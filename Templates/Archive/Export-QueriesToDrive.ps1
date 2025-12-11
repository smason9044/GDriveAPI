# ============================
# Export-QueriesToDrive.ps1
# ============================

param (
    [string]$ConfigPath
)

# ============================
# ❌ DO NOT EDIT BELOW THIS LINE
# ============================

# Constants
$DriveFolderId           = "1iMG5R9Sq5cZk3i22rKjHOYsKauyTVHwJ"
$ServiceAccountKeyPath   = "C:\GDriveAPI\Token\driveapi-fbrdata.json"
$NugetBasePath           = "C:\Program Files\PackageManagement\NuGet\Packages"

# Load Config
try {
    $queries = Get-Content -Path $ConfigPath | ConvertFrom-Json
    if (-not $queries) { throw "❌ No queries loaded from $ConfigPath" }
} catch {
    Write-Error "❌ Failed to load or parse config JSON: $_"
    exit 1
}

# Load Google API DLLs
$dlls = @()
$dlls += Get-ChildItem "$NugetBasePath\Google.Apis.Drive.v3*\lib\netstandard2.0\*.dll" -Recurse
$dlls += Get-ChildItem "$NugetBasePath\Google.Apis.Auth*\lib\netstandard2.0\*.dll" -Recurse
$dlls += Get-ChildItem "$NugetBasePath\Google.Apis.Core*\lib\netstandard2.0\*.dll" -Recurse
$dlls += Get-ChildItem "$NugetBasePath\Google.Apis*\lib\netstandard2.0\*.dll" -Recurse

foreach ($dll in $dlls) {
    try { [Reflection.Assembly]::LoadFrom($dll.FullName) | Out-Null }
    catch { Write-Warning "⚠️ Failed to load $($dll.FullName): $_" }
}

# Resolve types
try {
    $GoogleCredentialType   = [Google.Apis.Auth.OAuth2.GoogleCredential]
    $DriveServiceType       = [Google.Apis.Drive.v3.DriveService]
    $BaseClientServiceType  = [Google.Apis.Services.BaseClientService]
    $DriveFileType          = [Google.Apis.Drive.v3.Data.File]
} catch {
    throw "❌ One or more required Google API types failed to resolve. Check DLL loading above."
}

# Authenticate
$scopes = @("https://www.googleapis.com/auth/drive")
$credential = $GoogleCredentialType::FromFile($ServiceAccountKeyPath).CreateScoped($scopes)

$initializer = New-Object ($BaseClientServiceType.FullName + '+Initializer') -Property @{
    HttpClientInitializer = $credential
    ApplicationName       = "Drive API PowerShell Upload"
}

$service = [Activator]::CreateInstance($DriveServiceType, $initializer)

# Process each query
foreach ($entry in $queries) {
    Write-Host "📄 Processing: $($entry.DriveFileName)"

    # Validate query file exists
    if (-not (Test-Path $entry.QueryPath)) {
        Write-Error "❌ SQL file missing: $($entry.QueryPath)"
        continue
    }

    $queryText = Get-Content -Path $entry.QueryPath -Raw

    try {
        $results = Invoke-Sqlcmd -ServerInstance $entry.SQLServer -Database $entry.Database -Query $queryText -EncryptConnection -TrustServerCertificate
        if (-not $results -or $results.Count -eq 0) {
            Write-Warning "⚠️ No results from query $($entry.DriveFileName). Skipping upload."
            continue
        }
        Write-Host "✅ SQL query succeeded, uploading to Drive..."
    } catch {
        Write-Error "❌ SQL execution failed for $($entry.DriveFileName): $_"
        continue
    }

    # Build memory stream
    $memStream = New-Object System.IO.MemoryStream
    $writer = New-Object System.IO.StreamWriter($memStream, [System.Text.Encoding]::UTF8)
    $results | Export-Csv -NoTypeInformation -Encoding UTF8 | ForEach-Object { $writer.WriteLine($_) }
    $writer.Flush()
    $memStream.Position = 0

    # Check if file exists
    $existingFile = $service.Files.List()
    $existingFile.Q = "'$DriveFolderId' in parents and name = '$($entry.DriveFileName)' and trashed = false"
    $existingFile.Fields = "files(id, name)"
    $existingFiles = $existingFile.Execute().Files

    if ($existingFiles.Count -gt 0) {
        $fileId = $existingFiles[0].Id
        $updateRequest = $service.Files.Update($null, $fileId, $memStream, "text/csv")
        $updateRequest.Fields = "id"
        $updateRequest.Upload()
        Write-Host "♻️ Updated $($entry.DriveFileName)"
    } else {
        $fileMetadata = [Activator]::CreateInstance($DriveFileType)
        $fileMetadata.Name = $entry.DriveFileName
        $fileMetadata.Parents = [System.Collections.Generic.List[string]]::new()
        $fileMetadata.Parents.Add($DriveFolderId)

        $createRequest = $service.Files.Create($fileMetadata, $memStream, "text/csv")
        $createRequest.Fields = "id"
        $createRequest.Upload()
        Write-Host "🚀 Uploaded new file: $($entry.DriveFileName)"
    }

    $writer.Dispose()
    $memStream.Dispose()
}

Write-Host "🏁 All queries processed."
