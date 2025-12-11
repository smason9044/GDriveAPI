# ============================
# Export-QueriesToDrive-Parallel.ps1
# Run multiple SQL queries and upload CSVs to Google Drive (in parallel)
# ============================

param (
    [string]$ConfigPath = "C:\GDriveAPI\Configs\HourlyExports.json"
)

# ============================
# ❌ DO NOT EDIT BELOW THIS LINE
# ============================

$DriveFolderId         = "1iMG5R9Sq5cZk3i22rKjHOYsKauyTVHwJ"
$ServiceAccountKeyPath = "C:\GDriveAPI\Token\driveapi-fbrdata.json"
$NugetBasePath         = "C:\Program Files\PackageManagement\NuGet\Packages"

# Load Google API DLLs and Newtonsoft.Json
$dlls = @()
$dlls += Get-ChildItem "$NugetBasePath\Google.Apis.Drive.v3*\lib\netstandard2.0\*.dll" -Recurse
$dlls += Get-ChildItem "$NugetBasePath\Google.Apis.Auth*\lib\netstandard2.0\*.dll" -Recurse
$dlls += Get-ChildItem "$NugetBasePath\Google.Apis.Core*\lib\netstandard2.0\*.dll" -Recurse
$dlls += Get-ChildItem "$NugetBasePath\Google.Apis*\lib\netstandard2.0\*.dll" -Recurse
$dlls += Get-ChildItem "$NugetBasePath\Newtonsoft.Json*\lib\netstandard2.0\*.dll" -Recurse

foreach ($dll in $dlls) {
    try { [Reflection.Assembly]::LoadFrom($dll.FullName) | Out-Null }
    catch { Write-Warning "⚠️ Failed to load $($dll.FullName): $_" }
}

# Load JSON config
$config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json

# Declare the job scriptblock
$scriptBlock = {
    param ($Entry, $DriveFolderId, $ServiceAccountKeyPath, $NugetBasePath)

    # Reload necessary assemblies in each job
    $dlls = @()
    $dlls += Get-ChildItem "$NugetBasePath\Google.Apis.Drive.v3*\lib\netstandard2.0\*.dll" -Recurse
    $dlls += Get-ChildItem "$NugetBasePath\Google.Apis.Auth*\lib\netstandard2.0\*.dll" -Recurse
    $dlls += Get-ChildItem "$NugetBasePath\Google.Apis.Core*\lib\netstandard2.0\*.dll" -Recurse
    $dlls += Get-ChildItem "$NugetBasePath\Google.Apis*\lib\netstandard2.0\*.dll" -Recurse
    $dlls += Get-ChildItem "$NugetBasePath\Newtonsoft.Json*\lib\netstandard2.0\*.dll" -Recurse

    foreach ($dll in $dlls) {
        try { [Reflection.Assembly]::LoadFrom($dll.FullName) | Out-Null }
        catch { Write-Warning "⚠️ Failed to load $($dll.FullName): $_" }
    }

    try {
        # Load types
        $GoogleCredentialType   = [Google.Apis.Auth.OAuth2.GoogleCredential]
        $DriveServiceType       = [Google.Apis.Drive.v3.DriveService]
        $BaseClientServiceType  = [Google.Apis.Services.BaseClientService]
        $DriveFileType          = [Google.Apis.Drive.v3.Data.File]

        Write-Host "📃 Processing: $($Entry.DriveFileName)"

        # Authenticate
        $scopes = @("https://www.googleapis.com/auth/drive")
        $credential = $GoogleCredentialType::FromFile($ServiceAccountKeyPath).CreateScoped($scopes)
        $initializer = New-Object ($BaseClientServiceType.FullName + '+Initializer') -Property @{
            HttpClientInitializer = $credential
            ApplicationName       = "Drive API PowerShell Upload"
        }
        $service = [Activator]::CreateInstance($DriveServiceType, $initializer)

        # Load query
        $queryPath = $Entry.QueryFilePath
        if (-not (Test-Path $queryPath)) {
            Write-Warning "⚠️ Query file not found: $queryPath"
            return
        }
        $queryText = Get-Content -Raw -Path $queryPath

        # Execute query
        $results = Invoke-Sqlcmd -ServerInstance $Entry.SQLServer -Database $Entry.Database -Query $queryText -EncryptConnection -TrustServerCertificate

        if (-not $results -or $results.Count -eq 0) {
            Write-Warning "⚠️ Query returned no rows. Skipping $($Entry.DriveFileName)."
            return
        }

        Write-Host "✅ SQL query succeeded, uploading to Drive..."

        # Check if the file already exists
        $existingFile = $service.Files.List()
        $existingFile.Q = "'$DriveFolderId' in parents and name = '$($Entry.DriveFileName)' and trashed = false"
        $existingFile.Fields = "files(id, name)"
        $existingFiles = $existingFile.Execute().Files

        # Build memory stream
        $memStream = New-Object System.IO.MemoryStream
        $writer = New-Object System.IO.StreamWriter($memStream, [System.Text.Encoding]::UTF8)
        $csvContent = $results | ConvertTo-Csv -NoTypeInformation
        foreach ($line in $csvContent) {
            $writer.WriteLine($line)
        }
        $writer.Flush()
        $memStream.Position = 0

        # Upload or update
        if ($existingFiles.Count -gt 0) {
            $fileId = $existingFiles[0].Id
            $updateRequest = $service.Files.Update($null, $fileId, $memStream, "text/csv")
            $updateRequest.Fields = "id"
            $updateRequest.Upload()
            Write-Host "♻️ File updated: $($Entry.DriveFileName)"
        } else {
            $fileMetadata = [Activator]::CreateInstance($DriveFileType)
            $fileMetadata.Name = $Entry.DriveFileName
            $fileMetadata.Parents = [System.Collections.Generic.List[string]]::new()
            $fileMetadata.Parents.Add($DriveFolderId)

            $createRequest = $service.Files.Create($fileMetadata, $memStream, "text/csv")
            $createRequest.Fields = "id"
            $createRequest.Upload()
            Write-Host "🚀 Uploaded new file: $($Entry.DriveFileName)"
        }

        Write-Output "✅ Exported $($results.Count) rows to $($Entry.DriveFileName)"
        $writer.Dispose()
        $memStream.Dispose()

    } catch {
        Write-Error "❌ Error processing $($Entry.DriveFileName): $_"
    }
}

# Launch all jobs in parallel
$jobs = foreach ($entry in $config) {
    Start-Job -ScriptBlock $scriptBlock -ArgumentList $entry, $DriveFolderId, $ServiceAccountKeyPath, $NugetBasePath
}

# Wait for jobs to finish
$jobs | Wait-Job | Receive-Job | ForEach-Object { Write-Host $_ }

Write-Host "💡 All parallel queries processed."
