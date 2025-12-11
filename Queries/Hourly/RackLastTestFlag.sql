SELECT SiteCode as Plant,
       PartNum,
       ProdNo,
       AsmPlatform,
       RouteDescription,
       'Y' AS Flag
FROM PRODDIST.dbo.RackLastTestFlag
WHERE COUNT = 1
ORDER BY SiteCode