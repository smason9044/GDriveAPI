WITH CTE
AS (SELECT A.Plant,
           BoxYRWK,
           BoxDate,
           A.WorkOrdNum,
           AsmBasePartNum,
           AsmPlanGroup,
           AsmPlatform,
           A.AssetTagNum,
           TestStep,
           TestCount,
           TestErrorSymptom,
           DebugActionDesc,
           DebugFixedFlag,
           DebugNotes,
           Tester,
           TesterID,
           ROW_NUMBER() OVER (PARTITION BY A.Plant,
                                           A.AssetTagNum,
                                           TestStep,
                                           TestCount
                              ORDER BY A.FailDetailDateTime
                             ) AS RowNumFailDateTime,
           CASE
               WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
                   'CABLING ERROR'
               WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
                   'TEST SET UP'
               WHEN DebugNotes LIKE 'HUMAN ERROR - TLA' THEN
                   'TLA'
               ELSE
                   ''
           END AS Debug
    FROM ShopFloorN.dbo.Base_FailureDebug_RawData A
    WHERE A.AsmPlanGroup = 'RACK-ASM'
          AND BoxDate >= CONVERT(DATE, GETDATE() - 120)
    UNION ALL
    SELECT A.Plant,
           BoxYRWK,
           BoxDate,
           A.WorkOrdNum,
           AsmBasePartNum,
           AsmPlanGroup,
           AsmPlatform,
           A.AssetTagNum,
           TestStep,
           TestCount,
           TestErrorSymptom,
           DebugActionDesc,
           DebugFixedFlag,
           DebugNotes,
           Tester,
           TesterID,
           ROW_NUMBER() OVER (PARTITION BY A.Plant,
                                           A.AssetTagNum,
                                           TestStep,
                                           TestCount
                              ORDER BY A.FailDetailDateTime
                             ) AS RowNumFailDateTime,
           CASE
               WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
                   'CABLING ERROR'
               WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
                   'TEST SET UP'
               WHEN DebugNotes LIKE 'HUMAN ERROR - TLA' THEN
                   'TLA'
               ELSE
                   ''
           END AS Debug
    FROM NFShopFloorN.dbo.Base_FailureDebug_RawData A
    WHERE A.AsmPlanGroup = 'RACK-ASM'
          AND BoxDate >= CONVERT(DATE, GETDATE() - 120)),
     CTE2
AS (SELECT CreateDate AS Induction,
           CONCAT(
                     YEAR(DATEADD(DAY, 3 - ((DATEPART(WEEKDAY, CreateDate) + 5) % 7), CreateDate)),
                     'W',
                     FORMAT(DATEPART(ISO_WEEK, CreateDate), '00')
                 ) AS BuildYRWK_CTE2,
           Plant,
           AssetTagNum,
           WorkOrdNum,
           A.RouteMasterID,
           B.RouteMasterDesc,
           EmpID,
           AsmLine
    FROM [ShopFloorN].[dbo].[SFAssetTagRouteStatusView] A
        LEFT JOIN ShopFloorN.dbo.RouteMasterView B
            ON A.RouteMasterID = B.RouteMasterID
    WHERE Plant = 'FB'
          AND B.RouteMasterDesc LIKE 'APPLY%TAG%'
          AND A.CreateDate >= GETDATE() - 150
    UNION ALL
    SELECT CreateDate AS Induction,
           CONCAT(
                     YEAR(DATEADD(DAY, 3 - ((DATEPART(WEEKDAY, CreateDate) + 5) % 7), CreateDate)),
                     'W',
                     FORMAT(DATEPART(ISO_WEEK, CreateDate), '00')
                 ) AS BuildYRWK_CTE2,
           Plant,
           AssetTagNum,
           WorkOrdNum,
           A.RouteMasterID,
           B.RouteMasterDesc,
           EmpID,
           AsmLine
    FROM [NFShopFloorN].[dbo].[SFAssetTagRouteStatusView] A
        LEFT JOIN ShopFloorN.dbo.RouteMasterView B
            ON A.RouteMasterID = B.RouteMasterID
    WHERE Plant = 'NF'
          AND B.RouteMasterDesc LIKE 'APPLY%TAG%'
          AND A.CreateDate >= GETDATE() - 150),
     CTE3
AS (SELECT CTE.Plant,
           BuildYRWK_CTE2,
           BoxYRWK,
           BoxDate,
           CTE.WorkOrdNum,
           CTE2.AsmLine,
           AsmBasePartNum,
           AsmPlanGroup,
           AsmPlatform,
           CTE.AssetTagNum,
           TestStep,
           TestCount,
           TestErrorSymptom,
           DebugActionDesc,
           DebugFixedFlag,
           DebugNotes,
           Tester,
           TesterID,
           Debug,
           DENSE_RANK() OVER (PARTITION BY CTE.Plant,
                                           BuildYRWK_CTE2,
                                           CTE.TesterID
                              ORDER BY CTE.AssetTagNum ASC
                             ) + DENSE_RANK() OVER (PARTITION BY CTE.Plant,
                                                                 BuildYRWK_CTE2,
                                                                 CTE.TesterID
                                                    ORDER BY CTE.AssetTagNum DESC
                                                   ) - 1 AS CountOfATsTested,
           t1.EMP_LongName,
           t1.EMP_ShiftDesc,
           CASE
               WHEN LEFT(t1.EMP_JobTitle, 1) = 'N' THEN
                   'NTLA'
               ELSE
                   'RTLA'
           END AS breakdown
    FROM CTE
        LEFT JOIN CTE2
            ON CTE.AssetTagNum = CTE2.AssetTagNum
        LEFT JOIN PRODDIST.dbo.Base_EMPBasic t1
            ON CTE.TesterID = t1.EMP_EmpID
    WHERE RowNumFailDateTime = 1),
     CTE4
AS (SELECT A.Plant,
           CreateDate,
           CONCAT(
                     YEAR(DATEADD(DAY, 3 - ((DATEPART(WEEKDAY, DateOfInduction) + 5) % 7), DateOfInduction)),
                     'W',
                     FORMAT(DATEPART(ISO_WEEK, DateOfInduction), '00')
                 ) AS BuildYRWK_CTE4,
           A.AssetTagNum,
           A.EmpID,
           EMP_LongName,
           EMP_ShiftDesc,
           EMP_JobTitle,
           RouteMasterDesc,
           RouteStatus,
           --AsmLineAssigned,
           ROW_NUMBER() OVER (PARTITION BY A.AssetTagNum,
                                           RouteMasterDesc,
                                           EmpID
                              ORDER BY CreateDate DESC
                             ) RowCabling
    FROM ShopFloorN.dbo.SFTranHistoryView_All A
    WHERE (
              RouteMasterDesc = 'CABLE ASSEMBLY'
              OR
              (
                  RouteMasterDesc = 'CABLE QA'
                  AND RouteStatus = 'P'
              )
          )
          AND AsmPlanGroup = 'RACK-ASM'
          AND CreateDate >= GETDATE() - 150
          AND A.Plant = 'FB'
    UNION ALL
    SELECT A.Plant,
           CreateDate,
           CONCAT(
                     YEAR(DATEADD(DAY, 3 - ((DATEPART(WEEKDAY, DateOfInduction) + 5) % 7), DateOfInduction)),
                     'W',
                     FORMAT(DATEPART(ISO_WEEK, DateOfInduction), '00')
                 ) AS BuildYRWK_CTE4,
           A.AssetTagNum,
           A.EmpID,
           EMP_LongName,
           EMP_ShiftDesc,
           EMP_JobTitle,
           RouteMasterDesc,
           RouteStatus,
           --AsmLineAssigned,
           ROW_NUMBER() OVER (PARTITION BY A.AssetTagNum,
                                           RouteMasterDesc,
                                           EmpID
                              ORDER BY CreateDate DESC
                             ) RowCabling
    FROM NFShopFloorN.dbo.SFTranHistoryView_All A
    WHERE (
              RouteMasterDesc = 'CABLE ASSEMBLY'
              OR
              (
                  RouteMasterDesc = 'CABLE QA'
                  AND RouteStatus = 'P'
              )
          )
          AND AsmPlanGroup = 'RACK-ASM'
          AND CreateDate >= GETDATE() - 150
          AND A.Plant = 'NF'),
     CTE5
AS (SELECT Plant,
           BuildYRWK_CTE4,
           AssetTagNum,
           EmpID,
           EMP_LongName,
           EMP_ShiftDesc,
           RouteMasterDesc,
           CASE
               WHEN LEFT(EMP_JobTitle, 1) = 'N' THEN
                   'NTLA'
               ELSE
                   'RTLA'
           END AS breakdown,
           --AsmLineAssigned,
           DENSE_RANK() OVER (PARTITION BY Plant,
                                           BuildYRWK_CTE4,
                                           EmpID,
                                           RouteMasterDesc
                              ORDER BY AssetTagNum ASC
                             ) + DENSE_RANK() OVER (PARTITION BY Plant,
                                                                 BuildYRWK_CTE4,
                                                                 EmpID,
                                                                 RouteMasterDesc
                                                    ORDER BY AssetTagNum DESC
                                                   ) - 1 AS CountOfATs,
           'CABLING ERROR' AS DebugNote
    FROM CTE4
    WHERE RowCabling = 1)
SELECT CTE3.Plant,
       CTE3.BuildYRWK_CTE2 AS BuildYRWK,
       CTE3.BoxYRWK,
       CTE3.WorkOrdNum,
       CTE3.AsmBasePartNum,
       CTE3.AsmPlatform,
       CTE3.AssetTagNum,
       CTE3.TestStep,
       CTE3.TestCount,
       CTE3.Tester,
       CTE3.TestErrorSymptom,
       DebugActionDesc,
       CTE3.DebugNotes,
       CTE3.AsmLine,
       CASE
           WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
               CTE5.RouteMasterDesc
           WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
               'TEST SET UP ERR'
           WHEN Debugnotes LIKE 'HUMAN ERROR - TLA' THEN
               'TLA ERR'
       END AS RouteMasterDesc, --B.RouteMasterDesc
       CASE
           WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
               CTE5.EmpID
           WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
               CTE3.TesterID
           WHEN Debugnotes LIKE 'HUMAN ERROR - TLA' THEN
               NULL
       END AS EmpID,           --B.EmpID
       CASE
           WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
               CTE5.EMP_LongName
           WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
               CTE3.EMP_LongName
           WHEN Debugnotes LIKE 'HUMAN ERROR - TLA' THEN
               NULL
       END AS EMP_LongName,    --B.EMP_LongName
       CASE
           WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
               CTE5.EMP_ShiftDesc
           WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
               CTE3.EMP_ShiftDesc
           WHEN Debugnotes LIKE 'HUMAN ERROR - TLA' THEN
               NULL
       END AS EMP_ShiftDesc,   --B.EMP_ShiftDesc
       CASE
           WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
               CTE5.breakdown
           WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
               CTE3.breakdown
           WHEN Debugnotes LIKE 'HUMAN ERROR - TLA' THEN
               NULL
       END AS Breakdown,       --B.breakdown
       CTE5.CountOfATs,
       CTE3.CountOfATsTested
FROM CTE3
    LEFT JOIN CTE5
        ON CTE3.Plant = CTE5.Plant
           AND CTE3.AssetTagNum = CTE5.AssetTagNum
           AND CTE3.BuildYRWK_CTE2 = CTE5.BuildYRWK_CTE4
           AND CTE3.Debug = CTE5.DebugNote
WHERE (
          CTE3.DebugNotes LIKE 'HUMAN ERROR%CABLING%'
          OR CTE3.DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%'
          OR
          (
              CTE3.Debugnotes LIKE 'HUMAN ERROR - TLA'
              AND CTE3.TestErrorSymptom NOT LIKE '%SFS-INFO-VALIDATION-FAIL%'
          )
      )
ORDER BY Plant,
         BuildYRWK,
         AssetTagNum,
         TestStep

/*SELECT 
       A.Plant,
       A.BuildYRWK,
       A.BoxYRWK,
       A.WorkOrdNum,
       AsmBasePartNum,
       A.AsmPlatform,
       A.AssetTagNum,
       A.TestStep,
       A.TestCount,
       A.Tester,
       A.TestErrorSymptom,
       DebugActionDesc,
       A.DebugNotes,
       AsmLineAssigned,
       CASE
           WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
               B.RouteMasterDesc
           WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
               'TEST SET UP ERR'
           WHEN Debugnotes LIKE 'HUMAN ERROR - TLA' THEN
               'TLA ERR'
       END AS RouteMasterDesc, --B.RouteMasterDesc
       CASE
           WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
               B.EmpID
           WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
               A.TesterID
           WHEN Debugnotes LIKE 'HUMAN ERROR - TLA' THEN
               NULL
       END AS EmpID,           --B.EmpID
       CASE
           WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
               B.EMP_LongName
           WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
               A.EMP_LongName
           WHEN Debugnotes LIKE 'HUMAN ERROR - TLA' THEN
               NULL
       END AS EMP_LongName,    --B.EMP_LongName
       CASE
           WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
               B.EMP_ShiftDesc
           WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
               A.EMP_ShiftDesc
           WHEN Debugnotes LIKE 'HUMAN ERROR - TLA' THEN
               NULL
       END AS EMP_ShiftDesc,   --B.EMP_ShiftDesc
       CASE
           WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
               B.breakdown
           WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
               A.breakdown
           WHEN Debugnotes LIKE 'HUMAN ERROR - TLA' THEN
               NULL
       END AS Breakdown,       --B.breakdown
       B.CountOfATs,
       A.CountOfATsTested
FROM
(
    SELECT t1.*,
           DENSE_RANK() OVER (PARTITION BY Plant, BuildYRWK, TesterID ORDER BY assettagnum ASC)
           + DENSE_RANK() OVER (PARTITION BY Plant, BuildYRWK, TesterID ORDER BY assettagnum DESC) - 1 AS CountOfATsTested,
           t2.EMP_LongName,
           t2.EMP_ShiftDesc,
           CASE
               WHEN LEFT(t2.EMP_JobTitle, 1) = 'N' THEN
                   'NTLA'
               ELSE
                   'RTLA'
           END AS breakdown
    FROM
    (
        SELECT 
               A.Plant,
               CONCAT(
                         YEAR(DATEADD(DAY, 3 - ((DATEPART(WEEKDAY, Induction) + 5) % 7), Induction)),
                         'W',
                         FORMAT(DATEPART(ISO_WEEK, Induction), '00')
                     ) AS BuildYRWK,
               BoxYRWK,
               BoxDate,
               A.WorkOrdNum,
               AsmBasePartNum,
               AsmPlanGroup,
               AsmPlatform,
               A.AssetTagNum,
               TestStep,
               TestCount,
               TestErrorSymptom,
               DebugActionDesc,
               DebugFixedFlag,
               DebugNotes,
               Tester,
               TesterID,
               ROW_NUMBER() OVER (PARTITION BY A.Plant,
                                               A.AssetTagNum,
                                               TestStep,
                                               TestCount
                                  ORDER BY A.FailDetailDateTime
                                 ) AS RowNumFailDateTime,
               CASE
                   WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
                       'CABLING ERROR'
                   WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
                       'TEST SET UP'
                   WHEN DebugNotes LIKE 'HUMAN ERROR - TLA' THEN
                       'TLA'
                   ELSE
                       ''
               END AS Debug
        FROM ShopFloorN.dbo.Base_FailureDebug_RawData A
            LEFT JOIN
            (
                SELECT CreateDate AS Induction,
                       Plant,
                       AssetTagNum,
                       WorkOrdNum,
                       A.RouteMasterID,
                       B.RouteMasterDesc,
                       EmpID
                FROM [ShopFloorN].[dbo].[SFAssetTagRouteStatusView] A
                    LEFT JOIN ShopFloorN.dbo.RouteMasterView B
                        ON A.RouteMasterID = B.RouteMasterID
                WHERE Plant = 'FB'
                      AND B.RouteMasterDesc LIKE 'APPLY%TAG%'
            ) B
                ON A.AssetTagNum = B.AssetTagNum
        WHERE A.AsmPlanGroup = 'RACK-ASM'
        UNION ALL
        SELECT 
               A.Plant,
               CONCAT(
                         YEAR(DATEADD(DAY, 3 - ((DATEPART(WEEKDAY, Induction) + 5) % 7), Induction)),
                         'W',
                         FORMAT(DATEPART(ISO_WEEK, Induction), '00')
                     ) AS BuildYRWK,
               BoxYRWK,
               BoxDate,
               A.WorkOrdNum,
               AsmBasePartNum,
               AsmPlanGroup,
               AsmPlatform,
               A.AssetTagNum,
               TestStep,
               TestCount,
               TestErrorSymptom,
               DebugActionDesc,
               DebugFixedFlag,
               DebugNotes,
               Tester,
               TesterID,
               ROW_NUMBER() OVER (PARTITION BY A.Plant,
                                               A.AssetTagNum,
                                               TestStep,
                                               TestCount
                                  ORDER BY A.FailDetailDateTime
                                 ) AS RowNumFailDateTime,
               CASE
                   WHEN DebugNotes LIKE 'HUMAN ERROR%CABLING%' THEN
                       'CABLING ERROR'
                   WHEN DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%' THEN
                       'TEST SET UP'
                   WHEN DebugNotes LIKE 'HUMAN ERROR - TLA' THEN
                       'TLA'
                   ELSE
                       ''
               END AS Debug
        FROM NFShopFloorN.dbo.Base_FailureDebug_RawData A
            LEFT JOIN
            (
                SELECT CreateDate AS Induction,
                       Plant,
                       AssetTagNum,
                       WorkOrdNum,
                       A.RouteMasterID,
                       B.RouteMasterDesc,
                       EmpID
                FROM [NFShopFloorN].[dbo].[SFAssetTagRouteStatusView] A
                    LEFT JOIN ShopFloorN.dbo.RouteMasterView B
                        ON A.RouteMasterID = B.RouteMasterID
                WHERE Plant = 'NF'
                      AND B.RouteMasterDesc LIKE 'APPLY%TAG%'
            ) B
                ON A.AssetTagNum = B.AssetTagNum
        WHERE A.AsmPlanGroup = 'RACK-ASM'
    ) t1
        LEFT JOIN PRODDIST.dbo.Base_EMPBasic t2
            ON t1.TesterID = t2.EMP_EmpID
    WHERE BoxDate >= CONVERT(DATE, GETDATE() - 120)
          AND RowNumFailDateTime = 1
) A
    LEFT JOIN
    (
        SELECT 
               Plant,
               BuildYRWK,
               AssetTagNum,
               EmpID,
               EMP_LongName,
               EMP_ShiftDesc,
               RouteMasterDesc,
               --ROW_NUMBER() OVER (PARTITION BY AssetTagNum,RouteMasterDesc order by CreateDate desc) as RowCountRDesc,
               CASE
                   WHEN LEFT(EMP_JobTitle, 1) = 'N' THEN
                       'NTLA'
                   ELSE
                       'RTLA'
               END AS breakdown,
               AsmLineAssigned,
               DENSE_RANK() OVER (PARTITION BY Plant,
                                               BuildYRWK,
                                               EmpID,
                                               RouteMasterDesc
                                  ORDER BY assettagnum ASC
                                 ) + DENSE_RANK() OVER (PARTITION BY Plant,
                                                                     BuildYRWK,
                                                                     EmpID,
                                                                     RouteMasterDesc
                                                        ORDER BY assettagnum DESC
                                                       ) - 1 AS CountOfATs,
               'CABLING ERROR' AS DebugNote
        FROM
        (
            SELECT 
                   A.Plant,
                   CreateDate,
                   CONCAT(
                             YEAR(DATEADD(DAY, 3 - ((DATEPART(WEEKDAY, DateOfInduction) + 5) % 7), DateOfInduction)),
                             'W',
                             FORMAT(DATEPART(ISO_WEEK, DateOfInduction), '00')
                         ) AS BuildYRWK,
                   A.AssetTagNum,
                   A.EmpID,
                   EMP_LongName,
                   EMP_ShiftDesc,
                   EMP_JobTitle,
                   RouteMasterDesc,
                   RouteStatus,
                   AsmLineAssigned
            FROM ShopFloorN.dbo.SFTranHistoryView_All A
            --join ShopFloorN.dbo.SFAssetTagGenView B on A.AssetTagNum = B.AssetTagNum
            WHERE (
                      RouteMasterDesc = 'CABLE ASSEMBLY'
                      OR
                      (
                          RouteMasterDesc = 'CABLE QA'
                          AND RouteStatus = 'P'
                      )
                  )
                  AND AsmPlanGroup = 'RACK-ASM'
                  AND CreateDate >= GETDATE() - 150
                  AND A.Plant = 'FB'
            UNION ALL
            SELECT 
                   A.Plant,
                   CreateDate,
                   CONCAT(
                             YEAR(DATEADD(DAY, 3 - ((DATEPART(WEEKDAY, DateOfInduction) + 5) % 7), DateOfInduction)),
                             'W',
                             FORMAT(DATEPART(ISO_WEEK, DateOfInduction), '00')
                         ) AS BuildYRWK,
                   A.AssetTagNum,
                   A.EmpID,
                   EMP_LongName,
                   EMP_ShiftDesc,
                   EMP_JobTitle,
                   RouteMasterDesc,
                   RouteStatus,
                   AsmLineAssigned
            FROM NFShopFloorN.dbo.SFTranHistoryView_All A
            --join NFShopFloorN.dbo.SFAssetTagGenView B on A.AssetTagNum = B.AssetTagNum
            WHERE (
                      RouteMasterDesc = 'CABLE ASSEMBLY'
                      OR
                      (
                          RouteMasterDesc = 'CABLE QA'
                          AND RouteStatus = 'P'
                      )
                  )
                  AND AsmPlanGroup = 'RACK-ASM'
                  AND CreateDate >= GETDATE() - 150
                  AND A.Plant = 'NF'
        ) t1
    ) B
        ON A.Plant = B.Plant
           AND A.AssetTagNum = B.AssetTagNum
           AND A.BuildYRWK = B.BuildYRWK
           AND A.Debug = B.DebugNote
WHERE AsmPlanGroup = 'RACK-ASM'
      AND
      (
          DebugNotes LIKE 'HUMAN ERROR%CABLING%'
          OR DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%'
          OR
          (
              Debugnotes LIKE 'HUMAN ERROR - TLA'
              AND TestErrorSymptom NOT LIKE '%SFS-INFO-VALIDATION-FAIL%'
          )
      )
ORDER BY Plant,
         BuildYRWK,
         AssetTagNum,
         TestStep */


