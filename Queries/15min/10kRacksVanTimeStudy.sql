SELECT BoxYRWK as YRWK,
       SFTranHistoryView_All.AsmPlatform as PLATFORM,
       --SFTranHistoryView_All.AsmFormFactor,
       SFTranHistoryView_All.BasePartNum as GPN,
       --SFTranHistoryView_All.[WorkOrdNum],
       SFTranHistoryView_All.AssetTagNum as ASSETTAG,
       DateOfInduction as INDUCTION,
       BoxDate as BOX
FROM ShopFloorN.dbo.SFTranHistoryView_All
    JOIN
    (
        SELECT TOP (10000)
               A.gs_box_id,
               B.box_id,
               A.create_date AS BoxDate,
               CONCAT(YEAR(A.create_date), 'W', RIGHT('0' + CAST(DATEPART(iso_week, A.create_date) AS VARCHAR(2)), 2)) AS BoxYRWK,
               A.mim_part_num,
               B.asset_tag_num,
               source,
               box_name
        FROM [ShopFloorN].[dbo].[box] A
            JOIN ShopFloorN.dbo.box_detail B
                ON A.gs_box_id = B.box_id
        WHERE A.plant = 'FB'
              AND source = 'RACK-VAN'
        ORDER BY CloseDate DESC
    ) BoxTable
        ON BoxTable.asset_tag_num = SFTranHistoryView_All.asset_tag_num
WHERE SFTranHistoryView_All.plant = 'FB'
      AND SFTranHistoryView_All.AsmPlanGroup = 'RACK-ASM'
      AND SFTranHistoryView_All.AsmMachType = 'VANILLA'
      AND RouteMasterDesc LIKE 'APPLY%'
ORDER BY BoxDate,
         DateOfInduction