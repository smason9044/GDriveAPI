# ============================
# Export-QueriesToDrive-Parallel.ps1 (Optimized)
# Controller + Worker in one file
# ============================

param (
    [string]$ConfigPath  = "C:\GDriveAPI\Configs\DailyExports1.json",
    [string]$WebhookURL  = "https://chat.googleapis.com/v1/spaces/AAQAJrNN0cc/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=CvjAf5Oupe-53IogtShKnJRcBjJI61JogiFphcntSYg",
    [string]$DriveFolderId         = "1-EWEHx_d2fd0I1D8zgzTNkg44bj5LE-U",
    [string]$ServiceAccountKeyPath = "C:\GDriveAPI\Token\driveapi-fbrdata.json",
    [string]$NugetBasePath         = "C:\GDriveAPI\lib",

    # Worker-only params
    [switch]$Worker,
    [string]$EntryConfigPath
)

# --------------
# Shared helpers
# --------------

$script:DllsLoaded = $false

function Install-SqlServerModule {
    if (-not (Get-Module -ListAvailable -Name SqlServer)) {
        try { Install-Module -Name SqlServer -Scope AllUsers -Force -ErrorAction Stop } catch {}
    }
    Import-Module SqlServer -ErrorAction SilentlyContinue
}

function Send-WebhookMessage {
    param([Parameter(Mandatory)][string]$Message)
    if ([string]::IsNullOrWhiteSpace($WebhookURL)) { return }
    try {
        $body = @{ text = $Message } | ConvertTo-Json -Depth 3
        Invoke-RestMethod -Uri $WebhookURL -Method Post -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
    } catch {
        Write-Warning ("Webhook post failed: {0}" -f $_.Exception.Message)
    }
}

function Import-DriveAssemblies {
    param([Parameter(Mandatory)][string]$Base)
    if ($script:DllsLoaded) { return }
    
    $dlls = @()
    if (Test-Path $Base) {
        # First try direct DLLs in base folder
        $direct = Get-ChildItem -Path $Base -Filter *.dll -File -ErrorAction SilentlyContinue
        if ($direct.Count -gt 0) { $dlls += $direct }
        # Then check netstandard2.0 subfolders
        if ($dlls.Count -eq 0) {
            $dlls += Get-ChildItem -Path $Base -Recurse -Filter *.dll -File -ErrorAction SilentlyContinue | 
                     Where-Object FullName -Match 'netstandard2.0'
        }
    }
    foreach ($dll in ($dlls | Select-Object -Unique)) {
        try { [Reflection.Assembly]::LoadFrom($dll.FullName) | Out-Null } catch {}
    }
    $script:DllsLoaded = $true
    Write-Host ("   Assemblies loaded from: {0}" -f $Base)
}

# ============================
# WORKER MODE
# ============================
if ($Worker) {

    if (-not (Test-Path -LiteralPath $EntryConfigPath)) {
        Write-Error "Worker: EntryConfigPath not found: $EntryConfigPath"
        exit 1
    }

    $Entry = Get-Content -Raw -Path $EntryConfigPath | ConvertFrom-Json

    # Ensure SqlServer module in worker process
    Install-SqlServerModule

    try {
        Write-Host "==> Processing: $($Entry.DriveFileName)"

        Import-DriveAssemblies -Base $NugetBasePath

        # Google API setup
        $GoogleCredentialType   = [Google.Apis.Auth.OAuth2.GoogleCredential]
        $DriveServiceType       = [Google.Apis.Drive.v3.DriveService]
        $BaseClientServiceType  = [Google.Apis.Services.BaseClientService]
        $DriveFileType          = [Google.Apis.Drive.v3.Data.File]

        $scopes = @("https://www.googleapis.com/auth/drive")
        $credential  = $GoogleCredentialType::FromFile($ServiceAccountKeyPath).CreateScoped($scopes)
        $initializer = New-Object ($BaseClientServiceType.FullName + '+Initializer') -Property @{
            HttpClientInitializer = $credential
            ApplicationName       = "Drive API PowerShell Upload"
        }
        $service = [Activator]::CreateInstance($DriveServiceType, $initializer)

        # SQL execution via InputFile
        $queryPath = [string]$Entry.QueryFilePath
        if (-not (Test-Path -LiteralPath $queryPath)) { throw "Query file not found: $queryPath" }

        Write-Host ("   Target: {0}\{1}" -f $Entry.SQLServer, $Entry.Database)
        Write-Host ("   Running SQL file: {0}" -f $queryPath)

        $ErrorActionPreference = 'Stop'

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $results = Invoke-Sqlcmd `
            -ServerInstance $Entry.SQLServer `
            -Database       $Entry.Database `
            -InputFile      $queryPath `
            -Encrypt        Optional `
            -TrustServerCertificate `
            -ConnectionTimeout 10
        $sw.Stop()
        Write-Host ("   Invoke-Sqlcmd duration: {0:n1}s" -f $sw.Elapsed.TotalSeconds)

        # CSV build
        $memStream = New-Object System.IO.MemoryStream
        $writer    = New-Object System.IO.StreamWriter($memStream, [System.Text.Encoding]::UTF8)

        $exclude = 'RowError','RowState','Table','ItemArray','HasErrors'
        $rows = @()
        $colNames = @()

        if ($results -is [System.Data.DataTable]) {
            $rows     = $results.Rows
            $colNames = @($results.Columns | ForEach-Object ColumnName)
        }
        elseif ($results -is [System.Data.DataRow]) {
            $rows     = ,$results
            $colNames = @($results.Table.Columns | ForEach-Object ColumnName)
        }
        elseif ($results -is [System.Data.DataRowView]) {
            $rows     = ,$results
            $colNames = @($results.Row.Table.Columns | ForEach-Object ColumnName)
        }
        else {
            if ($results -isnot [System.Collections.IEnumerable] -or $results -is [string]) { $rows = ,$results } else { $rows = $results }
            if ($rows.Count -gt 0) {
                $first    = $rows | Select-Object -First 1
                $colNames = @($first.PSObject.Properties.Name | Where-Object { $_ -notin $exclude -and $_ -notmatch '^PS' })
            }
        }

        $rowCount = ($rows | Measure-Object).Count
        $colCount = $colNames.Count
        Write-Host ("   SQL ok. Rows: {0}, Cols: {1}" -f $rowCount, $colCount)

        if ($rowCount -gt 0 -and $colCount -gt 0) {
            # Write header row (unquoted)
            $headerLine = ($colNames -join ',')
            $writer.WriteLine($headerLine)
            
            # Write data rows efficiently
            foreach ($r in $rows) {
                $values = @()
                foreach ($name in $colNames) {
                    $val = if ($r -is [System.Data.DataRow])        { $r[$name] }
                           elseif ($r -is [System.Data.DataRowView]) { $r.Row[$name] }
                           else                                      { $r.$name }
                    if ($val -is [datetime]) { $val = $val.ToString('yyyy-MM-dd HH:mm:ss') }
                    elseif ($null -eq $val) { $val = '' }
                    $values += '"' + ($val -replace '"','""') + '"'
                }
                $writer.WriteLine(($values -join ','))
            }
        }
        else {
            $writer.WriteLine("")
        }

        $writer.Flush(); $memStream.Position = 0
        Write-Host ("   CSV bytes (pre-upload): {0}" -f $memStream.Length)

        # Upsert to Drive
        $listReq = $service.Files.List()
        $listReq.Q      = "'$DriveFolderId' in parents and name = '$($Entry.DriveFileName)' and trashed = false"
        $listReq.Fields = "files(id,name)"
        $existing       = $listReq.Execute().Files

        $swUpload = [System.Diagnostics.Stopwatch]::StartNew()

        if ($existing.Count -gt 0) {
            $fileId = $existing[0].Id
            $update = $service.Files.Update($null, $fileId, $memStream, "text/csv")
            $update.Fields = "id"
            $null = $update.Upload()
            Write-Host ("   Drive updated: {0}" -f $Entry.DriveFileName)
        } else {
            $meta = [Activator]::CreateInstance($DriveFileType)
            $meta.Name    = $Entry.DriveFileName
            $meta.Parents = [System.Collections.Generic.List[string]]::new()
            $meta.Parents.Add($DriveFolderId)
            $create = $service.Files.Create($meta, $memStream, "text/csv")
            $create.Fields = "id"
            $null = $create.Upload()
            Write-Host ("   Drive created: {0}" -f $Entry.DriveFileName)
        }

        $swUpload.Stop()
        Write-Host ("   Upload duration: {0:n1}s" -f $swUpload.Elapsed.TotalSeconds)

        $exported = 0
        if ($results) {
            if ($results -is [System.Data.DataTable]) {
                $exported = $results.Rows.Count
            }
            else {
                if ($results -isnot [System.Collections.IEnumerable] -or $results -is [string]) { $results = ,$results }
                $exported = ($results | Measure-Object).Count
            }
        }
        Write-Output ("Exported {0} rows to {1}" -f $exported, $Entry.DriveFileName)

        $writer.Dispose(); $memStream.Dispose()

        exit 0
    }
    catch {
        $fn = '<unknown>'
        if ($Entry -and ($Entry.PSObject.Properties.Name -contains 'DriveFileName') -and $Entry.DriveFileName) {
            $fn = $Entry.DriveFileName
        }
        $msg = ("FAILED {0} | Server={1}\{2} | Query={3} | Error={4}" -f $fn, $Entry.SQLServer, $Entry.Database, $Entry.QueryFilePath, $_.Exception.Message)
        Send-WebhookMessage $msg
        Write-Error ("Error processing {0}: {1}" -f $fn, $_)

        exit 1
    }
}

# ============================
# CONTROLLER MODE
# ============================

# Ensure SqlServer module in controller (not strictly required, but harmless)
Install-SqlServerModule

if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "Config file not found: $ConfigPath" }
$config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json

$JobTimeoutSec    = 660
$OverallBudgetSec = 700
$overallStart     = Get-Date

$logRoot = "C:\GDriveAPI\Logs"
if (-not (Test-Path $logRoot)) { New-Item -ItemType Directory -Path $logRoot | Out-Null }

$workers = @()

foreach ($entry in $config) {
    # Write per-entry config to temp file
    $baseName = [IO.Path]::GetFileNameWithoutExtension($entry.DriveFileName)
    $tempCfg  = Join-Path $env:TEMP ("GDriveEntry_{0}_{1}.json" -f $baseName, [System.Guid]::NewGuid().ToString("N"))

    $entry | ConvertTo-Json -Depth 6 | Set-Content -Path $tempCfg -Encoding UTF8

    $outLog = Join-Path $logRoot ("{0}.out.log" -f $baseName)
    $errLog = Join-Path $logRoot ("{0}.err.log" -f $baseName)

    $procArgs = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$PSCommandPath`"",
        "-Worker",
        "-EntryConfigPath", "`"$tempCfg`"",
        "-ConfigPath", "`"$ConfigPath`"",
        "-WebhookURL", "`"$WebhookURL`"",
        "-DriveFolderId", "`"$DriveFolderId`"",
        "-ServiceAccountKeyPath", "`"$ServiceAccountKeyPath`"",
        "-NugetBasePath", "`"$NugetBasePath`""
    )

    $proc = Start-Process powershell.exe `
        -ArgumentList $procArgs `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $outLog `
        -RedirectStandardError  $errLog

    $workers += [PSCustomObject]@{
        Name        = $entry.DriveFileName
        BaseName    = $baseName
        PID         = $proc.Id
        Process     = $proc
        Start       = Get-Date
        TimeoutSec  = $JobTimeoutSec
        TempConfig  = $tempCfg
        StdOutPath  = $outLog
        StdErrPath  = $errLog
        Done        = $false
        TimedOut    = $false
    }

    Write-Host ("Launched worker {0} (PID={1}) for {2}" -f $baseName, $proc.Id, $entry.DriveFileName)
}

# Watchdog loop
while ($true) {

    $unfinished = $workers | Where-Object { -not $_.Done }
    if ($unfinished.Count -eq 0) { break }

    # Overall budget
    $elapsedOverall = (New-TimeSpan -Start $overallStart -End (Get-Date)).TotalSeconds
    if ($elapsedOverall -ge $OverallBudgetSec) {
        $msg = ("ABORT: overall budget exceeded ({0}s). Killing {1} remaining job(s)." -f $OverallBudgetSec, $unfinished.Count)
        Write-Warning $msg
        Send-WebhookMessage $msg

        foreach ($w in $unfinished) {
            if (-not $w.Process.HasExited) {
                try { Stop-Process -Id $w.PID -Force -ErrorAction SilentlyContinue } catch {}
            }
            $w.TimedOut = $true
            $w.Done     = $true
        }
        break
    }

    foreach ($w in $unfinished) {
        $p = $w.Process
        $elapsed = (New-TimeSpan -Start $w.Start -End (Get-Date)).TotalSeconds

        if (-not $p.HasExited) {
            if ($elapsed -ge $w.TimeoutSec -and -not $w.TimedOut) {
                $w.TimedOut = $true
                try { Stop-Process -Id $w.PID -Force -ErrorAction SilentlyContinue } catch {}

                $note = ("TIMED OUT after {0}s -> {1} (PID={2})" -f [int]$elapsed, $w.Name, $w.PID)
                Write-Warning $note
                Send-WebhookMessage ("TIMED OUT {0} | Elapsed={1}s | PID={2}" -f $w.Name, [int]$elapsed, $w.PID)
            }
        }
        else {
            # Process finished naturally
            $w.Done = $true

            # Safely read exit code (null defaults to 0)
            $exitCode = if ($null -eq $p.ExitCode) { 0 } else { $p.ExitCode }

            Write-Host ("Completed worker {0} (PID={1}) ExitCode={2}" -f $w.BaseName, $w.PID, $exitCode)

            # Read and display output efficiently
            if (Test-Path $w.StdOutPath) {
                Get-Content -Path $w.StdOutPath -ErrorAction SilentlyContinue | Write-Host
                Remove-Item $w.StdOutPath -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path $w.StdErrPath) {
                Get-Content -Path $w.StdErrPath -ErrorAction SilentlyContinue | Write-Host
                Remove-Item $w.StdErrPath -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path $w.TempConfig) {
                Remove-Item $w.TempConfig -Force -ErrorAction SilentlyContinue
            }

            # Only alert on real failures
            if ($exitCode -ne 0) {
                $msg = ("Worker failed for {0} (PID={1}) ExitCode={2}" -f $w.Name, $w.PID, $exitCode)
                Write-Warning $msg
                Send-WebhookMessage $msg
            }
        }
    }

    # Check every half-second instead of 3 seconds to be more responsive
    Start-Sleep -Milliseconds 500
}

Write-Host "All worker processes finished (with watchdog)."
