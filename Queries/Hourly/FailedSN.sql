SELECT DISTINCT
       t1.BuiltYRWK,
       t1.AssetTagNum,
       t1.AsmBasePartNum,
       t1.AsmPlatform,
       BoxYRWK,
	   TestCount,
	   DefecSerialNum,
       DefectPartNum,
       HeaderSymptom
       ---Weekgroup
FROM
(
    SELECT DISTINCT
           B.BuiltYRWK,
           A.AssetTagNum,
           AsmBasePartNum,
           AsmPlatform,
           BoxYRWK,
           TestCount,
           DefectPartNum,
           DefecSerialNum,
           HeaderSymptom,
           Weekgroup
    FROM ShopFloorN.dbo.Base_FailureDebug_RawData A
        JOIN
        (
            SELECT CreateDate AS Induction,
                   Plant,
                   AssetTagNum,
                   WorkOrdNum,
                   A.RouteMasterID,
                   B.RouteMasterDesc,
                   EmpID,
                   CONCAT(
                             YEAR(DATEADD(DAY, 3 - ((DATEPART(WEEKDAY, CreateDate) + 5) % 7), CreateDate)),
                             'W',
                             FORMAT(DATEPART(ISO_WEEK, CreateDate), '00')
                         ) AS BuiltYRWK,
                   CASE
                       WHEN DATEPART(dw, GETDATE()) = 1 THEN
                           CASE
                               WHEN DATEPART(dw, CreateDate) = 1 THEN
                                   DATEDIFF(ww, GETDATE() - 1, CreateDate - 1) --,DATEDIFF(day,-1,@date),DATEDIFF(ww, getdate()-1,(@date -1))
                               ELSE
                                   DATEDIFF(ww, GETDATE() - 1, CreateDate)
                           END
                       ELSE
                           CASE
                               WHEN DATEPART(dw, CreateDate) = 1 THEN
                                   DATEDIFF(ww, GETDATE(), CreateDate - 1) --,DATEDIFF(day,-1,@date),DATEDIFF(ww, getdate()-1,(@date -1))
                               ELSE
                                   DATEDIFF(ww, GETDATE(), CreateDate)
                           END
                   END AS Weekgroup
            FROM [ShopFloorN].[dbo].[SFAssetTagRouteStatusView] A
                LEFT JOIN ShopFloorN.dbo.RouteMasterView B
                    ON A.RouteMasterID = B.RouteMasterID
            WHERE Plant = 'FB'
                  AND B.RouteMasterDesc LIKE 'APPLY%TAG%'
                  AND CreateDate >= GETDATE() - 60
        ) B
            ON A.AssetTagNum = B.AssetTagNum
    WHERE Weekgroup >= -5
          AND DebugActionDesc = 'PART SWAP'
          AND AsmPlanGroup = 'TRAY-ASM'
) t1
ORDER BY BuiltYRWK

