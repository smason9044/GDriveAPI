SELECT Plant,
       AsmLine,
       YearWeek,
       Hour,
       Shift,
       QTY,
       IM_PlanGroup,
       IM_FormFactor,
       IM_MachType,
       Day,
       BasePartNum,
       WeekGroup,
       WorkOrdNum,
       FORMAT(CreateDate, 'yyyy-MM-dd') AS CreateDate
FROM QualityReporting.dbo.QtyBuiltwithWO
ORDER BY WeekGroup DESC,
         AsmLine,
         CreateDate