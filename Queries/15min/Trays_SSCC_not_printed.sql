SELECT asset_tag_num as AssetTagNum,
       RouteMasterDesc,
       Indicator,
       test_ScanOut,
       rack_name,
       test_step,
       route_status_code as Result,
       CreateDate as BoxCreated,
       BoxName,
	   SSCC,
       AsmLineAssigned as LineAssigned
FROM ShopFloorN.dbo.TRAYS_SSCC_Not_Printed
ORDER BY asset_tag_num,
         test_ScanOut
