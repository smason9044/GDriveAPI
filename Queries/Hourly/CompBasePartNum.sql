SELECT BuiltYRWK,
       part_number AS CompBasePartNum,
       Description,
       IM_CommCodePrimDesc AS PrimeCode,
       AsmPlatform AS Platform,
       COUNT(serial_num) AS CountofParts,
       --cast(right(BuiltYRWK,2) as int) - cast(right(format(datepart(iso_week,GETDATE()),'00'),2) as int) as Weekgroup
       Weekgroup
FROM
(
    SELECT A.asset_tag_num,
           CONCAT(
                     YEAR(DATEADD(DAY, 3 - ((DATEPART(WEEKDAY, Induction) + 5) % 7), Induction)),
                     'W',
                     FORMAT(DATEPART(ISO_WEEK, Induction), '00')
                 ) AS BuiltYRWK,
           A.part_number,
           A.serial_num,
           D.PartDesc AS description,
           IM_CommCodePrimDesc,
           C.AsmPlatform,
           CASE
               WHEN DATEPART(dw, GETDATE()) = 1 THEN
                   CASE
                       WHEN DATEPART(dw, Induction) = 1 THEN
                           DATEDIFF(ww, GETDATE() - 1, Induction - 1)
                       ELSE
                           DATEDIFF(ww, GETDATE() - 1, Induction)
                   END
               ELSE
                   CASE
                       WHEN DATEPART(dw, Induction) = 1 THEN
                           DATEDIFF(ww, GETDATE(), Induction - 1)
                       ELSE
                           DATEDIFF(ww, GETDATE(), B.Induction)
                   END
           END AS Weekgroup
    FROM ShopFloorN.dbo.serial_master A
        LEFT JOIN
        (
            SELECT CreateDate AS Induction,
                   Plant,
                   AssetTagNum,
                   WorkOrdNum,
                   A.RouteMasterID,
                   B.RouteMasterDesc,
                   EmpID
            FROM [ShopFloorN].[dbo].[SFAssetTagRouteStatusView] A
                LEFT JOIN ShopFloorN.dbo.RouteMasterView B
                    ON A.RouteMasterID = B.RouteMasterID
            WHERE Plant = 'FB'
                  AND B.RouteMasterDesc LIKE 'APPLY%TAG%'
        ) B
            ON A.asset_tag_num = B.AssetTagNum
        JOIN ShopFloorN.dbo.SFOrderView C
            ON B.WorkOrdNum = C.WorkOrdNum --and A.plant = B.Plant
        JOIN
        (
            SELECT 
                   MIMPartNum,
                   CommCodePrimDesc AS IM_CommCodePrimDesc,
                   PartDesc
            FROM MIMDISTN.dbo.part_info
        ) D
            ON A.part_number = D.MIMPartNum
    WHERE A.[plant] = 'FB'
          AND C.AsmPlanGroup = 'TRAY-ASM'
          AND C.AsmMachType = 'TLA'
          AND Induction >= GETDATE() - 40 --datediff(day,datepart(iso_week,A.CreateDate),datepart(iso_week,GETDATE())) <= 4 and datepart(year,A.CreateDate) = datepart(year,GETDATE()) 
          AND serial_num_status = 'N'
          AND A.asset_tag_num NOT LIKE 'OSV%'
) t1
GROUP BY BuiltYRWK,
         part_number,
         IM_CommCodePrimDesc,
         AsmPlatform,
         [description],
         Weekgroup
ORDER BY BuiltYRWK




/*SELECT BuiltYRWK,part_number,[description],IM_CommCodePrimDesc,IM_CommCodeSecDesc,AsmPlatform,count(serial_num) as CountofParts,
--cast(right(BuiltYRWK,2) as int) - cast(right(format(datepart(iso_week,GETDATE()),'00'),2) as int) as Weekgroup
Weekgroup
FROM (SELECT A.asset_tag_num,CONCAT( YEAR(print_date),'W',RIGHT('0' + CAST(DATEPART(ISO_WEEK, print_date) AS NVARCHAR(2)), 2)) as BuiltYRWK,A.part_number,A.serial_num,
      D.[IM_PartDescription] as description,
      IM_CommCodePrimDesc,IM_CommCodeSecDesc,C.AsmPlatform,
      case when     DATEPART(dw, getdate()) = 1 
          then  
                case when DATEPART(dw,print_date ) = 1
                     then DATEDIFF(ww, getdate()-1,print_date -1)
                     ELSE DATEDIFF(ww,getdate()-1,print_date ) 
                end
          else   case when DATEPART(dw,print_date ) = 1
                     then DATEDIFF(ww, getdate(),print_date - 1)
                     ELSE DATEDIFF(ww,getdate(),print_date) 
                end 
        end as Weekgroup
      FROM ShopFloorN.dbo.serial_master A
      left join ShopFloorN.dbo.asset_tag_gen B on A.asset_tag_num = B.asset_tag_num
      JOIN ShopFloorN.dbo.SFOrderView C on B.work_order_num = C.WorkOrdNum --and A.plant = B.Plant
      JOIN (SELECT *
            FROM [PRODDIST].[dbo].[Base_Part_Ext]) D on A.part_number = D.IM_PartNum
      WHERE A.[plant] = 'FB' AND C.AsmPlanGroup = 'TRAY-ASM' AND C.AsmMachType = 'TLA' AND A.create_date >= GETDATE()-40 --datediff(day,datepart(iso_week,A.CreateDate),datepart(iso_week,GETDATE())) <= 4 and datepart(year,A.CreateDate) = datepart(year,GETDATE()) 
      AND serial_num_status = 'N' and A.asset_tag_num not like 'OSV%') t1
GROUP BY BuiltYRWK,part_number,IM_CommCodePrimDesc,IM_CommCodeSecDesc,AsmPlatform,[description],Weekgroup
  order by BuiltYRWK */


