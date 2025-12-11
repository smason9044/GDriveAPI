USE [msdb]
GO

-- Create the Hourly Export Job
EXEC msdb.dbo.sp_add_job
    @job_name = N'Export Hourly SQL Reports to Google Drive',
    @enabled = 1,
    @description = N'Exports multiple queries hourly to Google Drive.',
    @category_name = N'[Uncategorized (Local)]',
    @owner_login_name = N'sa';
GO

-- Add a Job Step
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Export Hourly SQL Reports to Google Drive',
    @step_name = N'Run HourlyExports.ps1',
    @subsystem = N'CmdExec',
    @command = N'powershell.exe -ExecutionPolicy Bypass -File "C:\GDriveAPI\Templates\Export-QueriesToDrive.ps1" -ConfigPath "C:\GDriveAPI\Configs\HourlyExports.json"',
    @retry_attempts = 1,
    @retry_interval = 5;
GO

-- Create a Schedule (Every 1 Hour)
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'HourlyExports_Schedule',
    @enabled = 1,
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @freq_subday_type = 8, -- Hours
    @freq_subday_interval = 1,
    @active_start_time = 0000; -- Midnight
GO

-- Attach Schedule to Job
EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'Export Hourly SQL Reports to Google Drive',
    @schedule_name = N'HourlyExports_Schedule';
GO

-- Assign Job to Server
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'Export Hourly SQL Reports to Google Drive',
    @server_name = N'(local)';
GO