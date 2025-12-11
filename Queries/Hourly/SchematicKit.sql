SELECT KitNum,
       WONum,
       PartNum,
       B.AssetTagNum,
       LineNum,
       LabelerName,
       LeadName,
       A.PrintDate,
       Status,
       SchemPartNum
FROM ShopFloorN.dbo.SFSchematicKitDetail A
    LEFT JOIN ShopFloorN.dbo.SFAssetTagGenView B
        ON A.WONum = B.WorkOrdNum
WHERE YEAR(A.PrintDate) = YEAR(GETDATE())
ORDER BY PrintDate DESC



