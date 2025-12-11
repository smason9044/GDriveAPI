SELECT Plant,
       BasePartNum,
       PlatformUpdated,
       AssetTagNum,
       BoxYRWK,
       TestCount,
       HeaderSymptom,
       DebugActionUpdated,
       PartLoc,
       AsmLine,
       VanLine,
       TestTechName,
       PQAYRWKDY,
       DebugTechName,
       TestResults,
       DebugActionPartLoc,
       DebugActionPartNum,
       DebugFixedFlag,
       BuildYRWK,
       PQAShift,
       PQA_Date
FROM QualityReporting.dbo.HumanError_Trays
/*
UNION ALL
SELECT DISTINCT
       Plant,
       BasePartNum,
       PlatformUpdated,
       AssetTagNum,
       BoxYRWK,
       TestCount,
       HeaderSymptom,
       DebugActionUpdated,
       PartLoc,
       AsmLine,
       VanLine,
       TestTechName,
       PQAYRWKDY,
       DebugTechName,
       TestResults,
       DebugActionPartLoc,
       DebugActionPartNum,
       DebugFixedFlag,
       BuildYRWK,
       PQAShift,
       PQA_Date
FROM NFShopFloorN.dbo.HumanError_TraysNF */
ORDER BY Plant,
         BoxYRWK,
         AssetTagNum,
         TestCount


