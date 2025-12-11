SELECT TOP 500
       CreateDate,
       AssetTagNum,
       TestStep,
       StationID,
       TestLog
FROM ShopFloorN.dbo.SFTestLogs
ORDER BY CreateDate DESC