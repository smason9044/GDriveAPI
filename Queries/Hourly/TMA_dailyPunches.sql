SET datefirst 1
SELECT *
FROM
(
    SELECT *,
           CASE
               WHEN InFlag = 1
                    OR OutFlag = 1 THEN
                   'Punch EarlyOut/Late'
               WHEN SchShiftInTime IS NULL
                    OR SchShiftOutTime IS NULL
                    OR ActShiftOutTime IS NULL THEN
                   'Missing Sch/Punch'
               ELSE
                   'None'
           END AS Discrepancy
    FROM
    (
        SELECT YRWK,
               Day,
               ClkSeqNo,
               DATE,
               Shift,
               EmpID,
               CategoryName,
               LongName,
               Dept,
               JobTitle,
               SchShiftInTime,
               ActShiftInTime,
               SchShiftOutTime,
               ActShiftOutTime,
               CASE
                   WHEN ActShiftInTime_New > SchShiftInTime_New THEN
                       1
                   ELSE
                       0
               END AS InFlag,
               CASE
                   WHEN ActShiftOutTime_New < SchShiftOutTime_New THEN
                       1
                   ELSE
                       0
               END AS OutFlag
        FROM TimeClock.dbo.RPTMaster_DailyHours
        WHERE PayRateType != 'S'
              AND ActShiftInTime IS NOT NULL
              AND CategoryCode = 1001
              AND DATE
              BETWEEN DATEADD(day, - (DATEPART(WEEKDAY, GETDATE()) + 5), CONVERT(DATE, GETDATE())) AND CONVERT(
                                                                                                                  DATE,
                                                                                                                  GETDATE()
                                                                                                              )
    ) a
) b
WHERE (
          (
              DATEPART(weekday, GETDATE()) = 1
              AND DATEDIFF(day, DATEPART(iso_week, DATE), DATEPART(iso_week, GETDATE())) = 1
          )
          OR
          (
              (DATEPART(weekday, GETDATE())
      BETWEEN 2 AND 7
              )
              AND DATEDIFF(day, DATEPART(iso_week, DATE), DATEPART(iso_week, GETDATE())) = 0
          )
      )
      AND Discrepancy LIKE 'Missing%'
      AND CONVERT(DATE, DATE) <= CONVERT(DATE, GETDATE())
ORDER BY DATE