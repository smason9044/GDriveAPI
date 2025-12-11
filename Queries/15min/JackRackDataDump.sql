SELECT DISTINCT
       CONCAT(AsmFormFactor, AsmPlatform) AS FormFactorPlatform,
       DateOfInduction,
       MIN(YRWK) OVER (partition BY AssetTagNum) AS YRWK,
       AsmLineAssigned,
                    --CONCAT(YEAR(MIN(Createdate)), 'W', FORMAT(DATEPART(ISO_WEEK, MIN(Createdate)), '00')) AS YRWK,
       Shift,
       BasePartNum,
       WorkOrdNum,
       AssetTagNum, AsmPlatform,AsmFormFactor,
       MAX(   CASE
                  WHEN test_step = 'PQA'
                       AND RouteStatus = 'P' THEN
                      Createdate
              END
          ) OVER (partition BY AssetTagNum) AS PQA_tranDate,
       MAX(   CASE
                  WHEN test_step = 'PQA'
                       AND RouteStatus = 'P' THEN
                      EmpID
              END
          ) OVER (partition BY AssetTagNum) AS PQA_EmpID,
       MAX(   CASE
                  WHEN test_step = 'PQA'
                       AND RouteStatus = 'P' THEN
                      EMP_ShiftDesc
              END
          ) OVER (partition BY AssetTagNum) AS PQA_EmpShift,
       MIN(   CASE
                  WHEN RouteMasterDesc = 'CABLE ASSEMBLY' THEN
                      Createdate
              END
          ) OVER (partition BY AssetTagNum) AS Cable_StartTime,
       MAX(   CASE
                  WHEN test_step = 'CABLE ASSEMBLY'
                       AND RouteStatus = 'C' THEN
                      EndTime
              END
          ) OVER (partition BY AssetTagNum) AS Cable_endTime,
       MAX(   CASE
                  WHEN test_step = 'CABLE ASSEMBLY'
                       AND RouteStatus = 'C' THEN
                      updated_StationID
              END
          ) OVER (partition BY AssetTagNum) AS Cable_teststationname,
       MAX(   CASE
                  WHEN test_step = 'CABLE ASSEMBLY'
                       AND RouteStatus = 'C' THEN
                      EmpID
              END
          ) OVER (partition BY AssetTagNum) AS Cable_EmpID,
       MAX(   CASE
                  WHEN test_step = 'CABLE ASSEMBLY'
                       AND RouteStatus = 'C' THEN
                      EMP_ShiftDesc
              END
          ) OVER (partition BY AssetTagNum) AS Cable_EmpShift,
       MAX(   CASE
                  WHEN Count1 = 1 THEN
                      updated_StationID
              END
          ) OVER (partition BY AssetTagNum) AS teststationname,
       MAX(   CASE
                  WHEN Count1 = 1 THEN
                      RouteMasterDesc
              END
          ) OVER (partition BY AssetTagNum) AS latest_test_step,
       MAX(   CASE
                  WHEN Count1 = 1 THEN
                      RouteStatus
              END
          ) OVER (partition BY AssetTagNum) AS RouteStatus,
       MAX(   CASE
                  WHEN Count1 = 1 THEN
                      Createdate
              END
          ) OVER (partition BY AssetTagNum) AS lateststep_tranDate,
       MAX(   CASE
                  WHEN Count1 = 1 THEN
                      EmpID
              END
          ) OVER (partition BY AssetTagNum) AS lateststep_EmpID,
       MAX(   CASE
                  WHEN Count1 = 1 THEN
                      EMP_ShiftDesc
              END
          ) OVER (partition BY AssetTagNum) AS lateststep_EmpShift,
       MAX(   CASE
                  WHEN test_step = 'FQA'
                       AND RouteStatus = 'P' THEN
                      StartTime
              END
          ) OVER (partition BY AssetTagNum) AS FQA_StartTime,
       MAX(   CASE
                  WHEN test_step = 'FQA'
                       AND RouteStatus = 'P' THEN
                      EmpID
              END
          ) OVER (partition BY AssetTagNum) AS FQA_EmpID,
       MAX(   CASE
                  WHEN test_step = 'FQA'
                       AND RouteStatus = 'P' THEN
                      EMP_ShiftDesc
              END
          ) OVER (partition BY AssetTagNum) AS FQA_EmpShift,
       MAX(   CASE
                  WHEN RouteMasterDesc LIKE 'PRINT & APPLY ALL CBL LABEL-WO' THEN
                      StartTime
              END
          ) OVER (partition BY AssetTagNum) AS PRINT_and_APPLY_ALL_CBL_LABEL_WO,
       MAX(   CASE
                  WHEN RouteMasterDesc LIKE 'PRINT & APPLY ALL CBL LABEL-WO' THEN
                      EmpID
              END
          ) OVER (partition BY AssetTagNum) AS PRINT_and_APPLY_ALL_CBL_LABEL_WO_EMPID,
       MAX(   CASE
                  WHEN RouteMasterDesc LIKE 'PRINT & APPLY ALL CBL LABEL-WO' THEN
                      EMP_ShiftDesc
              END
          ) OVER (partition BY AssetTagNum) AS PRINT_and_APPLY_ALL_CBL_LABEL_WO_ShiftDesc
FROM
(
    SELECT *,
           ROW_NUMBER() OVER (partition BY test_step,
                                           RouteMasterDesc,
                                           AssetTagNum
                              ORDER BY Createdate DESC
                             ) AS Count,
           ROW_NUMBER() OVER (Partition BY AssetTagNum ORDER BY Createdate DESC) AS Count1
    FROM ShopFloorN.[dbo].[SF_RackTestStepDetail]
) a
WHERE test_step != 'PBT'
      AND CONVERT(DATE, DateOfInduction) >= DATEADD(week, DATEDIFF(week, 0, GETDATE()), -21)