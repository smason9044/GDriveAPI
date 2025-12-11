# ============================
# Export-QueryToDrive.ps1
# ============================

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
    [string]$DriveFileName       = "AuditReport.csv"
    )

# ============================
# ❌ DO NOT EDIT BELOW THIS LINE
# ============================

#NuGet Packages
$NugetBasePath       = "C:\Program Files\PackageManagement\NuGet\Packages"

#Drive Token
$serviceAccountKeyFile = "C:\GDriveAPI\Token\driveapi-fbrdata.json"

# Create export folder if needed
if (-not (Test-Path (Split-Path $CSVExportPath))) {
    New-Item -ItemType Directory -Path (Split-Path $CSVExportPath) -Force | Out-Null
}

# SQL Export
try {
    $results = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $Database -Query $Query -EncryptConnection -TrustServerCertificate
    if ($results.Count -gt 0) {
        $results | Export-Csv -Path $CSVExportPath -NoTypeInformation -Encoding UTF8
        Write-Host "✅ SQL data exported to $CSVExportPath"
    } else {
        Write-Warning "⚠️ SQL query returned no results. Skipping upload."
        return
    }
} catch {
    Write-Error "❌ SQL query failed: $_"
    return
}

# Load Google API DLLs
$basePath = "C:\Program Files\PackageManagement\NuGet\Packages"
$packageDlls = @()
$packageDlls += Get-ChildItem "$basePath\Google.Apis.Drive.v3*\lib\netstandard2.0\*.dll" -Recurse
$packageDlls += Get-ChildItem "$basePath\Google.Apis.Auth*\lib\netstandard2.0\*.dll" -Recurse
$packageDlls += Get-ChildItem "$basePath\Google.Apis.Core*\lib\netstandard2.0\*.dll" -Recurse
$packageDlls += Get-ChildItem "$basePath\Google.Apis*\lib\netstandard2.0\*.dll" -Recurse

foreach ($dll in $packageDlls) {
    try {
        [Reflection.Assembly]::LoadFrom($dll.FullName) | Out-Null
    } catch {
        Write-Warning "⚠️ Failed to load $($dll.FullName): $_"
    }
}

# Resolve types using loaded assemblies
function Get-TypeFromAssembly {
    param ([string]$FullName)
    return [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.GetType($FullName, $false) } |
        ForEach-Object { $_.GetType($FullName) } |
        Select-Object -First 1
}

$GoogleCredentialType = Get-TypeFromAssembly -FullName "Google.Apis.Auth.OAuth2.GoogleCredential"
$DriveServiceType     = Get-TypeFromAssembly -FullName "Google.Apis.Drive.v3.DriveService"
$BaseClientServiceType = Get-TypeFromAssembly -FullName "Google.Apis.Services.BaseClientService"
$DriveFileType        = Get-TypeFromAssembly -FullName "Google.Apis.Drive.v3.Data.File"

if (-not $GoogleCredentialType) { throw "❌ GoogleCredential type not loaded!" }
if (-not $DriveServiceType) { throw "❌ DriveService type not loaded!" }
if (-not $BaseClientServiceType) { throw "❌ BaseClientService type not loaded!" }
if (-not $DriveFileType) { throw "❌ Drive File metadata type not loaded!" }

# Auth & Service Init
$scopes = @("https://www.googleapis.com/auth/drive")
$credential = $GoogleCredentialType::FromFile($ServiceAccountKeyPath).CreateScoped($scopes)

$initializer = New-Object ($BaseClientServiceType.FullName + '+Initializer') -Property @{
    HttpClientInitializer = $credential
    ApplicationName       = "Drive API PowerShell Upload"
}

$service = [Activator]::CreateInstance($DriveServiceType, $initializer)

# Upload logic
$existingFile = $service.Files.List()
$existingFile.Q = "'$DriveFolderId' in parents and name = '$DriveFileName' and trashed = false"
$existingFile.Fields = "files(id, name)"
$existingFiles = $existingFile.Execute().Files

if ($existingFiles.Count -gt 0) {
    $fileId = $existingFiles[0].Id
    $fileStream = [System.IO.File]::Open($CSVExportPath, 'Open')
    $updateRequest = $service.Files.Update($null, $fileId, $fileStream, "text/csv")
    $updateRequest.Fields = "id"
    $updateRequest.Upload()
    $fileStream.Close()
    Write-Host "♻️ Existing file overwritten in Google Drive."
} else {
    $fileMetadata = [Activator]::CreateInstance($DriveFileType)
    $fileMetadata.Name = $DriveFileName
    $fileMetadata.Parents = [System.Collections.Generic.List[string]]::new()
    $fileMetadata.Parents.Add($DriveFolderId)

    $fileStream = [System.IO.File]::Open($CSVExportPath, 'Open')
    $createRequest = $service.Files.Create($fileMetadata, $fileStream, "text/csv")
    $createRequest.Fields = "id"
    $createRequest.Upload()
    $fileStream.Close()
    Write-Host "🚀 New file uploaded successfully to Google Drive."
}
