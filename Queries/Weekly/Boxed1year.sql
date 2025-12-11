SELECT DISTINCT
       Quarter,
       PlanGroup,
       part_num,
       SUM(box_qty) AS Quantity,
       MachType
FROM
(
    SELECT DISTINCT
           CASE
               WHEN RIGHT(DATEPART(iso_week, A.create_date), 2)
                    BETWEEN 1 AND 13 THEN
                   'QUARTER 1'
               WHEN RIGHT(DATEPART(iso_week, A.create_date), 2)
                    BETWEEN 14 AND 26 THEN
                   'QUARTER 2'
               WHEN RIGHT(DATEPART(iso_week, A.create_date), 2)
                    BETWEEN 27 AND 39 THEN
                   'QUARTER 3'
               ELSE
                   'QUARTER 4'
           END AS Quarter,
           C.PlanGroup,
           part_num,
           SSCC,
           B.box_qty,
           C.MachType
    FROM ShopfloorN.dbo.box_detail A
        INNER JOIN ShopFloorN.dbo.box B
            ON A.box_id = B.gs_box_id
        INNER JOIN MIMDISTN.dbo.part_info C
            ON B.part_num = C.MIMPartNum
    WHERE A.Plant = 'FB'
          AND CONVERT(DATE, B.create_date) >= GETDATE() - 365
          AND PlanGroup IN ( 'TRAY-ASM', 'RACK-ASM' )
          AND SSCC IS NOT NULL
) t1
GROUP BY Quarter,
         PlanGroup,
         part_num,
         MachType

