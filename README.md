Overview
This project automates exporting SQL query results to Google Drive using PowerShell and the Google Drive API.

Project Structure
/Configs – JSON config files specifying SQL Server, database name, query path, and destination Drive filename.
/Queries – Organized .sql query files.
/Templates – PowerShell automation scripts.
/Token – Google Service Account credentials.

Setup & Usage
  Share your Drive folder with the service account:
    driveuploadfbrdata@driveapi-fbrdata.iam.gserviceaccount.com

  Get the Folder ID from the Drive share URL.
    Example:
   https://drive.google.com/drive/u/0/folders/1iMG5R9Sq5cZk3i22rKjHOYsKauyTVHwJ
    Folder ID = 1iMG5R9Sq5cZk3i22rKjHOYsKauyTVHwJ

  Update your PowerShell script (e.g., Export-QueriesToDrive.ps1) with the Drive Folder ID by setting the $DriveFolderId variable.

  Multiple folders?
  Copy the PowerShell template, adjust the $DriveFolderId, and create a matching JSON config file for that folder.

Example: Run an Hourly Export - Command for Task Scheduler or SQL JOB.
  powershell.exe -File "C:\GDriveAPI\Templates\Export-QueriesToDrive.ps1" -ConfigPath "C:\GDriveAPI\Configs\HourlyExports.json"
Example: Alternate Folder Export
  powershell.exe -File "C:\GDriveAPI\Templates\Export-QueriesToDrivePY.ps1" -ConfigPath "C:\GDriveAPI\Configs\HourlyExportsPY.json"
