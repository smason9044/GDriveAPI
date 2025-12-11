SELECT RPT_LastWorkedDate_FB.UserID,
       RPT_LastWorkedDate_FB.EMP_FirstName,
       RPT_LastWorkedDate_FB.EMP_LastName,
       format(RPT_LastWorkedDate_FB.EMP_StartDate, 'yyyy-MM-dd') as EMP_StartDate,
       format(RPT_LastWorkedDate_FB.EMP_EndDate, 'yyyy-MM-dd') as EMP_EndDate,
       RPT_LastWorkedDate_FB.EMP_EmpStatus,
       RPT_LastWorkedDate_FB.EMP_ShiftDesc,
       RPT_LastWorkedDate_FB.EMP_JobTitle,
       RPT_LastWorkedDate_FB.EMP_ExpenseType,
       format(RPT_LastWorkedDate_FB.LastWorkedDate, 'yyyy-MM-dd') as LastWorkedDate,
       RPT_LastWorkedDate_FB.YRWK,
       RPT_LastWorkedDate_FB.Day,
       RPT_LastWorkedDate_FB.ShiftInTime,
       RPT_LastWorkedDate_FB.Shiftouttime,
       CASE
           WHEN RPT_LastWorkedDate_FB.EMP_TempStatus = 'X' THEN
               'TERM IN PROCESS'
           WHEN RPT_LastWorkedDate_FB.EMP_TempStatus = 'H' THEN
               'HOLD'
           ELSE
               RPT_LastWorkedDate_FB.EMP_TempStatus
       END AS TempStatus
FROM TimeClock.dbo.RPT_LastWorkedDate_FB
ORDER BY LastWorkedDate,
         YRWK