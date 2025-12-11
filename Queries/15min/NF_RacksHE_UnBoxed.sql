SELECT CreateDate,
       AssetTagNum,
       TestStep,
       TestErrorSymptom,
       DebugNotes,
       ROW_NUMBER() OVER (PARTITION BY AssetTagNum, TestStep ORDER BY CreateDate) as RowNum
FROM NFShopFloorN.dbo.Base_FailureDebug_RawData_UnBoxed
WHERE AsmPlanGroup = 'RACK-ASM'
      AND DebugNotes LIKE 'HUMAN ERROR - TEST SET UP%'