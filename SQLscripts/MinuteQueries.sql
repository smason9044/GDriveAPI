/*=============================================================
  0.  Delete any existing jobs so the script is re-runnable
=============================================================*/
USE msdb;
GO

DECLARE @jobName SYSNAME;

DECLARE cur CURSOR FOR
SELECT name
FROM   msdb.dbo.sysjobs
WHERE  name IN ( N'Export 5min SQL Reports to Google Drive',
                 N'Export 10min SQL Reports to Google Drive',
                 N'Export 15min SQL Reports to Google Drive',
                 N'Export 30min SQL Reports to Google Drive',
                 N'Export 45min SQL Reports to Google Drive' );

OPEN  cur;
FETCH NEXT FROM cur INTO @jobName;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC msdb.dbo.sp_delete_job
         @job_name = @jobName,
         @delete_unused_schedule = 1;
    FETCH NEXT FROM cur INTO @jobName;
END
CLOSE cur;
DEALLOCATE cur;
GO

/*=============================================================
  1.  Helper proc – creates ONE interval job + schedule
=============================================================*/
IF OBJECT_ID('tempdb..#add_interval_job') IS NOT NULL
    DROP PROC #add_interval_job;
GO

CREATE PROC #add_interval_job @IntervalMinutes INT
AS
BEGIN
    SET NOCOUNT ON;

    /* ---------  Build the strings first  --------- */
    DECLARE
        @str        NVARCHAR(10),
        @JobName    SYSNAME,
        @StepName   SYSNAME,
        @SchedName  SYSNAME,
        @CfgPath    NVARCHAR(260),
        @Desc       NVARCHAR(200),
        @Cmd        NVARCHAR(4000);

    SET @str      = CAST(@IntervalMinutes AS NVARCHAR(10));
    SET @JobName  = N'Export ' + @str + N'min SQL Reports to Google Drive';
    SET @StepName = N'Run ' + @str + N'minExports.ps1';
    SET @SchedName= N'Export_' + @str + N'min_Schedule';
    SET @CfgPath  = N'C:\GDriveAPI\Configs\' + @str + N'minExports.json';
    SET @Desc     = N'Exports queries every ' + @str + N' minutes to Google Drive.';
    SET @Cmd      = N'powershell.exe -ExecutionPolicy Bypass ' +
                    N'-File "C:\GDriveAPI\Templates\Export-QueriesToDrive-Parallel.ps1" ' +
                    N'-ConfigPath "' + @CfgPath + N'"';

    /* --------- 1) Job --------- */
    EXEC msdb.dbo.sp_add_job
         @job_name         = @JobName,
         @enabled          = 1,
         @description      = @Desc,
         @category_name    = N'[Uncategorized (Local)]',
         @owner_login_name = N'sa';

    /* --------- 2) Step --------- */
    EXEC msdb.dbo.sp_add_jobstep
         @job_name       = @JobName,
         @step_name      = @StepName,
         @subsystem      = N'CmdExec',
         @command        = @Cmd,
         @retry_attempts = 1,
         @retry_interval = 5;

    /* --------- 3) Schedule --------- */
    EXEC msdb.dbo.sp_add_schedule
         @schedule_name        = @SchedName,
         @enabled              = 1,
         @freq_type            = 4,                -- daily
         @freq_interval        = 1,                -- every day
         @freq_subday_type     = 4,                -- minutes
         @freq_subday_interval = @IntervalMinutes, -- every n minutes
         @active_start_date    = 20250101,         -- adjust if needed
         @active_start_time    = 000000;           -- start at midnight

    /* --------- 4) Attach & target server --------- */
    EXEC msdb.dbo.sp_attach_schedule
         @job_name      = @JobName,
         @schedule_name = @SchedName;

    EXEC msdb.dbo.sp_add_jobserver
         @job_name    = @JobName,
         @server_name = N'(local)';               -- change if remote
END
GO

/*=============================================================
  2.  Build the five jobs
=============================================================*/
EXEC #add_interval_job 5;
EXEC #add_interval_job 10;
EXEC #add_interval_job 15;
EXEC #add_interval_job 30;
EXEC #add_interval_job 45;
GO

/*=============================================================
  3.  Optional cleanup
DROP PROC #add_interval_job;
GO
=============================================================*/