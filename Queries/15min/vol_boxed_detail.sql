SELECT APP,
       AsmLine,
       YearWeek,
       Hour,
       Shift,
       SUM(Qty) AS Quantity,
       IM_Plangroup,
       IM_FormFactor,
       IM_Platform,
       IM_MachType,
       Day,
       PartNum,
       WeekGroup
FROM
(
    SELECT APP,
           YearWeek,
           Qty,
           PartNum,
           WeekGroup,
           New_date,
           DATENAME(weekday, New_date) AS Day,
           IM_PlanGroup,
           IM_FormFactor,
           IM_Platform,
           IM_MachType,
           CASE
               WHEN DATENAME(weekday, New_date) IN ( 'Friday', 'Saturday', 'Sunday' ) THEN
                   'SHIFT 1 WE'
               WHEN DATEPART(hour, New_date) >= 4
                    AND DATEPART(hour, New_date) < 16 THEN
                   'SHIFT 1'
               ELSE
                   'SHIFT 2'
           END AS Shift,
           AsmLine,
           DATEPART(hour, New_date) AS Hour
    FROM
    (
        SELECT APP,
               YearWeek,
               Qty,
               PartNum,
               WeekGroup,
               DATE,
               IM_PlanGroup,
               IM_FormFactor,
               IM_Platform,
               IM_MachType,
               AsmLine,
               CASE
                   WHEN DATENAME(weekday, DATE) IN ( 'Tuesday', 'Wednesday', 'Thursday', 'Friday' ) THEN
                       IIF(cast(DATE AS TIME) BETWEEN '00:00:00' AND '04:00:00', DATE - 1, DATE)
                   ELSE
                       [Date]
               END AS New_date
        FROM ProdDist.dbo.VolumeDataDetail_Report
        WHERE sitecode = 'FB'
              AND IM_FormFactor <> N''
              AND WeekGroup <= 14
    ) t1
) t2
GROUP BY APP,
         AsmLine,
         YearWeek,
         Hour,
         Shift,
         IM_Plangroup,
         IM_FormFactor,
         IM_Platform,
         IM_MachType,
         Day,
         PartNum,
         WeekGroup
ORDER BY APP,
         YearWeek,
         PartNum,
         Shift