WITH CTE1
AS (SELECT CreateDate,
           TranID,
           YRWK,
           WorkOrdNum,
           AsmPlatform,
           AssetTagNum,
           test_step,
           EmpID,
           EMP_LongName,
           EMP_ShiftDesc,
           RouteMasterDesc,
           COUNT(AssetTagNum) OVER (PARTITION BY YRWK, EmpID) AS CountOfRacks
    FROM
    (
        SELECT CreateDate,
               TranID,
               YRWK,
               WorkOrdNum,
               AsmPlatform,
               AssetTagNum,
               test_step,
               EmpID,
               B.EMP_LongName,
               A.EMP_ShiftDesc,
               A.RouteMasterDesc,
               ROW_NUMBER() OVER (PARTITION BY AssetTagNum, RouteMasterDesc ORDER BY CreateDate) AS RowCountRDesc
        FROM ShopFloorN.dbo.SF_RackTestStepDetail A
            JOIN PRODDIST.dbo.Base_EMPBasic B
                ON A.EmpID = B.EMP_EmpID
        WHERE RouteMasterDesc LIKE 'POPULATE%'
              AND Plant = 'FB'
    ) t1
    WHERE RowCountRDesc = 1)
SELECT A.BoxDate,
       C.YRWK,
       C.WorkOrdNum,
       C.AsmPlatform,
       A.AssetTagNum,
       A.TestStep,
       C.EMP_LongName,
       C.EMP_ShiftDesc,
       C.EmpID,
       C.RouteMasterDesc,
       B.FirstFailureSymptom,
       CountOfRacks
FROM QualityReporting.dbo.FailureDebugTable A
    JOIN ShopFloorN.dbo.SFFailureDetailView B
        ON A.FailureDetailID = B.FailureDetailID
    LEFT JOIN CTE1 C
        ON A.AssetTagNum = C.AssetTagNum
WHERE A.Plant = 'FB'
      AND A.BoxDate >= DATEADD(week, DATEDIFF(week, 0, GETDATE()), -182)
      AND FirstFailureSymptom LIKE '%SFS-INFO-VALIDATION-FAIL%'