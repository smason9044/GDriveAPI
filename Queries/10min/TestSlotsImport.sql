SELECT DISTINCT
       RackName,
       SlotNum,
       DATE,
       AssetTagNum,
       FailureType,
       TestError,
       FailureSymptom
FROM ShopFloorN.dbo.RPT_DisabledTestSlots