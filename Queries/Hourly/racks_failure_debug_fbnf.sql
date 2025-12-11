SELECT AsmPlanGroup,
       Plant,
       t2.FormFactor AS FormFactor,
       t2.Platform AS Platform,
       t2.G_FullCommCode AS G_FullCommCode,
       AsmBasePartNum,
       AssetTagNum,
       BoxDate,
       BoxYRWK,
       TestStep,
       Tester,
       TestCount,
       TestResults,
       TestError,
       SugDebugAction,
       SugDebugTurn,
       SugDebugLevel,
       DebugTechName,
       DebugActionDesc,
       DefectPartLoc,
       DefecSerialNum,
       DebugFixedFlag,
       TestErrorSymptom,
       DefectPartNum,
       DebugNotes,
       BP_WKGRP,
       COALESCE(t3.UpdatedPlatform, t2.Platform) AS UpdatedPlatform,
       TestStationID
FROM
(
    SELECT A.AsmPlanGroup,
           A.Plant,
           AsmBasePartNum,
           A.AssetTagNum,
           A.BoxDate,
           A.BoxYRWK,
           TestStep,
           Tester,
           TestCount,
           TestResults,
           TestError,
           SugDebugAction,
           SugDebugTurn,
           SugDebugLevel,
           DebugTechName,
           DebugActionDesc,
           DefectPartLoc,
           DefecSerialNum,
           DebugFixedFlag,
           TestErrorSymptom,
           DefectPartNum,
           DebugNotes,
           CASE
               WHEN DATEPART(dw, GETDATE()) = 1 THEN
                   CASE
                       WHEN DATEPART(dw, TRY_CONVERT(DATETIME, A.BoxDate)) = 1 THEN
                           DATEDIFF(ww, GETDATE() - 1, TRY_CONVERT(DATETIME, A.BoxDate) - 1)
                       ELSE
                           DATEDIFF(ww, GETDATE() - 1, TRY_CONVERT(DATETIME, A.BoxDate))
                   END
               ELSE
                   CASE
                       WHEN DATEPART(dw, TRY_CONVERT(DATETIME, A.BoxDate)) = 1 THEN
                           DATEDIFF(ww, GETDATE(), TRY_CONVERT(DATETIME, A.BoxDate) - 1)
                       ELSE
                           DATEDIFF(ww, GETDATE(), TRY_CONVERT(DATETIME, A.BoxDate))
                   END
           END AS BP_WKGRP,
           TestStationID
    FROM ShopFloorN.dbo.Base_FailureDebug_RawData A
    WHERE A.Plant = 'FB'
          AND A.AsmPlanGroup = 'RACK-ASM'
          AND Flag = 1
    UNION ALL
    SELECT A.AsmPlanGroup,
           A.Plant,
           AsmBasePartNum,
           A.AssetTagNum,
           A.BoxDate,
           A.BoxYRWK,
           TestStep,
           Tester,
           TestCount,
           TestResults,
           TestError,
           SugDebugAction,
           SugDebugTurn,
           SugDebugLevel,
           DebugTechName,
           DebugActionDesc,
           DefectPartLoc,
           DefecSerialNum,
           DebugFixedFlag,
           TestErrorSymptom,
           DefectPartNum,
           DebugNotes,
           CASE
               WHEN DATEPART(dw, GETDATE()) = 1 THEN
                   CASE
                       WHEN DATEPART(dw, TRY_CONVERT(DATETIME, A.BoxDate)) = 1 THEN
                           DATEDIFF(ww, GETDATE() - 1, TRY_CONVERT(DATETIME, A.BoxDate) - 1)
                       ELSE
                           DATEDIFF(ww, GETDATE() - 1, TRY_CONVERT(DATETIME, A.BoxDate))
                   END
               ELSE
                   CASE
                       WHEN DATEPART(dw, TRY_CONVERT(DATETIME, A.BoxDate)) = 1 THEN
                           DATEDIFF(ww, GETDATE(), TRY_CONVERT(DATETIME, A.BoxDate) - 1)
                       ELSE
                           DATEDIFF(ww, GETDATE(), TRY_CONVERT(DATETIME, A.BoxDate))
                   END
           END AS BP_WKGRP,
           TestStationID
    FROM NFShopFloorN.dbo.Base_FailureDebug_RawData A
    WHERE A.Plant = 'NF'
          AND A.AsmPlanGroup = 'RACK-ASM'
          AND Flag = 1
) t1
    JOIN MIMDISTN.dbo.part_info t2
        ON t1.AsmBasePartNum = t2.MIMPartNum
    LEFT JOIN ShopFloorN.dbo.CommCodes_RackFBNF t3
        ON t2.G_FullCommCode = t3.CommCode
           AND
           (
               t3.Platform IS NULL
               OR t3.Platform = t2.Platform
           )
           AND
           (
               t3.PartDesc IS NULL
               OR
               (
                   t3.PartDesc LIKE 'NOT %'
                   AND t2.PartDesc NOT LIKE REPLACE(t3.PartDesc, 'NOT ', '')
               )
               OR t2.PartDesc LIKE t3.PartDesc
           )
ORDER BY Plant,
         BoxDate DESC,
         FormFactor,
         Platform,
         AssetTagNum,
         TestStep,
         TestCount