SELECT A.Dept AS Department,
       B.FormFactor,
       C.Platform,
       a.CommodityID,
       d.CommodityName
FROM Training.dbo.Commodity_Platform A
    JOIN Training.dbo.FormFactor_Master B
        ON A.FormFactorID = B.FormFactorid
    JOIN Training.dbo.Platform_Master C
        ON A.PlatformID = C.PlatformID
    JOIN Training.dbo.CommodityList d
        ON a.CommodityID = d.CommodityID
WHERE a.ActiveFlag = 1
ORDER BY a.dept ASC,
         FormFactor ASC,
         platform ASC,
         CommodityID ASC
