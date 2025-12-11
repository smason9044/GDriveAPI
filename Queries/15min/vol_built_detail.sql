SELECT Plant,
       AsmLine,
       YearWeek,
       WeekGroup,
       BasePartNum,
       IM_PlanGroup,
       IM_FormFactor,
       IM_Platform,
       IM_MachType,
       Day,
       Hour,
       CASE
           WHEN Day IN ( 'Friday', 'Saturday', 'Sunday' ) THEN
               'SHIFT 1 WE'
           WHEN hour >= 4
                AND hour < 16 THEN
               'SHIFT 1'
           ELSE
               'SHIFT 2'
       END AS Shift_Updated,
       Shift,
       QTY,
       DENSE_RANK() OVER (PARTITION BY AsmLine,
                                       YearWeek,
                                       CASE
                                           WHEN Day IN ( 'Friday', 'Saturday', 'Sunday' ) THEN
                                               'SHIFT 1 WE'
                                           WHEN hour >= 4
                                                AND hour < 16 THEN
                                               'SHIFT 1'
                                           ELSE
                                               'SHIFT 2'
                                       END,
                                       IM_PlanGroup,
                                       IM_Platform,
                                       IM_MachType,
                                       Day
                          ORDER BY YearWeek,
                                   Hour,
                                   Day DESC
                         ) AS RowNum
FROM QualityReporting.dbo.VolumeDataDetail_Report_Built
WHERE WeekGroup <= 24
      AND Plant = 'FB'
ORDER BY YearWeek,
         AsmLine,
         Day,
         Hour