SELECT AsmLine,
       YearWeek AS YRWK,
       Hour,
       Shift,
       Quantity AS Qty,
       IM_Plangroup AS PlanGroup,
       IM_FormFactor AS FormFactor,
       IM_Platform AS Platform,
       IM_MachType AS Type,
       Day AS DayName,
       PartNum,
       WeekGroup AS WeekGrp,
	   Disposition
FROM [WreckingBall].[dbo].[WB BoxData]
WHERE WeekGroup
BETWEEN -26 AND 0
ORDER BY YearWeek,
         IM_PlanGroup,
         IM_Platform,
         Day,
         Hour,
		 Disposition