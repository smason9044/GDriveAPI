SELECT FORMAT(DATE, 'yyyy-MM-dd') AS DATE,
       Day,
       [Function Area],
       HC,
       Shift,
       Attendance
FROM Timeclock.dbo.MIMAttTracker_FB
ORDER BY [Function Area],
         Attendance