@echo off
SETLOCAL ENABLEEXTENSIONS

:: SET YOUR VARIABLES HERE
set PowerShellPath=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
set ScriptPath=C:\GDriveAPI\Templates\Export-QueriesToDrive-Parallel.ps1
set ConfigDir=C:\GDriveAPI\Configs
set LogDir=C:\GDriveAPI\Logs

if not exist "%LogDir%" mkdir "%LogDir%"

:: ASK USER WHICH EXPORT TO RUN
echo ==========================================
echo Which export do you want to run?
echo ==========================================
echo 1) HourlyExports.json
echo 2) DailyExports.json
echo 3) WeeklyExports.json
echo ==========================================
set /p choice=Enter your choice [1-3]: 

if "%choice%"=="1" set ConfigFile=HourlyExports.json
if "%choice%"=="2" set ConfigFile=DailyExports.json
if "%choice%"=="3" set ConfigFile=WeeklyExports.json

if "%ConfigFile%"=="" (
    echo ? Invalid choice. Exiting...
    exit /b 1
)

:: Build paths
set ConfigPath=%ConfigDir%\%ConfigFile%
set LogFile=%LogDir%\ExportRun_%ConfigFile%_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log

:: Normalize the log filename (remove spaces in time fields)
set LogFile=%LogFile: =0%

:: RUN THE POWERSHELL SCRIPT
echo ?? Launching export: %ConfigFile%
echo Saving log to: %LogFile%
%PowerShellPath% -ExecutionPolicy Bypass -NoProfile -File "%ScriptPath%" -ConfigPath "%ConfigPath%" > "%LogFile%" 2>&1

:: CHECK EXIT STATUS
if %ERRORLEVEL% NEQ 0 (
    echo ? PowerShell script FAILED! Check the log: %LogFile%
    pause
    exit /b 1
) else (
    echo ? PowerShell script completed successfully!
)

:: SHOW ROWS EXPORTED (pull from last lines of the log)
findstr /C:"? Exported" "%LogFile%" || echo (No export row count found in log)

echo ==========================================
echo Log file created: %LogFile%
echo ==========================================
pause
ENDLOCAL