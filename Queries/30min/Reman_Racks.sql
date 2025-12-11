WITH cte1
AS (SELECT CreateDate,
           OrderID,
           AssetTagNum,
           AssetTagStatus,
           FormFactor,
           Platform,
           AsmType,
           Disposition,
           NewPartNum,
           SSCC,
           PlanGroup,
           UpdateDate
    FROM WreckingBall.dbo.WBAssetTagDetailTable
    WHERE LEN(NewPartNum) > 0
          AND plant = 'FB'
          AND CAST(CREATEDATE AS DATE) > CAST(GETDATE() - 60 AS DATE)
          AND PlanGroup = 'RACK-ASM'
          AND Disposition = 'CREATE VANILLA'),
     cte2
AS (SELECT DISTINCT
           AssetTagNum,
           StationID
    FROM
    (
        SELECT AssetTagNum,
               CreateDate,
               StationID,
               ROW_NUMBER() OVER (PARTITION BY ASSETTAGNUM ORDER BY CREATEDATE ASC) AS rn,
               COUNT(*) OVER (partition BY assettagnum) AS cnt
        FROM WreckingBall.dbo.WBAssetTagOperView
        WHERE plant = 'FB'
              AND CAST(CREATEDATE AS DATE) > CAST(GETDATE() - 60 AS DATE)
    ) a
    WHERE rn = 1
          AND cnt = 2)
SELECT b.CreateDate,
       b.OrderID,
       b.AssetTagNum,
       b.AssetTagStatus,
       b.FormFactor,
       b.Platform,
       b.AsmType,
       b.Disposition,
       b.NewPartNum,
       b.SSCC,
       b.PlanGroup,
       b.UpdateDate,
       c.stationid
FROM cte1 b
    INNER JOIN cte2 c
        ON b.AssetTagNum = c.AssetTagNum
ORDER BY b.CreateDate DESC


