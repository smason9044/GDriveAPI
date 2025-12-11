SELECT CreateDate,
       BoxName,
       StationID,
       OperID,
       OverBoxId,
       BoxStatus,
       BoxQty,
       GooPartNum,
       MrbFlag,
       Disposition,
       FromBin,
       ToWarehouse,
       ToBin,
       Who,
       BinQty,
       CloseDate,
       B.PlanGroup AS IM_PlanGroup,
       CASE
           WHEN RIGHT(PRODDIST.dbo.udf_YearWeek(A.CreateDate), 2)
                BETWEEN 1 AND 13 THEN
               'QUARTER 1'
           WHEN RIGHT(PRODDIST.dbo.udf_YearWeek(A.CreateDate), 2)
                BETWEEN 14 AND 26 THEN
               'QUARTER 2'
           WHEN RIGHT(PRODDIST.dbo.udf_YearWeek(A.CreateDate), 2)
                BETWEEN 27 AND 39 THEN
               'QUARTER 3'
           ELSE
               'QUARTER 4'
       END AS Quarter
FROM WreckingBall.dbo.WBBoxTable A
    LEFT JOIN MIMDISTN.dbo.part_info B
        ON A.GooPartNum = B.MIMPartNum
WHERE Plant = 'FB'
      AND
      (
          (
              A.CreateDate >= GETDATE() - 365
              AND PlanGroup IN ( 'TRAY-ASM', 'RACK-ASM' )
          )
          OR
          (
              OperID = 1044
              AND
              (
                  (
                      BoxStatus IN ( 'C', 'M', 'O' )
                      AND OverBoxId IS NULL
                  )
                  OR
                  (
                      OverBoxId = 1
                      AND CAST(CloseDate AS DATE) >= CAST(DATEADD(DAY, -90, GETDATE()) AS DATE)
                  )
              )
          )
          OR (MIMPartNum = '1157872-R')
      )