SELECT a.[CommodityID],
       a.[CommodityName],
       a.[CommodityType],
       a.[ActiveFlag],
       a.[CommodityDesc],
       a.[CommodityDept],
       b.Latest_Active_Date
FROM [Training].[dbo].[CommodityList] a
    OUTER apply
(
    SELECT TOP 1
           t.TestDate AS Latest_Active_Date
    FROM [Training].[dbo].[TrainingLog] t
    WHERE t.ComodityID = a.CommodityID
    ORDER BY t.TestDate DESC
) b
WHERE a.ActiveFlag = 1
ORDER BY a.CommodityDept ASC,
         a.CommodityID ASC