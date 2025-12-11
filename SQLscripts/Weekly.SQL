USE [msdb]
GO

-- Create the Weekly Export Job
EXEC msdb.dbo.sp_add_job
    @job_name = N'Export Weekly SQL Reports to Google Drive',
    @enabled = 1,
    @description = N'Exports multiple queries weekly to Google Drive.',
    @category_name = N'[Uncategorized (Local)]',
    @owner_login_name = N'sa';
GO

-- Add a Job Step
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Export Weekly SQL Reports to Google Drive',
    @step_name = N'Run WeeklyExports.ps1',
    @subsystem = N'CmdExec',
    @command = N'powershell.exe -ExecutionPolicy Bypass -File "C:\GDriveAPI\Templates\Export-QueriesToDrive.ps1" -ConfigPath "C:\GDriveAPI\Configs\WeeklyExports.json"',
    @retry_attempts = 1,
    @retry_interval = 5;
GO

-- Create a Schedule (Every Sunday at 3AM)
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'WeeklyExports_Schedule',
    @enabled = 1,
    @freq_type = 8,  -- Weekly
    @freq_interval = 1,
    @freq_recurrence_factor = 1,
    @active_start_time = 030000, -- 3:00 AM
    @active_start_date = 20250101, -- Start immediately
    @freq_subday_type = 1,
    @freq_subday_interval = 0,
    @freq_relative_interval = 0,
    @freq_interval_days_of_week = 1; -- Sunday
GO

-- Attach Schedule to Job
EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'Export Weekly SQL Reports to Google Drive',
    @schedule_name = N'WeeklyExports_Schedule';
GO

-- Assign Job to Server
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'Export Weekly SQL Reports to Google Drive',
    @server_name = N'(local)';
GO