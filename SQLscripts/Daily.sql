USE [msdb]
GO

-- Create the Daily Export Job
EXEC msdb.dbo.sp_add_job
    @job_name = N'Export Daily SQL Reports to Google Drive',
    @enabled = 1,
    @description = N'Exports multiple queries daily to Google Drive.',
    @category_name = N'[Uncategorized (Local)]',
    @owner_login_name = N'sa';
GO

-- Add a Job Step
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Export Daily SQL Reports to Google Drive',
    @step_name = N'Run DailyExports.ps1',
    @subsystem = N'CmdExec',
    @command = N'powershell.exe -ExecutionPolicy Bypass -File "C:\GDriveAPI\Templates\Export-QueriesToDrive.ps1" -ConfigPath "C:\GDriveAPI\Configs\DailyExports.json"',
    @retry_attempts = 1,
    @retry_interval = 5;
GO

-- Create a Schedule (Every Day at 2AM)
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'DailyExports_Schedule',
    @enabled = 1,
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @active_start_time = 020000; -- 2:00 AM
GO

-- Attach Schedule to Job
EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'Export Daily SQL Reports to Google Drive',
    @schedule_name = N'DailyExports_Schedule';
GO

-- Assign Job to Server
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'Export Daily SQL Reports to Google Drive',
    @server_name = N'(local)';
GO