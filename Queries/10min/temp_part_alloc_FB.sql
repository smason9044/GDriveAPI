SELECT SiteCode,
       CompWIPBin,
       PartNum,
       AllocQty
FROM MIMDISTN.dbo.Form_Close_WipAllocQty
WHERE SiteCode = 'FB'
ORDER BY CompWIPBin