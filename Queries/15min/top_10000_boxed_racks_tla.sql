SELECT BoxYRWK,
       AsmPlatform,
       BasePartNum,
       AssetTagNum,
       Induction,
       PQA_Complete,
       Cable_Induction,
       Cable_Assembly_Induction,
       Cable_Assembly_Endtime,
       Cable_Assembly_EmpID,
       Cable_QA_EndTime,
       Cable_QA_EmpID,
       Test_Start,
       Test_Pass,
       FQA,
       BOX,
       BoxStatus,
       Cable_Assembly_Shift,
       Boxed_Shift,
       WorkOrdNum,
       AsmFormFactor,
       UpdatedStationID,
       AsmLine,
       MAX(CBL_Count) AS CBLScans,
       Latest_CBL_StartTime,
       PTS_EmpID,
       PTS_Shift,
       PTS_EMP_Shift,
       PTS_CreateDate,
       PTS_StartTime,
       PTS_EndTime,
       PTS_UpdatedStationID,
       PTS_AsmLine,
       PTS_DeltaTimeInSeconds,
       Plant,
       CBL_RouteID,
       CBL_RouteDesc,
       CBL_YRWK,
       AsmMachType,
       DATEDIFF(second, Cable_Assembly_Induction, Cable_Assembly_Endtime) AS Duration_in_Seconds,
       DATEDIFF(MINUTE, Cable_Assembly_Induction, Cable_Assembly_Endtime) AS Duration_in_Mins,
       PTS_YRWK,
       BoxDate,
       BoxAssetTagNum,
       PTS_RouteDesc,
       Cable_QA_StartTime
FROM
(
    SELECT DISTINCT
           BoxYRWK,
           AsmPlatform,
           BasePartNum,
           AssetTagNum,
           DateOfInduction AS Induction,
           MAX(   CASE
                      WHEN test_step = 'PQA'
                           AND RouteStatus = 'P' THEN
                          EndTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS PQA_Complete,
           MIN(   CASE
                      WHEN RouteMasterDesc LIKE 'Cable%' THEN
                          StartTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS Cable_Induction,
           MIN(   CASE
                      WHEN RouteMasterDesc LIKE 'CABLE ASSEMBLY' THEN
                          StartTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS Cable_Assembly_Induction,
           MAX(   CASE
                      WHEN RouteMasterDesc LIKE 'CABLE ASSEMBLY'
                           AND RouteStatus = 'C' THEN
                          EndTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS Cable_Assembly_Endtime,
           CASE
               WHEN MIN(   CASE
                               WHEN RouteMasterDesc LIKE 'CABLE ASSEMBLY' THEN
                                   StartTime
                           END
                       ) OVER (PARTITION BY AssetTagNum) IS NULL THEN
                   NULL
               ELSE
                   FIRST_VALUE(EmpID) OVER (PARTITION BY AssetTagNum
                                            ORDER BY (CASE
                                                          WHEN RouteMasterDesc LIKE 'CABLE ASSEMBLY' THEN
                                                              StartTime
                                                      END
                                                     ) DESC
                                           )
           END AS Cable_Assembly_EmpID,
           MAX(   CASE
                      WHEN RouteMasterDesc LIKE 'CABLE QA' THEN
                          EndTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS Cable_QA_EndTime,
           MAX(   CASE
                      WHEN RouteMasterDesc LIKE 'CABLE QA'
                           AND RouteStatus = 'P' THEN
                          EmpID
                  END
              ) OVER (PARTITION BY AssetTagNum) AS Cable_QA_EmpID,
           MIN(   CASE
                      WHEN RowNumTest = 1 THEN
                          StartTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS Test_Start,
           MAX(   CASE
                      WHEN RowNumTest = 1
                           AND RouteStatus = 'P' THEN
                          EndTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS Test_Pass,
           MAX(   CASE
                      WHEN test_step = 'FQA'
                           AND RouteStatus = 'P' THEN
                          EndTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS FQA,
           MAX(   CASE
                      WHEN RouteMasterDesc = 'BOX TRAY (TLA)' THEN
                          EndTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS BOX,
           BoxStatus,
           MAX(   CASE
                      WHEN RouteMasterDesc LIKE 'CABLE ASSEMBLY'
                           AND RouteStatus = 'C' THEN
                          EMP_ShiftDesc
                  END
              ) OVER (PARTITION BY AssetTagNum) AS Cable_Assembly_Shift,
           (CASE
                WHEN YEAR(MAX(   CASE
                                     WHEN RouteMasterDesc = 'BOX TRAY (TLA)' THEN
                                         EndTime
                                 END
                             ) OVER (PARTITION BY AssetTagNum)
                         ) >= 2025 THEN
                    CASE
                        WHEN MAX(   CASE
                                        WHEN RouteMasterDesc = 'BOX TRAY (TLA)' THEN
                                            EndTime
                                    END
                                ) OVER (PARTITION BY AssetTagNum) IS NULL THEN
                            NULL
                        WHEN DATENAME(weekday,
                                      MAX(   CASE
                                                 WHEN RouteMasterDesc = 'BOX TRAY (TLA)' THEN
                                                     EndTime
                                             END
                                         ) OVER (PARTITION BY AssetTagNum)
                                     ) IN ( 'Friday', 'Saturday', 'Sunday' ) THEN
                            'SHIFT 1 WE'
                        WHEN DATEPART(hour,
                                      MAX(   CASE
                                                 WHEN RouteMasterDesc = 'BOX TRAY (TLA)' THEN
                                                     EndTime
                                             END
                                         ) OVER (PARTITION BY AssetTagNum)
                                     )
                             BETWEEN 4 AND 17 THEN
                            'SHIFT 1'
                        ELSE
                            'SHIFT 2'
                    END
                ELSE
           (CASE
                WHEN MAX(   CASE
                                WHEN RouteMasterDesc = 'BOX TRAY (TLA)' THEN
                                    EndTime
                            END
                        ) OVER (PARTITION BY AssetTagNum) IS NULL THEN
                    NULL
                WHEN DATENAME(weekday,
                              MAX(   CASE
                                         WHEN RouteMasterDesc = 'BOX TRAY (TLA)' THEN
                                             EndTime
                                     END
                                 ) OVER (PARTITION BY AssetTagNum)
                             ) IN ( 'Friday', 'Saturday', 'Sunday' )
                     AND DATEPART(hour,
                                  MAX(   CASE
                                             WHEN RouteMasterDesc = 'BOX TRAY (TLA)' THEN
                                                 EndTime
                                         END
                                     ) OVER (PARTITION BY AssetTagNum)
                                 ) >= 4 THEN
                    'SHIFT 1 WE'
                WHEN DATEPART(hour,
                              MAX(   CASE
                                         WHEN RouteMasterDesc = 'BOX TRAY (TLA)' THEN
                                             EndTime
                                     END
                                 ) OVER (PARTITION BY AssetTagNum)
                             )
                     BETWEEN 4 AND 16 THEN
                    'SHIFT 1'
                ELSE
                    'SHIFT 2'
            END
           )
            END
           ) AS Boxed_Shift,
           WorkOrdNum,
           AsmFormFactor,
           MAX(   CASE
                      WHEN test_step = 'CABLE ASSEMBLY'
                           AND RouteStatus = 'C' THEN
                          updated_StationID
                      ELSE
                          NULL
                  END
              ) OVER (PARTITION BY AssetTagNum) AS UpdatedStationID,
           SUBSTRING(MAX(   CASE
                                WHEN test_step = 'CABLE ASSEMBLY'
                                     AND RouteStatus = 'C' THEN
                                    updated_StationID
                                ELSE
                                    NULL
                            END
                        ) OVER (PARTITION BY AssetTagNum),
                     7,
                     3
                    ) AS AsmLine,
           CASE
               WHEN RouteMasterID = 1748 THEN
                   DENSE_RANK() OVER (PARTITION BY AssetTagNum, RouteMasterID ORDER BY Createdate ASC)
                   + DENSE_RANK() OVER (PARTITION BY AssetTagNum, RouteMasterID ORDER BY Createdate DESC) - 1
               ELSE
                   ''
           END AS CBL_Count,
           MAX(   CASE
                      WHEN RouteMasterDesc LIKE 'CABLE ASSEMBLY' THEN
                          StartTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS Latest_CBL_StartTime,
           CASE
               WHEN MIN(   CASE
                               WHEN RouteMasterDesc LIKE 'PREP TO SHIP' THEN
                                   StartTime
                           END
                       ) OVER (PARTITION BY AssetTagNum) IS NULL THEN
                   NULL
               ELSE
                   FIRST_VALUE(EmpID) OVER (PARTITION BY AssetTagNum
                                            ORDER BY (CASE
                                                          WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                                                              [EmpID]
                                                      END
                                                     ) DESC
                                           )
           END AS PTS_EmpID,
           (CASE
                WHEN YEAR(MAX(   CASE
                                     WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                                         EndTime
                                 END
                             ) OVER (PARTITION BY AssetTagNum)
                         ) >= 2025 THEN
                    CASE
                        WHEN MAX(   CASE
                                        WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                                            EndTime
                                    END
                                ) OVER (PARTITION BY AssetTagNum) IS NULL THEN
                            NULL
                        WHEN DATENAME(weekday,
                                      MAX(   CASE
                                                 WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                                                     EndTime
                                             END
                                         ) OVER (PARTITION BY AssetTagNum)
                                     ) IN ( 'Friday', 'Saturday', 'Sunday' ) THEN
                            'SHIFT 1 WE'
                        WHEN DATEPART(hour,
                                      MAX(   CASE
                                                 WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                                                     EndTime
                                             END
                                         ) OVER (PARTITION BY AssetTagNum)
                                     )
                             BETWEEN 4 AND 17 THEN
                            'SHIFT 1'
                        ELSE
                            'SHIFT 2'
                    END
                ELSE
           (CASE
                WHEN MAX(   CASE
                                WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                                    EndTime
                            END
                        ) OVER (PARTITION BY AssetTagNum) IS NULL THEN
                    NULL
                WHEN DATENAME(weekday,
                              MAX(   CASE
                                         WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                                             EndTime
                                     END
                                 ) OVER (PARTITION BY AssetTagNum)
                             ) IN ( 'Friday', 'Saturday', 'Sunday' )
                     AND DATEPART(hour,
                                  MAX(   CASE
                                             WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                                                 EndTime
                                         END
                                     ) OVER (PARTITION BY AssetTagNum)
                                 ) >= 4 THEN
                    'SHIFT 1 WE'
                WHEN DATEPART(hour,
                              MAX(   CASE
                                         WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                                             EndTime
                                     END
                                 ) OVER (PARTITION BY AssetTagNum)
                             )
                     BETWEEN 4 AND 16 THEN
                    'SHIFT 1'
                ELSE
                    'SHIFT 2'
            END
           )
            END
           ) AS PTS_Shift,
           MAX(   CASE
                      WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                          [EMP_ShiftDesc]
                  END
              ) OVER (PARTITION BY AssetTagNum) AS PTS_EMP_Shift,
           MAX(   CASE
                      WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                          CreateDate
                  END
              ) OVER (PARTITION BY AssetTagNum) AS PTS_CreateDate,
           MIN(   CASE
                      WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                          StartTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS PTS_StartTime,
           MAX(   CASE
                      WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                          EndTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS PTS_Endtime,
           MAX(   CASE
                      WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                          updated_StationID
                      ELSE
                          NULL
                  END
              ) OVER (PARTITION BY AssetTagNum) AS PTS_UpdatedStationID,
           SUBSTRING(MAX(   CASE
                                WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                                    updated_StationID
                                ELSE
                                    NULL
                            END
                        ) OVER (PARTITION BY AssetTagNum),
                     7,
                     3
                    ) AS PTS_AsmLine,
           DATEDIFF(
                       SECOND,
                       MIN(   CASE
                                  WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                                      StartTime
                              END
                          ) OVER (PARTITION BY AssetTagNum),
                       MAX(   CASE
                                  WHEN RouteMasterDesc = 'PREP TO SHIP' THEN
                                      EndTime
                              END
                          ) OVER (PARTITION BY AssetTagNum)
                   ) AS PTS_DeltaTimeInSeconds,
           Plant,
           '1748' AS CBL_RouteID,
           'CABLE ASSEMBLY' AS CBL_RouteDesc,
           MAX(   CASE
                      WHEN RouteMasterDesc LIKE 'CABLE ASSEMBLY'
                           AND RouteStatus = 'C' THEN
                          YRWK
                  END
              ) OVER (PARTITION BY AssetTagNum) AS CBL_YRWK,
           AsmMachType,
           MAX(   CASE
                      WHEN RouteMasterDesc LIKE 'PREP TO SHIP' THEN
                          YRWK
                  END
              ) OVER (PARTITION BY AssetTagNum) AS PTS_YRWK,
           MAX(   CASE
                      WHEN RouteMasterDesc LIKE 'BOX TRAY (TLA)' THEN
                          FORMAT(BoxDate, 'yyyy-MM-dd')
                  END
              ) OVER (PARTITION BY AssetTagNum) AS BoxDate,
           BoxAssetTagNum,
           MAX(   CASE
                      WHEN RouteMasterID = 1957 THEN
                          RouteMasterDesc
                  END
              ) OVER (PARTITION BY AssetTagNum) AS PTS_RouteDesc,
           MIN(   CASE
                      WHEN RouteMasterDesc LIKE 'CABLE QA' THEN
                          StartTime
                  END
              ) OVER (PARTITION BY AssetTagNum) AS Cable_QA_StartTime,
           CASE
               WHEN BoxDate IS NULL THEN
                   0
               ELSE
                   DENSE_RANK() OVER (ORDER BY BoxDate DESC, BoxAssetTagNum)
           END AS Top10kRowNum
    FROM ShopFloorN.dbo.SF_RackTestStepDetail
) T1
WHERE (
          Top10kRowNum = 0
          OR Top10kRowNum <= 10000
      )
GROUP BY BoxYRWK,
         AsmPlatform,
         BasePartNum,
         AssetTagNum,
         Induction,
         PQA_Complete,
         Cable_Induction,
         Cable_Assembly_Induction,
         Cable_Assembly_Endtime,
         Cable_Assembly_EmpID,
         Cable_QA_EndTime,
         Cable_QA_EmpID,
         Test_Start,
         Test_Pass,
         FQA,
         BOX,
         BoxStatus,
         Cable_Assembly_Shift,
         Boxed_Shift,
         WorkOrdNum,
         AsmFormFactor,
         UpdatedStationID,
         AsmLine,
         PTS_Shift,
         PTS_Starttime,
         PTS_createdate,
         PTS_Endtime,
         PTS_EMP_Shift,
         PTS_UpdatedStationID,
         PTS_AsmLine,
         PTS_EmpID,
         Latest_CBL_Starttime,
         PTS_DeltaTimeInSeconds,
         Plant,
         CBL_RouteID,
         CBL_RouteDesc,
         CBL_YRWK,
         AsmMachType,
         PTS_YRWK,
         BoxDate,
         BoxAssetTagNum,
         PTS_RouteDesc,
         Cable_QA_StartTime
ORDER BY BoxYRWK DESC,
         Induction DESC,
         AssetTagNum