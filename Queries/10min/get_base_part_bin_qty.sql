SELECT DISTINCT
       Base_PartBinQty.PBQ_OnhandQty,
       Base_PartBinQty.PBQ_WhseCode,
       Base_PartBinQty.PBQ_Plant,
       Base_PartBinQty.PBQ_BinNum,
       Base_PartBinQty.PBQ_BasePartNum,
       part_info.PartDesc,
       part_info.CommCodePrimDesc,
       part_info.CommCodePrimCode,
       Base_PartBinQty.PBQ_PartNum,
       GETDATE() AS lastUpdate
FROM ProdDist.dbo.Base_PartBinQty
    LEFT OUTER JOIN MIMDISTN.dbo.part_info
        ON Base_PartBinQty.PBQ_PartNum = part_info.MIMPartNum
WHERE Base_PartBinQty.PBQ_Plant = 'FB'
      AND Base_PartBinQty.PBQ_WhseCode IN ( 'FBFGI', 'FBOSV', 'FBSTOCK', 'FBWIP' )
      AND
      (
          Base_PartBinQty.PBQ_BinNum LIKE 'FGI%'
          OR Base_PartBinQty.PBQ_BinNum = 'HOLD'
          OR Base_PartBinQty.PBQ_BinNum = 'MAKESWAP'
          OR Base_PartBinQty.PBQ_BinNum = 'PIRECON'
          OR Base_PartBinQty.PBQ_BinNum = 'QUALITY'
          OR Base_PartBinQty.PBQ_BinNum = 'RESEARCH'
          OR Base_PartBinQty.PBQ_BinNum = 'RTS'
          OR Base_PartBinQty.PBQ_BinNum = 'SOI100'
          OR Base_PartBinQty.PBQ_BinNum LIKE 'WIP%'
          OR Base_PartBinQty.PBQ_BinNum = 'ENG'
          OR Base_PartBinQty.PBQ_BinNum = 'PADECOM'
      )
ORDER BY Base_PartBinQty.PBQ_BasePartNum,
         Base_PartBinQty.PBQ_BinNum