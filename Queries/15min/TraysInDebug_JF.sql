SELECT B.PrintDate,
       C.BuildID,
       C.WorkOrdNum,
       A.AssetTagNum,
       C.BasePartNum,
       C.AsmPlatform,
       C.AsmLineAssigned AS AsmLine,
       F.CTBDate AS SchedDate,
       E.DebugTurn,
       CASE
           WHEN A.CurrAssetTagStatus = 1635 THEN
               'QA Failure'
           ELSE
               E.FailureTest
       END AS TestResults,
       CASE
           WHEN D.auto_id > 0 THEN
               'RE-TEST'
           ELSE
               ''
       END AS ReTest,
       CASE
           WHEN A.MessageID >= D.message_id THEN
               ''
           ELSE
               D.result
       END AS CurrTestStatus,
       D.current_test
FROM ShopFloorN.dbo.SFAssetTagDetailView A
    INNER JOIN ShopFloorN.dbo.SFAssetTagGenView B
        ON A.AssetTagNum = B.AssetTagNum
           AND A.Plant = B.Plant
    LEFT JOIN ShopFloorN.dbo.SFOrderView C
        ON B.WorkOrdNum = C.WorkOrdNum
           AND B.Plant = C.Plant
    LEFT JOIN ShopFloorN.dbo.temp_asset_tag_test D
        ON A.AssetTagNum = D.asset_tag_num
           AND A.Plant = D.plant
    LEFT JOIN ShopFloorN.dbo.SFU_LastTestTranRecResults E
        ON A.AssetTagNum = E.AssetTagNum
           AND A.MessageID = E.TestMessageID
    LEFT OUTER JOIN PRODDIST.dbo.NLK_ProduceHeader F
        ON C.WorkOrdNum = F.ProdNo
           AND C.Plant = F.SiteCode
WHERE A.plant = 'FB'
      AND TRY_CONVERT(DATE, C.CreateDate) >= TRY_CONVERT(DATE, GETDATE() - 20)
      AND C.AsmPlanGroup = 'TRAY-ASM'
      AND C.AsmMachType <> 'VANILLA'
      AND C.OrderStatusCode <> 'C'
      AND
      (
          A.RouteStatusCode = 'F'
          OR A.RouteStatusCode = 'N'
      )
      AND F.LineAsn <> 'D11'
      AND E.TestStep <> 'PQA'
ORDER BY B.PrintDate,
         A.AssetTagNum