SELECT --RPT_BoxtStatus_WB.Plant,
    RPT_BoxtStatus_WB.CreateDate as BoxDate,
    RPT_BoxtStatus_WB.BoxName as BoxID,
    RPT_BoxtStatus_WB.GooPartNum as PartNum,
    RPT_BoxtStatus_WB.BoxStatusDesc as BoxStatus,
    RPT_BoxtStatus_WB.BoxQty as Quantity,
    CASE
        WHEN RPT_BoxtStatus_WB.MrbFlag = 'Y' THEN
            'MRB'
        ELSE
            ' '
    END AS MrbFlag,
    CASE
        WHEN RPT_BoxtStatus_WB.Disposition IS NULL THEN
            'MISSING!'
        WHEN RPT_BoxtStatus_WB.Disposition = ' ' THEN
            'MISSING!'
        ELSE
            RPT_BoxtStatus_WB.Disposition
    END AS Disposition,
    RPT_BoxtStatus_WB.FromBin,
    RPT_BoxtStatus_WB.StationID,
    EMPShortName as WhoBoxed
FROM PRODDIST.dbo.RPT_BoxtStatus_WB
    /*LEFT OUTER JOIN PRODDIST.dbo.Base_Part_Ext
        ON RPT_BoxtStatus_WB.BasePartNum = Base_Part_Ext.IM_PartNum */
    LEFT OUTER JOIN PRODDIST.dbo.Base_PartBinQty
        ON RPT_BoxtStatus_WB.FromWarehouse = Base_PartBinQty.PBQ_WhseCode
           AND RPT_BoxtStatus_WB.FromBin = Base_PartBinQty.PBQ_BinNum
           AND RPT_BoxtStatus_WB.Plant = Base_PartBinQty.PBQ_Plant
           AND RPT_BoxtStatus_WB.GooPartNum = Base_PartBinQty.PBQ_PartNum
WHERE RPT_BoxtStatus_WB.Plant = 'FB'
      AND CreateDate >= GETDATE() - 56
ORDER BY CreateDate ASC

