# GDriveAPI Copilot Instructions

**Audience**: For IT and database administrators maintaining SQL export automation on FBRDATA.

This is a **SQL-to-Google Drive export automation system** for factory operations reporting.

## Architecture Overview

**Data Flow**: SQL Server → PowerShell → Google Drive

- **Config-driven**: Each export frequency (Hourly, Daily, Weekly, etc.) has a JSON config in `Configs/`
- **Parallel execution**: `Templates/Export-QueriesToDrive-Parallel.ps1` runs multiple SQL queries concurrently with timeouts
- **CSV output**: Results from SQL Server queries are streamed to Google Drive as CSV files
- **Webhook notifications**: Google Chat integration for success/failure/timeout alerts

## Recent Changes (2025-12-08)

- Renamed internal helper functions to improve analyzer compatibility:
  - `Ensure-SqlServerModule` -> `Install-SqlServerModule`
  - `Load-DriveDlls` -> `Import-DriveAssemblies`
- Replaced PowerShell 7-only usage (`Join-String`) with PowerShell 5-compatible `-join` for header construction.
- Replaced use of the automatic `$args` variable with an explicit `$procArgs` array when launching worker processes to avoid unintended side-effects.
- Improved DLL loading with a cache flag to avoid repeated assembly loads across workers, and simplified DLL discovery to scan `netstandard2.0` locations.
- Replaced PS7 null-coalescing usage with a PowerShell 5-compatible conditional to maintain compatibility with Windows PowerShell 5.1.
- Streamlined CSV generation to write header and rows directly (avoids `ConvertTo-Csv` intermediate), and reduced watchdog sleep interval for more responsive job monitoring.

These changes were implemented in the `Templates/Export-QueriesToDrive-Parallel.ps1` family of scripts (including `-Test` and `-Optimized` variants) to improve compatibility and performance while running under Windows PowerShell 5.1.

### Execution Model Change

- The parallel execution model was changed from in-process PowerShell jobs to a controller/worker pattern: the controller launches isolated worker processes (via `Start-Process`) for each export entry and monitors them with a watchdog. This improves process isolation, per-worker logging, reliable PID-based timeouts, and avoids job-state quirks when running under SQL Agent.

## Project Structure

- `Configs/` – JSON export manifests (5min, 10min, Hourly, Daily, Weekly, etc.)
- `Queries/` – Organized SQL files by frequency (Hourly/, Daily-4am/, Weekly/, etc.)
- `Templates/` – PowerShell automation scripts (main: `Export-QueriesToDrive-Parallel.ps1`)
- `Token/` – Google Service Account credentials (`driveapi-fbrdata.json`)
- `Logs/` – Timestamped logs from `RunExports.bat` (batch launcher only; SQL Agent Jobs log to SSMS)
- `CSVExports/` – Optional local CSV staging (not typically used in production)

## Critical Workflows

### Running an Export Locally
```bash
powershell -ExecutionPolicy Bypass -File "C:\GDriveAPI\Templates\Export-QueriesToDrive-Parallel.ps1" `
  -ConfigPath "C:\GDriveAPI\Configs\HourlyExports.json"
```

### Using the Batch Launcher
Double-click `RunExports.bat` for an interactive menu to choose export frequency.

## Logging

### Batch Launcher Logs (RunExports.bat)
When exports are run via the batch launcher, detailed logs are written to the `Logs/` directory under the project root (e.g., `C:\GDriveAPI\Logs`).
Each run produces a timestamped `.log` file containing PowerShell output, including job statuses, timeouts, and webhook messages. These are mainly for manual runs or local testing.

### SQL Agent Job Logs
When the same exports run through SQL Agent Jobs (production mode), execution logs are not written to `Logs/`.
Instead, all output, errors, and warnings are captured directly in the SQL Agent Job History under the Output tab for each job step.
This approach keeps centralized, timestamped records inside SQL Server Management Studio (SSMS) and avoids redundant file writes on the FBRDATA host.

### Adding a New Query to an Export

### New Export Checklist
- [ ] Create SQL file under correct frequency folder
- [ ] Test query in SSMS
- [ ] Add config entry in corresponding JSON
- [ ] Verify Drive folder permissions for service account
- [ ] Test via batch launcher
- [ ] Schedule in SQL Agent with matching ConfigPath

1. Create `.sql` file in `Queries/{Frequency}/` (e.g., `Queries/Hourly/MyReport.sql`)
2. Add entry to corresponding `Configs/{Frequency}Exports.json`:
   ```json
   {
     "SQLServer": "FBRDATA",
     "Database": "DatabaseName",
     "QueryFilePath": "C:\\GDriveAPI\\Queries\\Hourly\\MyReport.sql",
     "DriveFileName": "MyReport.csv"
   }
   ```
3. Share the Google Drive folder with `driveuploadfbrdata@driveapi-fbrdata.iam.gserviceaccount.com` (if new folder)

## Key Implementation Patterns

### Config Format
Every entry requires:
- `SQLServer`: Target SQL Server instance (e.g., `FBRDATA`)
- `Database`: Target database (e.g., `ShopFloorN`, `Timeclock`, `PRODDIST`)
- `QueryFilePath`: Absolute path to `.sql` file
- `DriveFileName`: Output CSV filename in Google Drive

### CSV Output Handling
- Header row is unquoted (custom logic: `$csv[0] = $csv[0] -replace '"',''`)
- DateTime values formatted as `'yyyy-MM-dd HH:mm:ss'`
- Empty result sets produce single empty line (signals success, not error)
- Multi-row DataTable results properly flattened to CSV

### Parallel Job Management
- Each query runs in a separate PowerShell job (`Start-Job`)
- Per-job timeout: **660 seconds** (11 minutes)
- Overall process timeout: **700 seconds** (~11.5 minutes)
- Watchdog kills stuck processes using `Stop-Process` + process ID tracking
- Failed jobs trigger webhook notification with error details

### Drive Upsert Logic
- Queries Google Drive API: `'<FolderId>' in parents and name = '<FileName>' and trashed = false`
- **Update** if file exists (via `Files.Update()`); **Create** if new
- Both operations stream CSV directly (no temp files)

## Important Parameters & Defaults

- `-ConfigPath`: JSON config file location (required)
- `-WebhookURL`: Google Chat webhook for notifications (optional; defaults to silent)
- `-DriveFolderId`: This deployment uses a single shared folder via `-DriveFolderId`; configs define only file names.
- `-ServiceAccountKeyPath`: Path to `driveapi-fbrdata.json`
- `-NugetBasePath`: DLL load path for Google APIs (defaults to `C:\GDriveAPI\lib`)

## Integration Points

### SQL Server Dependencies
- Requires `SqlServer` PowerShell module (auto-installed if missing)
- Uses `Invoke-Sqlcmd` with `-InputFile` parameter
- Connects to multiple databases on `FBRDATA` instance

### Google Drive API
- .NET assemblies loaded dynamically from `lib/` directory
- Service account scopes: `https://www.googleapis.com/auth/drive`
- No user authentication; uses service account credentials

### Google Chat Webhooks
- Success: "✓ Exported {count} rows to {filename}"
- Timeout: "TIMED OUT {filename} | Elapsed={seconds}s | PID={processid}"
- Failure: "FAILED {filename} | Server={server}\{database} | Query={path} | Error={message}"

## Common Patterns to Follow

1. **Query design**: Select specific columns; avoid `SELECT *` and internal/system columns
2. **Query naming**: Use descriptive names matching the CSV output (e.g., `EmployeeMasterOccGrad.sql` → `EmployeeMasterOccGrad.csv`)
3. **Error recovery**: Exports are designed to be idempotent—re-running with same config overwrites/updates Drive file
4. **Scheduling**: Via SQL Agent Jobs; each config frequency (Hourly, Daily, Weekly, etc.) has a corresponding SQL Agent job that invokes the PowerShell script with the appropriate `-ConfigPath`

## Troubleshooting

- **"Config file not found"**: Verify `-ConfigPath` absolute path is correct
- **Timeout warnings in logs**: Job exceeded 660s limit; reduce query complexity or increase `$JobTimeoutSec` in template
- **Google API assembly load failure**: Ensure `.dll` files exist in `lib/` (Google.Apis.Drive.v3, Google.Apis.Auth, Newtonsoft.Json, etc.)
- **Drive file not updating**: Verify service account email is shared on target Drive folder with **Editor** permissions
- **Webhook not firing**: Check webhook URL is valid and not expired; failures are logged but won't block export

## Files NOT to Modify Without Care

- `Token/driveapi-fbrdata.json` – Service account credentials; do not commit to version control
- `Templates/OG Scripts - DO NOT DELETE OR CHANGE/` – Legacy backup scripts; preserved for reference
- `RunExports.bat` – Batch launcher; coordinate script path updates if template moves

## Security & Credentials

**CRITICAL**: This repo should **not** be pushed to public Git hosting with credentials present.

- `Token/driveapi-fbrdata.json` contains sensitive Google service account credentials
- Ensure this file has **restricted NTFS permissions** (readable only by the SQL Agent service account and administrators)
- If credentials are ever exposed, regenerate the service account key in Google Cloud Console immediately
