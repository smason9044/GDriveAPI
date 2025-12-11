SELECT AsmPlatform AS Platform,
       AssetTagNum,
       TestCount,
       A.DebugTechName,
       DebugAction,
       HeaderSymptom,
       TestError
FROM QualityReporting.dbo.FailureDebugTable A
    LEFT JOIN ShopFloorN.dbo.SFOrderView B
        ON A.WorkOrdNum = B.WorkOrdNum
WHERE TestError = 'VALIDATE SFC TRAY PARTS'
      AND BoxDate >= GETDATE() - 7 --and AssetTagNum = 'MAT2517-00733'
ORDER BY DebugStartTime

/*select distinct AsmPlatform,AssetTagNum,DebugStartTime,DENSE_RANK()over (partition by A.AssetTagnum order by DebugStartTime) as TestCount
,C.EMP_LongName as DebugTechName,C.EMP_ShiftDesc as Shift,B.DebugActionCode,HeaderSymptom,TestError
from [ShopfloorN].[dbo].Base_FailureDebug_RawData_UnBoxed A 
left join (select * from QualityReporting.dbo.XU_Debug_D_DebugDetailString 
where Plant = 'FB') B on A.DebugHeaderID = B.DebugHeaderID
left join PRODDIST.dbo.Base_EMPBasic C on A.DebugTechID = C.EMP_EmpID
where  A.DebugHeaderID is not NULL and TestError = 'Validate SFC Tray Parts'
order by DebugStartTime

select B.AsmPlatform,A.AssetTagNum,TestCount,DebugTechName,E.EMP_ShiftDesc,DebugAction,
HeaderSymptom,TestError
from QualityReporting.dbo.FailureDebugTableOpen A
left join [ShopfloorN].[dbo].[SFTranHistoryView_All] B on A.AssetTagNum = B.asset_tag_num and A.TranID = B.TranID and A.Plant = B.plant
--left join ShopFloorN.dbo.SFOrderView C on A.WorkOrdNum = C.WorkOrdNum
--left join TimeClock.dbo.MIMCalendar D on CONVERT(date,A.DebugEndTime) = D.[DATE]
left join PRODDIST.dbo.Base_EMPBasic E on A.DebugTechName = E.EMP_ShortName
where A.AsmPlanGroup = 'TRAY-ASM'
and A.plant = 'FB' and B.TestStep = 'IST' --and C.AsmMachType = 'TLA'
and TestResults = 'FAIL' and DebugAction != '' and EMP_EmpStatusDesc = 'ACTIVE' and EMP_JobTitle like '%DEBUG%'
 and TestError like 'VALIDATE SFC TRAY PARTS' and DebugAction like 'RESCAN-FOR-BAR-CODE%'
 and DebugAction not like '%RESCAN-FOR-BAR-CODE|RETEST-AS-IS%' and DebugAction not like
'%RESCAN-FOR-BAR-CODE|DANCE-DIMMS%' and DebugAction not like
'%RESCAN-FOR-BAR-CODE|PART-SWAP%' and DebugAction not like 'RETEST%'*/


