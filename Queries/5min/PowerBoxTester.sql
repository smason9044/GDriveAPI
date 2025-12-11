SELECT TOP 500
       DATE,
       EmpID,
       RackAsset_Tag,
       PowerBoxCMMS_Tag,
       Result,
       Notes,
       Chassis_G,
       L1_L2,
       L1_L3,
       L1_N,
       L1_G,
       L2_L3,
       L2_N,
       L2_G,
       L3_N,
       L3_G,
       N_G,
       TesterName
FROM PBxTester.dbo.[PowerBoxTester]
ORDER BY TRY_CONVERT(DATETIME, DATE) DESC