SELECT DISTINCT 
	   A.Plant,
       A.AsmPlanGroup,
       FormFactor,
       Platform,
       G_FullCommCode,
       AsmBasePartNum,
       A.AssetTagNum,
       TestStep,
       TestTechName,
       TestCount,
       TestResults,
       TestError,
       TestErrorSymptom,
       SugDebugAction,
       SugDebugTurn,
       SugDebugLevel,
       DebugTechName,
       DebugAction,
       DebugActionPartLoc,
       DebugActionPartNum,
       DebugActionSerialNum,
       DebugFixedFlag,
       DebugNotes,
       updated_StationID AS StationID,
       FORMAT(GETDATE(),'MM/dd/yyyy') AS 'Export Date',
       FORMAT(GETDATE(), 'hh:mm:ss tt') AS 'Export Time'
FROM QualityReporting.dbo.FailureDebugTableOpen A
    INNER JOIN MIMDISTN.dbo.part_info B
        ON A.AsmBasePartNum = B.MIMPartNum
    LEFT OUTER JOIN QualityReporting.dbo.FailureDataDebugNotes C
        ON A.DebugHeaderID = C.DebugHeaderID
    LEFT JOIN ShopFloorN.dbo.SF_RackTestStepDetail D
        ON A.AssetTagNum = D.AssetTagNum
           AND A.TranID = D.TranID
WHERE A.Plant = 'FB'
      --AND A.AsmPlanGroup = 'RACK-ASM'
ORDER BY FormFactor,
         Platform,
         AssetTagNum,
         TestStep,
         TestCount



