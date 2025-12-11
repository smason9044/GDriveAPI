SELECT RPT_SML_LineCount.WipBin,
       RPT_SML_LineCount.CompBasePartNum,
       RPT_SML_LineCount.LineCount,
       RPT_SML_LineCount.LineAsn,
       RPT_SML_LineCount.NeedQty,
       part_info.CommCodePrimDesc as PartTypeDesc,
       part_info.PartDesc as description
FROM PRODDIST.dbo.RPT_SML_LineCount
    LEFT OUTER JOIN MIMDISTN.dbo.part_info
        ON RPT_SML_LineCount.CompBasePartNum = part_info.MIMPartNum
ORDER BY RPT_SML_LineCount.WipBin,
         part_info.CommCodePrimDesc,
         RPT_SML_LineCount.CompBasePartNum