# ============================
# Export-QueriesToDrive-Parallel-v2.ps1
# IMPROVEMENTS: Native .NET SQL, Throttling, Retries, TLS 1.2, Auto-Cleanup
# ============================

param (
    [string]$ConfigPath  = "C:\GDriveAPI\Configs\DailyExports1.json",
    [string]$WebhookURL  = "https://chat.googleapis.com/v1/spaces/AAQAJrNN0cc/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=CvjAf5Oupe-53IogtShKnJRcBjJI61JogiFphcntSYg",
    [string]$DriveFolderId         = "1-EWEHx_d2fd0I1D8zgzTNkg44bj5LE-U",
    [string]$ServiceAccountKeyPath = "C:\GDriveAPI\Token\driveapi-fbrdata.json",
    [string]$NugetBasePath         = "C:\GDriveAPI\lib",
    [int]$ThrottleLimit            = 5,  # Max concurrent workers

    # Worker-only params (Do not set these manually)
    [switch]$Worker,
    [string]$EntryConfigPath
)

# Force TLS 1.2 for Google API compatibility
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# --------------
# Shared helpers
# --------------

$script:DllsLoaded = $false

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
        $direct = Get-ChildItem -Path $Base -Filter *.dll -File -ErrorAction SilentlyContinue
        if ($direct.Count -gt 0) { $dlls += $direct }
        if ($dlls.Count -eq 0) {
            $dlls += Get-ChildItem -Path $Base -Recurse -Filter *.dll -File -ErrorAction SilentlyContinue | 
                     Where-Object FullName -Match 'netstandard2.0'
        }
    }
    foreach ($dll in ($dlls | Select-Object -Unique)) {
        try { [Reflection.Assembly]::LoadFrom($dll.FullName) | Out-Null } catch {}
    }
    $script:DllsLoaded = $true
}

# ============================
# WORKER MODE
# ============================
if ($Worker) {
    try {
        if (-not (Test-Path -LiteralPath $EntryConfigPath)) { throw "Config not found" }
        $Entry = Get-Content -Raw -Path $EntryConfigPath | ConvertFrom-Json
        $FileName = $Entry.DriveFileName

        Write-Host "==> Processing: $FileName"

        # ----------------------
        # STEP 1: Execute SQL (Native .NET - No Module)
        # ----------------------
        $queryPath = [string]$Entry.QueryFilePath
        if (-not (Test-Path -LiteralPath $queryPath)) { throw "Query file not found: $queryPath" }
        
        $sqlQuery = Get-Content -Raw -Path $queryPath
        $connStr  = "Server=$($Entry.SQLServer);Database=$($Entry.Database);Integrated Security=True;Encrypt=True;TrustServerCertificate=True;Connection Timeout=60"
        
        $dt = New-Object System.Data.DataTable
        $swSql = [System.Diagnostics.Stopwatch]::StartNew()

        # Retry Logic for SQL
        $maxRetries = 3
        $retryCount = 0
        $sqlSuccess = $false
        
        while (-not $sqlSuccess -and $retryCount -lt $maxRetries) {
            try {
                $conn = New-Object System.Data.SqlClient.SqlConnection $connStr
                $conn.Open()
                $cmd = $conn.CreateCommand()
                $cmd.CommandText = $sqlQuery
                $cmd.CommandTimeout = 600 # 10 minutes
                
                $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
                $null = $adapter.Fill($dt)
                $conn.Close()
                $sqlSuccess = $true
            }
            catch {
                $retryCount++
                Write-Warning "SQL Error ($retryCount/$maxRetries): $_"
                if ($conn) { $conn.Close() }
                if ($retryCount -lt $maxRetries) { Start-Sleep -Seconds 5 }
                else { throw "SQL failed after $maxRetries attempts: $_" }
            }
        }
        $swSql.Stop()
        Write-Host ("   SQL Fetched {0} rows in {1:n1}s" -f $dt.Rows.Count, $swSql.Elapsed.TotalSeconds)

        # ----------------------
        # STEP 2: Build CSV Stream
        # ----------------------
        $memStream = New-Object System.IO.MemoryStream
        $writer    = New-Object System.IO.StreamWriter($memStream, [System.Text.Encoding]::UTF8)

        if ($dt.Rows.Count -gt 0) {
            $colNames = @($dt.Columns | ForEach-Object ColumnName)
            $writer.WriteLine(($colNames -join ',')) # Header

            foreach ($row in $dt.Rows) {
                $values = @()
                foreach ($col in $colNames) {
                    $val = $row[$col]
                    if ($val -is [DBNull]) { $val = '' }
                    elseif ($val -is [datetime]) { $val = $val.ToString('yyyy-MM-dd HH:mm:ss') }
                    $values += '"' + ([string]$val -replace '"','""') + '"'
                }
                $writer.WriteLine(($values -join ','))
            }
        } else {
            $writer.WriteLine("") # Empty file for no results
        }
        $writer.Flush()
        $memStream.Position = 0

        # ----------------------
        # STEP 3: Upload to Drive (With Retry)
        # ----------------------
        Import-DriveAssemblies -Base $NugetBasePath

        # Auth
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

        $retryCount = 0
        $uploadSuccess = $false

        while (-not $uploadSuccess -and $retryCount -lt $maxRetries) {
            try {
                # Check exist
                $listReq = $service.Files.List()
                $listReq.Q = "'$DriveFolderId' in parents and name = '$FileName' and trashed = false"
                $listReq.Fields = "files(id,name)"
                $existing = $listReq.Execute().Files

                if ($existing.Count -gt 0) {
                    $fileId = $existing[0].Id
                    $update = $service.Files.Update($null, $fileId, $memStream, "text/csv")
                    $update.Fields = "id"
                    $null = $update.Upload()
                    Write-Host "   Drive: Updated existing file."
                } else {
                    $meta = [Activator]::CreateInstance($DriveFileType)
                    $meta.Name = $FileName
                    $meta.Parents = [System.Collections.Generic.List[string]]::new()
                    $meta.Parents.Add($DriveFolderId)
                    $create = $service.Files.Create($meta, $memStream, "text/csv")
                    $create.Fields = "id"
                    $null = $create.Upload()
                    Write-Host "   Drive: Created new file."
                }
                $uploadSuccess = $true
            }
            catch {
                $retryCount++
                Write-Warning "Upload Error ($retryCount/$maxRetries): $_"
                if ($retryCount -lt $maxRetries) { 
                    $memStream.Position = 0 # Reset stream for retry
                    Start-Sleep -Seconds 2 
                }
                else { throw "Upload failed after $maxRetries attempts: $_" }
            }
        }

        Write-Output ("Exported {0} rows to {1}" -f $dt.Rows.Count, $FileName)
        $writer.Dispose(); $memStream.Dispose()
        exit 0

    } catch {
        $err = $_.Exception.Message
        Write-Error "CRITICAL WORKER FAIL: $err"
        $msg = "FAILED {0} | Server={1}\{2} | Error={3}" -f $Entry.DriveFileName, $Entry.SQLServer, $Entry.Database, $err
        Send-WebhookMessage $msg
        exit 1
    }
}

# ============================
# CONTROLLER MODE
# ============================

if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "Config file not found: $ConfigPath" }
$config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json

$JobTimeoutSec    = 660
$OverallBudgetSec = 900
$overallStart     = Get-Date

$logRoot = "C:\GDriveAPI\Logs"
if (-not (Test-Path $logRoot)) { New-Item -ItemType Directory -Path $logRoot | Out-Null }

$workers = @()
$queue   = [System.Collections.Generic.Queue[Object]]::new()

# Load Queue
foreach ($c in $config) { $queue.Enqueue($c) }

Write-Host "Starting Controller. Queue: $($queue.Count) items. Throttle: $ThrottleLimit"

while ($true) {
    # 1. CLEANUP: Check running workers
    $finished = $workers | Where-Object { $_.Done -eq $false -and ($_.Process.HasExited -or (New-TimeSpan -Start $_.Start).TotalSeconds -gt $JobTimeoutSec) }
    
    foreach ($w in $finished) {
        $p = $w.Process
        $w.Done = $true
        
        # Handle Timeout vs Exit
        if (-not $p.HasExited) {
            $w.TimedOut = $true
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
            Write-Warning "TIMEOUT: $($w.Name) (PID $($p.Id))"
            Send-WebhookMessage "TIMED OUT $($w.Name)"
        } else {
            # Standard Exit
            $p.Refresh()
            $code = $p.ExitCode
            
            # Treat null exit code as success (0) to prevent false positives
            if ($null -eq $code) { $code = 0 }

            Write-Host "Finished: $($w.Name) (Exit $code)"
            
            if ($code -ne 0) {
                Write-Warning "FAILED: $($w.Name) (Check Logs)"
                # Keep logs for debugging if it failed
            } else {
                # SUCCESS: Clean up logs and temp config
                Remove-Item $w.StdOutPath -ErrorAction SilentlyContinue
                Remove-Item $w.StdErrPath -ErrorAction SilentlyContinue
                Remove-Item $w.TempConfig -ErrorAction SilentlyContinue
            }
            
            # Read Output for console feedback
            if (Test-Path $w.StdOutPath) { Get-Content $w.StdOutPath | Write-Host }
        }
    }

    # 2. OVERALL TIMEOUT CHECK
    if ((New-TimeSpan -Start $overallStart).TotalSeconds -gt $OverallBudgetSec) {
        Write-Warning "ABORT: Overall budget exceeded."
        break
    }

    # 3. LAUNCH: Start new workers if slots available
    $runningCount = ($workers | Where-Object { -not $_.Done }).Count
    
    while ($runningCount -lt $ThrottleLimit -and $queue.Count -gt 0) {
        $entry = $queue.Dequeue()
        $baseName = [IO.Path]::GetFileNameWithoutExtension($entry.DriveFileName)
        
        # Temp Config
        $tempCfg = Join-Path $env:TEMP ("GDriveEntry_{0}_{1}.json" -f $baseName, [Guid]::NewGuid().ToString("N"))
        $entry | ConvertTo-Json -Depth 6 | Set-Content -Path $tempCfg -Encoding UTF8

        # Log Paths
        $outLog = Join-Path $logRoot ("{0}.out.log" -f $baseName)
        $errLog = Join-Path $logRoot ("{0}.err.log" -f $baseName)

        $procArgs = @(
            "-NoProfile", "-ExecutionPolicy", "Bypass",
            "-File", "`"$PSCommandPath`"",
            "-Worker",
            "-EntryConfigPath", "`"$tempCfg`"",
            "-ConfigPath", "`"$ConfigPath`"", 
            "-WebhookURL", "`"$WebhookURL`"",
            "-DriveFolderId", "`"$DriveFolderId`"",
            "-ServiceAccountKeyPath", "`"$ServiceAccountKeyPath`"",
            "-NugetBasePath", "`"$NugetBasePath`""
        )

        $p = Start-Process powershell.exe -ArgumentList $procArgs -PassThru -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog
        
        $workers += [PSCustomObject]@{
            Name = $entry.DriveFileName
            Process = $p
            Start = Get-Date
            Done = $false
            TimedOut = $false
            StdOutPath = $outLog
            StdErrPath = $errLog
            TempConfig = $tempCfg
        }
        $runningCount++
        Write-Host "Launched: $baseName (PID $($p.Id))"
    }

    # 4. EXIT CONDITION
    if ($queue.Count -eq 0 -and $runningCount -eq 0) {
        break
    }

    Start-Sleep -Milliseconds 500
}

Write-Host "All jobs completed."