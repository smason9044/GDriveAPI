SELECT 'FB' AS Plant,
       AsmPlatform,
       A.AssetTagNum,
       HeaderSymptom,
       B.DebugActionCode,
       B.DefectPartLoc,
       AsmLineAssigned as AsmLine,
       TestTechID,
       C.EMP_LongName AS TestTechName
FROM [ShopfloorN].[dbo].Base_FailureDebug_RawData_UnBoxed A
    JOIN
    (
        SELECT *
        FROM [QualityReporting].[dbo].[XU_Debug_D_DebugDetail]
        WHERE Plant = 'FB'
              AND DebugActionCode IN ( 'ASSEMBLY-OPERATOR-ERROR', 'TEST-OPERATOR-ERROR' )
    ) B
        ON A.DebugDetailID = B.DebugDetailID
    LEFT JOIN PRODDIST.dbo.Base_EMPBasic C
        ON A.TestTechID = C.EMP_EmpID
WHERE A.DebugHeaderID IS NOT NULL
/*
UNION ALL
SELECT DISTINCT 'NF' AS Plant,
       AsmPlatform,
       A.AssetTagNum,
       HeaderSymptom,
       B.DebugActionCode,
       B.DefectPartLoc,
       AsmLineAssigned as AsmLine,
       TestTechID,
       C.EMP_LongName AS TestTechName
FROM [NFShopfloorN].[dbo].Base_FailureDebug_RawData_UnBoxed A
    JOIN
    (
        SELECT *
        FROM [NFShopFloorN].[dbo].[XU_Debug_D_DebugDetail]
        WHERE DebugActionCode IN ( 'ASSEMBLY-OPERATOR-ERROR', 'TEST-OPERATOR-ERROR' )
    ) B
        ON A.DebugDetailID = B.DebugDetailID
    LEFT JOIN PRODDIST.dbo.Base_EMPBasic C
        ON A.TestTechID = C.EMP_EmpID
WHERE A.DebugHeaderID IS NOT NULL*/