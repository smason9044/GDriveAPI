SELECT
    [Yrwk],
    [Day],
    [EmpID],
    [First Name],
    [Last Name],
    [JobTitle],
    [ExpenseType],
	Shift,
    ----[Dept],
    [SchShiftInTime],
    [ActShiftInTime],
    [SchShiftOutTime],
    [ActShiftOutTime],
    [ActualHoursWorked],
    [RoundedHoursWorked]
    --ROW_NUMBER() OVER (PARTITION BY a.YRWK, a.DAY, a.EmpID ORDER BY a.CategoryCode DESC) AS No
FROM [TimeClock].[dbo].[Payroll_History] a
WHERE
YRWK BETWEEN qualityreporting.dbo.udf_yearweek(DATEADD(MONTH, -3, GETDATE())) 
    AND qualityreporting.dbo.udf_yearweek(DATEADD(MONTH, 0, GETDATE()))
    AND COALESCE(SchShiftInTime, ActShiftInTime, ActShiftOutTime) IS NOT NULL
    --AND SchShiftInTime != '00:00:00'
    --AND RoundedHoursWorked != '0.00'
    AND Dept = 'LOGISTICS'
    AND DATEDIFF(MINUTE, SchShiftOutTime, ActShiftOutTime) > 5
