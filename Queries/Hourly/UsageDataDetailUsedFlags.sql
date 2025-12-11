	SELECT BuiltYRWK,
			AsmPlatform,
			AsmBasePartNum,
			AssettagNum,
			YRWK,
			CompBasePartNum,
			CompSerialNum,
			WOUsageQty,
			UsedFlag,
			UsedWhere,
			countofstrikes
	FROM
	(
		SELECT CONCAT(
							YEAR(DATEADD(DAY, 3 - ((DATEPART(WEEKDAY, Induction) + 5) % 7), Induction)),
							'W',
							FORMAT(DATEPART(ISO_WEEK, Induction), '00')
						) AS BuiltYRWK,
				AsmPlatform,
				AsmBasePartNum,
				A.AssettagNum,
				YRWK,
				CompBasePartNum,
				CompSerialNum,
				WOUsageQty,
				UsedFlag,
				UsedWhere,
				countofstrikes,
				CASE
					WHEN DATEPART(dw, GETDATE()) = 1 THEN
						CASE
							WHEN DATEPART(dw, D.Induction) = 1 THEN
								DATEDIFF(ww, GETDATE() - 1, D.Induction - 1)
							ELSE
								DATEDIFF(ww, GETDATE() - 1, D.Induction)
						END
					ELSE
						CASE
							WHEN DATEPART(dw, D.Induction) = 1 THEN
								DATEDIFF(ww, GETDATE(), D.Induction - 1)
							ELSE
								DATEDIFF(ww, GETDATE(), D.Induction)
						END
				END AS Weekgroup
		FROM QualityReporting.dbo.UsageDataDetailTable A
			JOIN ShopfloorN.dbo.SFOrderView B
				ON A.WorkOrdNum = B.WorkOrdNum
					AND A.Plant = B.Plant
			LEFT JOIN
			(SELECT * FROM [ShopFloorN].[dbo].[Part_Strikes]) C
				ON A.CompBasePartNum = C.part_number
					AND A.CompSerialNum = C.serial_num
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
			) D
				ON A.AssetTagNum = D.AssetTagNum
		WHERE A.Plant = 'FB'
				AND UsedFlag = 'Y'
				AND AsmPlanGroup = 'TRAY-ASM'
				AND AsmMachType = 'TLA'
				AND UsedWhere != ''
				AND D.Induction >= GETDATE() - 60
				AND DataSource = 'SerialTLA'
	) T1
	WHERE  Weekgroup >= -5
	ORDER BY BuiltYRWK


/*select distinct BuiltYRWK,AsmPlatform,AsmBasePartNum, 
AssettagNum, YRWK, CompBasePartNum,CompSerialNum, WOUsageQty,UsedFlag, UsedWhere, countofstrikes,Weekgroup
from (select CONCAT(YEAR(print_date),'W',RIGHT('0' + CAST(DATEPART(ISO_WEEK, print_date) AS NVARCHAR(2)), 2)) as BuiltYRWK, AsmPlatform,AsmBasePartNum, 
AssettagNum, YRWK, CompBasePartNum,CompSerialNum, WOUsageQty,UsedFlag, UsedWhere, countofstrikes,
case when     DATEPART(dw, getdate()) = 1 
          then  
                case when DATEPART(dw,print_date ) = 1
                     then DATEDIFF(ww, getdate()-1,print_date - 1)
                     ELSE DATEDIFF(ww,getdate()-1,print_date ) 
                end
          else   case when DATEPART(dw,print_date ) = 1
                     then DATEDIFF(ww, getdate(),print_date - 1)
                     ELSE DATEDIFF(ww,getdate(),print_date ) 
                end 
        end as Weekgroup
from QualityReporting.dbo.UsageDataDetailTable A 
join ShopfloorN.dbo.SFOrderView B on A.WorkOrdNum = B.WorkOrdNum and A.Plant = B.Plant
left join (SELECT *
           FROM [ShopFloorN].[dbo].[Part_Strikes]) C on A.CompBasePartNum = C.part_number and A.CompSerialNum = C.serial_num
join ShopFloorN.dbo.asset_tag_gen D on A.AssetTagNum = D.asset_tag_num
where A.Plant = 'FB' and UsedFlag = 'Y' and AsmPlanGroup = 'TRAY-ASM' and AsmMachType = 'TLA'
and UsedWhere != '' and  print_date >= GETDATE()-60 
and DataSource = 'SerialTLA') T1
where Weekgroup >= -5
order by BuiltYRWK*/