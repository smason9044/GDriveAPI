SELECT A.AsmPlatform AS Platform,
       A.AssetTagNum,
       TestCount,
       BoxYRWK,
       DebugTechName,
       DebugAction,
       A.CreateDate AS TrayScanOut,
       DebugEndTime,
       CONCAT(YEAR(B.DebugEndTime), 'W', RIGHT('0' + CAST(DATEPART(ISO_WEEK, B.DebugEndTime) AS NVARCHAR(2)), 2)) AS DebugYRWK,
       DATENAME(WEEKDAY, DebugEndTime) AS Day,
       E.EMP_ShiftDesc AS DebugShift,
       HeaderSymptom,
       TestError,
       E.EMP_JobTitle AS JobTitle
FROM [ShopfloorN].[dbo].[SFTranHistoryView_All] A
    JOIN QualityReporting.dbo.FailureDebugTable B
        ON A.asset_tag_num = B.AssetTagNum
           AND A.TranID = B.TranID
           AND A.Plant = B.plant
    LEFT JOIN PRODDIST.dbo.Base_EMPBasic E
        ON B.DebugTechName = E.EMP_ShortName
WHERE A.AsmPlanGroup = 'TRAY-ASM'
      AND CONVERT(DATE, DebugEndTime) >= DATEADD(week, DATEDIFF(week, 0, GETDATE()), -28)
      AND A.plant = 'FB'
      AND A.TestStep = 'IST'
      AND TestResults = 'FAIL'
      AND DebugAction != ''
      AND EMP_EmpStatusDesc = 'ACTIVE'
      AND EMP_ProdGroup = 'TRAYS'
      AND E.EMP_JobTitle LIKE '%DEBUG%'
ORDER BY BoxYRWK DESC,
         AssetTagNum,
         TestCount

/*
select *,DATENAME(WEEKDAY,Updated_debug_Date) as  Adjusted_Day,
case when DATENAME(WEEKDAY,Updated_debug_Date) in ('Monday','Tuesday','Wednesday','Thursday') and datepart(hour,Updated_debug_Date) between 0 and 4 then 'SHIFT 2'
when DATENAME(WEEKDAY,Updated_debug_Date) in ('Monday','Tuesday','Wednesday','Thursday') and datepart(hour,Updated_debug_Date) between 4 and 17 then 'SHIFT 1'
when DATENAME(WEEKDAY,Updated_debug_Date) in ('Monday','Tuesday','Wednesday','Thursday') and datepart(hour,Updated_debug_Date) >= 17 then 'SHIFT 2' 
else 'SHIFT WE' end as Adjusted_DebugShift
from (select distinct A.AsmPlatform,A.AssetTagNum,TestCount,BoxYRWK,DebugTechName,DebugAction,A.CreateDate as TrayScanOut,DebugEndTime,
CONCAT(YEAR(B.DebugEndTime),'W',RIGHT('0' + CAST(DATEPART(ISO_WEEK, B.DebugEndTime) AS NVARCHAR(2)),2)) as DebugYRWK,
datediff(SECOND,A.CreateDate,DebugEndTime) as DebugTimeinSecs,case when datepart(hour,DebugEndTime) between 0 and 4 then dateadd(day,-1,DebugEndTime) 
else DebugEndTime end as Updated_debug_Date,TestError,HeaderSymptom,E.EMP_ShiftDesc,E.EMP_JobTitle
from [ShopfloorN].[dbo].[SFTranHistoryView_All] A
join QualityReporting.dbo.FailureDebugTable B on A.asset_tag_num = B.AssetTagNum and A.TranID = B.TranID and A.Plant = B.plant
left join PRODDIST.dbo.Base_EMPBasic E on B.DebugTechName = E.EMP_ShortName
where A.AsmPlanGroup = 'TRAY-ASM' and BoxDate >= dateadd(week, datediff(week,0, getdate()), -35) and A.plant = 'FB' and A.TestStep = 'IST' and A.AsmMachType = 'TLA' 
and TestResults = 'FAIL' and DebugAction != '' and EMP_EmpStatusDesc = 'ACTIVE' and EMP_ProdGroup = 'TRAYS' and E.EMP_JobTitle like '%DEBUG%') T1
where Updated_debug_Date >= dateadd(week, datediff(week,0, getdate()), -28)
order by BoxYRWK desc,AssetTagNum,TestCount
*/