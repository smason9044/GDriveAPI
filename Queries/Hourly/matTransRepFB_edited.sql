SELECT LocDate,
       COUNT(TranSourceNum) AS TotalScans,
       MonthName as Month,
       YEAR(LocDate) AS Year
FROM
(
    SELECT DISTINCT
           A.TranDate,
           A.PartNo,
           A.TranSourceNum,
           A.Qty,
           C.SHP_Tracking,
           FORMAT(DATEADD(hh, 3, A.TranDate), 'MM-dd-yy') AS LocDate,
           DATENAME(month, DATEADD(hh, 3, A.TranDate)) AS MonthName
    FROM PRODDIST.dbo.BTS_GoogleIntInvTranForMTView A
        LEFT OUTER JOIN PRODDIST.Erp.EDI_OrdStatusGoo B
            ON (A.TranSourceNum = B.MTNO)
               AND (A.Plant = B.Plant)
        LEFT OUTER JOIN PRODDIST.dbo.RPT_SHPHeadDetail C
            ON (A.TranSourceNum = C.OH_MTNum)
               AND (A.Plant = C.SHP_Plant)
    WHERE A.Plant = 'FB'
          AND C.SHP_Tracking = N'XX123'
          AND YEAR(DATEADD(hh, 3, TranDate)) >= YEAR(GETDATE() - 365)/*dateadd(hh,3,TranDate) >= '2022-01-01 00:00:00'*/
) a
GROUP BY LocDate,
         MonthName
ORDER BY Year DESC,
         LocDate



