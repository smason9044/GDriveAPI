SELECT
    x.Yrwk,
    x.[Day],
    x.EmpID,
    x.[First Name],
    x.[Last Name],
    x.[ExpenseType],
    x.[Dept],
    x.EmpShiftDesc,
    x.AssingnedShift,
    x.SchShiftInTime,
    x.ClockInShift,
    x.ActShiftInTime,
    x.SchShiftOutTime,
    x.ActShiftOutTime,
    x.ActualHoursWorked,
    x.RoundedHoursWorked
FROM (
    SELECT
        a.[Date],
        a.[Yrwk],
        a.[Day],
        a.[EmpID],
        a.[First Name],
        a.[Last Name],
        a.[Agency],
        a.[ExpenseType],
        a.[PayRateType],
        a.[Dept],
        a.[CategoryName],
        a.Shift AS EmpShiftDesc,
        CASE
            WHEN a.SchShiftInTime BETWEEN '03:00:00' AND '15:00:00' AND a.[Day] IN (1,2,3,4) THEN 'SHIFT 1'
            WHEN a.SchShiftInTime BETWEEN '15:00:00' AND '23:59:59' AND a.[Day] IN (1,2,3,4) THEN 'SHIFT 2'
            WHEN a.[Day] IN (5,6,7) AND a.SchShiftInTime BETWEEN '03:00:00' AND '15:00:00' THEN 'SHIFT 1 WE'
            WHEN a.SchShiftInTime = '00:00:00' THEN 'Not Scheduled'
            ELSE NULL
        END AS AssingnedShift,
        a.SchShiftInTime,
        CASE
            WHEN a.ActShiftInTime BETWEEN '03:00:00' AND '15:00:00' AND a.[Day] IN (1,2,3,4) THEN 'SHIFT 1'
            WHEN a.ActShiftInTime BETWEEN '15:00:00' AND '23:59:59' AND a.[Day] IN (1,2,3,4) THEN 'SHIFT 2'
            WHEN a.[Day] IN (5,6,7) AND a.ActShiftInTime BETWEEN '03:00:00' AND '15:00:00' THEN 'SHIFT 1 WE'
            WHEN a.ActShiftInTime = '00:00:00' THEN 'Not Scheduled'
            ELSE NULL
        END AS ClockInShift,
        a.ActShiftInTime,
        a.SchShiftOutTime,
        a.ActShiftOutTime,
        a.ActualHoursWorked,
        a.RoundedHoursWorked,
        a.JobTitle,
        ROW_NUMBER() OVER (
            PARTITION BY a.Yrwk, a.[Day], a.EmpID
            ORDER BY a.CategoryCode DESC
        ) AS [No]
    FROM TimeClock.dbo.Payroll_History AS a
    WHERE a.PayRateType = 'H'
      AND a.YRWK BETWEEN qualityreporting.dbo.udf_yearweek(DATEADD(MONTH,-3,GETDATE()))
                     AND qualityreporting.dbo.udf_yearweek(GETDATE())
      AND COALESCE(a.SchShiftInTime, a.ActShiftInTime, a.ActShiftOutTime) IS NOT NULL
      AND a.SchShiftInTime <> '00:00:00'
) AS x
WHERE x.RoundedHoursWorked <> '0.00'
  AND (x.AssingnedShift <> x.ClockInShift OR x.EmpShiftDesc <> x.ClockInShift);