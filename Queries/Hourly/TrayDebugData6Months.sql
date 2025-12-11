SELECT B.AsmPlatform AS Platform,
       A.AssetTagNum,
       TestCount,
       BoxYRWK,
       DebugTechName,
       DebugActionDesc as DebugAction,
       A.CreateDate AS TrayScanOut,
       B.DebugEndTime,
       CONCAT(YEAR(B.DebugEndTime), 'W', RIGHT('0' + CAST(DATEPART(ISO_WEEK, B.DebugEndTime) AS NVARCHAR(2)), 2)) AS DebugYRWK,
       DATENAME(WEEKDAY, DebugEndTime) AS Day,
       C.EMP_ShiftDesc AS DebugShift,
       HeaderSymptom,
       TestError,
       C.EMP_JobTitle AS JobTitle,
	   C.EMP_ProdGroup,
	   BoxDate,
	   B.Tester,
	   TestStationID,
	   TestErrorSymptom,
	   DefectPartLoc,
	   DefectPartNum,
	   DefecSerialNum,
	   DebugFixedFlag,
	   DebugNotes
FROM [ShopfloorN].[dbo].[SFTranHistoryView] A
    JOIN ShopFloorN.dbo.Base_FailureDebug_RawData B
        ON A.asset_tag_num = B.AssetTagNum
           AND A.TranID = B.TranID
           AND A.Plant = B.plant
    LEFT JOIN PRODDIST.dbo.Base_EMPBasic C
        ON B.Debugger = C.EMP_EmpID
WHERE B.AsmPlanGroup = 'TRAY-ASM'
      AND CONVERT(DATE, BoxDate) >= DATEADD(week, DATEDIFF(week, 0, GETDATE()), -180)
      AND A.plant = 'FB'
ORDER BY BoxYRWK DESC,
         AssetTagNum,
         TestCount