SELECT RPT_BoxtStatus_SF.CreateDate,
       RPT_BoxtStatus_SF.CloseDate,
       RPT_BoxtStatus_SF.BoxName AS BoxID,
       RPT_BoxtStatus_SF.GooPartNum AS PartNum,
       part_info.PartDesc,
       RPT_BoxtStatus_SF.BoxStatusDesc AS BoxStatus,
       RPT_BoxtStatus_SF.BoxQty AS Qty,
       RPT_BoxtStatus_SF.FromBin,
       RPT_BoxtStatus_SF.BoxSource,
       RPT_BoxtStatus_SF.StationID,
       RPT_BoxtStatus_SF.EMPShortName AS Name,
       RPT_BoxtStatus_SF.ToBin
FROM PRODDIST.dbo.RPT_BoxtStatus_SF
    LEFT OUTER JOIN MIMDISTN.dbo.part_info
        ON RPT_BoxtStatus_SF.BasePartNum = part_info.MIMPartNum
    LEFT OUTER JOIN PRODDIST.dbo.Base_WhseBin
        ON RPT_BoxtStatus_SF.FromWarehouse = Base_WhseBin.WB_WhseCode
           AND RPT_BoxtStatus_SF.FromBin = Base_WhseBin.WB_BinNum
    LEFT OUTER JOIN PRODDIST.dbo.Base_BPDist_DItem
        ON RPT_BoxtStatus_SF.GooPartNum = Base_BPDist_DItem.DItem_GPN
           AND RPT_BoxtStatus_SF.BuildID = Base_BPDist_DItem.BuildID
    LEFT OUTER JOIN PRODDIST.dbo.Base_PartPlantPackView
        ON RPT_BoxtStatus_SF.Plant = Base_PartPlantPackView.Plant
           AND RPT_BoxtStatus_SF.BasePartNum = Base_PartPlantPackView.PartNum
WHERE RPT_BoxtStatus_SF.Plant = 'FB'
      AND NOT (
                  Base_WhseBin.WB_ZoneID = N'CONS'
                  OR Base_WhseBin.WB_ZoneID = N'OSV'
              )
      AND RPT_BoxtStatus_SF.BoxStatusDesc LIKE 'CLOSE%'
      AND DATEDIFF(hh, RPT_BoxtStatus_SF.CloseDate, GETDATE()) > 2