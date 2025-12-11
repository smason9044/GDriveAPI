SELECT YRWK,
       Day,
       Shift,
       AsmMachType,
       AsmPlatform,
       AsmLineAssigned,
       BasePartNum,
       COUNT(asset_tag_num) AS CountOfInduction,
       AsmPlanGroup,
       AsmFormFactor,
       WeekGroup,
       WorkOrdNum
FROM
(
    SELECT *,
           DATENAME(weekday, CONVERT(DATE, [Date])) AS day
    FROM
    (
        SELECT *,
               CASE
                   WHEN Shift = 'SHIFT 2'
                        AND DATEPART(hh, DateOfInduction)
                        BETWEEN 0 AND 4 THEN
                       CONVERT(DATE, DateOfInduction - 1)
                   ELSE
                       CONVERT(DATE, DateOfInduction)
               END AS DATE
        FROM
        (
            SELECT DISTINCT
                   A.DateOfInduction,
                   A.asset_tag_num,
                   WorkOrdNum,
                   basePartNum,
                   AsmPlatform,
                   AsmMachType,
                   AsmLineAssigned,
                   AsmPlanGroup,
                   AsmFormFactor,
                   CONCAT(
                             DATEPART(Year, CONVERT(DATE, DateOfInduction)),
                             'W',
                             RIGHT('0' + CAST(DATEPART(ISO_WEEK, CONVERT(DATE, DateOfInduction)) AS VARCHAR), 2)
                         ) AS YRWK,
                   CASE
                       WHEN DATENAME(weekday, CONVERT(DATE, DateOfInduction)) IN ( 'Friday', 'Saturday', 'Sunday' ) THEN
                           'SHIFT WE'
                       WHEN DATEPART(hour, DateOfInduction) >= 4
                            AND DATEPART(hour, DateOfInduction) < 16 THEN
                           'SHIFT 1'
                       ELSE
                           'SHIFT 2'
                   END AS Shift,
                   CASE
                       WHEN DATEPART(dw, GETDATE()) = 1 THEN
                           CASE
                               WHEN DATEPART(dw, DateOfInduction) = 1 THEN
                                   DATEDIFF(ww, GETDATE() - 1, DateOfInduction - 1)
                               ELSE
                                   DATEDIFF(ww, GETDATE() - 1, DateOfInduction)
                           END
                       ELSE
                           CASE
                               WHEN DATEPART(dw, DateOfInduction) = 1 THEN
                                   DATEDIFF(ww, GETDATE(), DateOfInduction - 1)
                               ELSE
                                   DATEDIFF(ww, GETDATE(), DateOfInduction)
                           END
                   END AS WeekGroup
            FROM [ShopFloorN].[dbo].SFTranHistoryView_All A
            WHERE A.plant = 'FB'
                  AND CONVERT(DATE, DateOfInduction) >= DATEADD(WEEK, -5, GETDATE()) --and AsmPlanGroup = 'RACK-ASM'
                                                                                     --and MIMPartNum = '1169457'
        ) a
    ) b
) c
GROUP BY AsmPlatform,
         AsmMachType,
         AsmLineAssigned,
         Shift,
         YRWK,
         BasePartNum,
         [DAY],
         AsmPlanGroup,
         AsmFormFactor,
         WeekGroup,
         WorkOrdNum
ORDER BY YRWK,
         Shift,
         AsmMachType