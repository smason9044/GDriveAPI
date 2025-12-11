# ============================
# Export-QueryToDrive.ps1
# ============================

param (
    [string]$SQLServer,
    [string]$Database,
    [string]$Query,
    [string]$DriveFileName
)

# ============================
# ❌ DO NOT EDIT BELOW THIS LINE
# ============================

# Required Constants
$DriveFolderId           = "1iMG5R9Sq5cZk3i22rKjHOYsKauyTVHwJ"
$ServiceAccountKeyPath   = "C:\GDriveAPI\Token\driveapi-fbrdata.json"
$NugetBasePath           = "C:\Program Files\PackageManagement\NuGet\Packages"

# Execute SQL query
try {
    $results = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $Database -Query $Query -EncryptConnection -TrustServerCertificate
    if (-not $results -or $results.Count -eq 0) {
        Write-Warning "⚠️ SQL query returned no results. Skipping upload."
        return
    }
    Write-Host "✅ SQL query succeeded, preparing in-memory CSV..."
} catch {
    Write-Error "❌ SQL query failed: $_"
    return
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

# Query existing file in Drive
$existingFile = $service.Files.List()
$existingFile.Q = "'$DriveFolderId' in parents and name = '$DriveFileName' and trashed = false"
$existingFile.Fields = "files(id, name)"
$existingFiles = $existingFile.Execute().Files

# Build CSV in memory
$memStream = New-Object System.IO.MemoryStream
$writer = New-Object System.IO.StreamWriter($memStream, [System.Text.Encoding]::UTF8)
$results | Export-Csv -NoTypeInformation -Encoding UTF8 | ForEach-Object { $writer.WriteLine($_) }
$writer.Flush()
$memStream.Position = 0

# Upload to Drive
if ($existingFiles.Count -gt 0) {
    $fileId = $existingFiles[0].Id
    $updateRequest = $service.Files.Update($null, $fileId, $memStream, "text/csv")
    $updateRequest.Fields = "id"
    $updateRequest.Upload()
    Write-Host "♻️ File updated in Google Drive!"
} else {
    $fileMetadata = [Activator]::CreateInstance($DriveFileType)
    $fileMetadata.Name = $DriveFileName
    $fileMetadata.Parents = [System.Collections.Generic.List[string]]::new()
    $fileMetadata.Parents.Add($DriveFolderId)

    $createRequest = $service.Files.Create($fileMetadata, $memStream, "text/csv")
    $createRequest.Fields = "id"
    $createRequest.Upload()
    Write-Host "🚀 New file uploaded to Google Drive!"
}

$writer.Dispose()
$memStream.Dispose()