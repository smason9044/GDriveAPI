SELECT Plant,
       CreateDate,
	   IM_PartNum,
	   IM_Platform,
       IM_PartDescription,
       AssetTagNum,
       RackName,
       EmpID,
       test_step,
       TestCount,
       ROW_NUMBER() OVER (PARTITION BY AssetTagNum ORDER BY CreateDate DESC) AS Numbered,
       TestError,
       WorkOrdNum,
       RouteStatusCode,
       AsmFormFactor,
       FailureHeaderID
FROM
(
    SELECT *
    FROM ShopFloorN.dbo.AllLiveTestRacksFB
    UNION ALL
    SELECT *
    FROM NFShopFloorN.dbo.AllLiveTestRacksNF
) T1
ORDER BY Plant,
         CreateDate
