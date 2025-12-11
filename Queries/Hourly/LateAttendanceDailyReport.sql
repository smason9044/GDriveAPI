SELECT format(DATE,'yyyy-MM-dd') as DATE,
       YRWK,
       Day,
       A.EmpID,
       A.LongName,
       A.Shift,
       A.Dept,
       --A.CategoryCode,
       SchShiftInTime,
       --SchShiftInTime_New,
       ActShiftInTime,
       --ActShiftInTime_New,
       SchShiftOutTime,
       ActShiftOutTime,
      -- TORequest.PCID,
       CASE
           WHEN PayCategories.CategoryCode IS NULL THEN
               'Regular'
           ELSE
               PayCategories.CategoryName
       END AS Reason,
       RPTMaster_SupvAssign.SupName,
       RPTMaster_SupvAssign.SupRole
FROM TimeClock.dbo.RPTMaster_DailyHours A
    LEFT JOIN
    (
        SELECT *
        FROM
        (
            SELECT DISTINCT
                   *,
                   ROW_NUMBER() OVER (PARTITION BY EmpID, StartDate ORDER BY PCID) AS PC
            FROM TimeClock.dbo.TORequest
        ) a
        WHERE PC = 1
    ) TORequest
        ON TORequest.EmpID = A.EmpID
           AND A.[Date] = TORequest.StartDate
    LEFT JOIN TimeClock.dbo.PayCategories
        ON PayCategories.PCID = TORequest.PCID
    LEFT JOIN
    (
        SELECT DISTINCT
               EmpID,
               SupName,
               SupRole
        FROM TimeClock.dbo.RPTMaster_SupvAssign
    ) AS RPTMaster_SupvAssign
        ON RPTMaster_SupvAssign.EmpID = A.EmpID
WHERE ActShiftInTime_New >= DATEADD(HOUR, 4, SchShiftInTime_New)
      AND ClkSeqNo = 1
ORDER BY ActShiftInTime_New DESC