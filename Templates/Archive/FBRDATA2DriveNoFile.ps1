# =========================
# USER-CONFIGURABLE SETTINGS
# =========================

param (
    [string]$SQLServer           = "FBRDATA",
    [string]$Database            = "MIMDISTN",
    [string]$Query               = @"
SELECT 
    RPT_RTPSequence_AuditReport.Plant, 
    RPT_RTPSequence_AuditReport.SeqNum, 
    RPT_RTPSequence_AuditReport.ProdNo, 
    RPT_RTPSequence_AuditReport.RTx, 
    RPT_RTPSequence_AuditReport.WIPBin, 
    RPT_RTPSequence_AuditReport.LineAsn AS LineAsn_Audit, 
    RPT_RTPSequence_AuditReport.SkuCude, 
    RPT_RTPSequence_AuditReport.AdjPlanQty, 
    RPT_RTPSequence_AuditReport.PlanQtyRT, 
    RPT_RTPSequence_AuditReport.SFC, 
    RPT_RTP_U_OpenMORQty.OrdQty, 
    RPT_RTP_U_OpenMORQty.ShipQty, 
    NLK_ProduceHeaderShort.PartNum, 
    NLK_ProduceHeaderShort.LineAsn AS LineAsn_Header, 
    RPT_RTP_U_MIMStk.QtyOnHand
FROM MIMDISTN.dbo.RPT_RTPSequence_AuditReport
INNER JOIN MIMDISTN.dbo.NLK_ProduceHeaderShort 
    ON RPT_RTPSequence_AuditReport.ProdNo = NLK_ProduceHeaderShort.ProdNo
LEFT OUTER JOIN MIMDISTN.dbo.RPT_RTP_U_OpenMORQty 
    ON RPT_RTPSequence_AuditReport.Plant = RPT_RTP_U_OpenMORQty.PO_Plant
    AND RPT_RTPSequence_AuditReport.SkuCude = RPT_RTP_U_OpenMORQty.PO_BasePartNum
LEFT OUTER JOIN MIMDISTN.dbo.RPT_RTP_U_MIMStk 
    ON RPT_RTPSequence_AuditReport.Plant = RPT_RTP_U_MIMStk.Plant
    AND RPT_RTPSequence_AuditReport.SkuCude = RPT_RTP_U_MIMStk.BasePartNum
WHERE RPT_RTPSequence_AuditReport.Plant = 'FB'
"@,
    [string]$DriveFolderId       = "1iMG5R9Sq5cZk3i22rKjHOYsKauyTVHwJ",
    [string]$DriveFileName       = "AuditReport.csv",
    [string]$ServiceAccountPath  = "C:\GDriveAPI\Token\driveapi-fbrdata.json",
    [string]$NugetBasePath       = "C:\Program Files\PackageManagement\NuGet\Packages"
)

# =========================
# DO NOT EDIT BELOW THIS LINE
# =========================

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
dlls += Get-ChildItem "$NugetBasePath\Google.Apis.Drive.v3*\lib\netstandard2.0\*.dll" -Recurse
Dlls += Get-ChildItem "$NugetBasePath\Google.Apis.Auth*\lib\netstandard2.0\*.dll" -Recurse
Dlls += Get-ChildItem "$NugetBasePath\Google.Apis.Core*\lib\netstandard2.0\*.dll" -Recurse
Dlls += Get-ChildItem "$NugetBasePath\Google.Apis*\lib\netstandard2.0\*.dll" -Recurse

foreach ($dll in $dlls) {
    try { [Reflection.Assembly]::LoadFrom($dll.FullName) | Out-Null }
    catch { Write-Warning "⚠️ Failed to load $($dll.FullName): $_" }
}

# Use direct types
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
$credential = $GoogleCredentialType::FromFile($ServiceAccountPath).CreateScoped($scopes)

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
