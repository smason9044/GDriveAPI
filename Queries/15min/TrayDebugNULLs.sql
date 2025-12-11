SELECT A.asset_tag_num AS AssetTagNum,
       A.AsmPlatform AS Platform,
       A.StartTime AS TestStart,
       A.EndTime AS TestEnd,
       A.CreateDate AS TestScanOut,
       a.TestFixture AS POD,
       CASE
           WHEN DATENAME(WEEKDAY, A.CreateDate) IN ( 'Monday', 'Tuesday', 'Wednesday', 'Thursday' )
                AND DATEPART(hour, A.CreateDate) NOT
                BETWEEN 4 AND 16 THEN
               'SHIFT 2'
           WHEN DATENAME(WEEKDAY, A.CreateDate) IN ( 'Monday', 'Tuesday', 'Wednesday', 'Thursday' )
                AND DATEPART(hour, A.CreateDate)
                BETWEEN 4 AND 16 THEN
               'SHIFT 1'
           ELSE
               'SHIFT WE'
       END AS ScanOut_Shift,
       B.TestTechID AS ScanOut_EmpID,
       G.EMP_ShortName AS Name,
       G.EMP_ShiftDesc AS Emp_Shift,
       RouteStatus AS TestResult,
       MIN(B.DebugStartTime) AS DebugStart,
       MAX(B.DebugEndTime) AS DebugEnd
FROM ShopFloorN.dbo.SFTranHistoryView_All A
    LEFT JOIN ShopFloorN.dbo.Base_FailureDebug_RawData_UnBoxed B
        ON A.asset_tag_num = B.AssetTagNum
           AND A.TranID = B.TranID
    JOIN [PRODDIST].dbo.Base_EMPBasic G
        ON B.TestTechID = G.EMP_EmpID
WHERE A.plant = 'FB'
      AND A.AsmPlanGroup = 'TRAY-ASM'
      AND A.CreateDate >= GETDATE() - 30
      AND RouteStatus = 'F'
      AND B.DebugStartTime IS NULL
      AND A.TestStep = 'IST'
      AND A.AsmLineAssigned != 'D11'
GROUP BY A.asset_tag_num,
         A.StartTime,
         A.EndTime,
         A.CreateDate,
         RouteStatus,
         A.AsmPlatform,
         B.TestTechID,
         G.EMP_ShiftDesc,
         G.EMP_ShortName,
         a.TestFixture,
         A.AsmLineAssigned
ORDER BY TestScanOut
