SELECT RPT_RTPSequence_AuditReport.Plant,
       RPT_RTPSequence_AuditReport.SeqNum,
       RPT_RTPSequence_AuditReport.ProdNo,
       RPT_RTPSequence_AuditReport.RTx,
       RPT_RTPSequence_AuditReport.WIPBin,
       RPT_RTPSequence_AuditReport.LineAsn,
       RPT_RTPSequence_AuditReport.SkuCude,
       RPT_RTPSequence_AuditReport.AdjPlanQty,
       RPT_RTPSequence_AuditReport.PlanQtyRT,
       RPT_RTPSequence_AuditReport.SFC,
       RPT_RTP_U_OpenMORQty.OrdQty,
       RPT_RTP_U_OpenMORQty.ShipQty,
       NLK_ProduceHeaderShort.PartNum,
       NLK_ProduceHeaderShort.LineAsn as NLK_LineAsn,
       RPT_RTP_U_MIMStk.QtyOnHand
FROM MIMDISTN.dbo.RPT_RTPSequence_AuditReport
    INNER JOIN MIMDISTN.dbo.NLK_ProduceHeaderShort
        ON RPT_RTPSequence_AuditReport.ProdNo = NLK_ProduceHeaderShort.ProdNo
    LEFT OUTER JOIN MIMDISTN.dbo.RPT_RTP_U_OpenMORQty
        ON RPT_RTPSequence_AuditReport.Plant = RPT_RTP_U_OpenMORQty.PO_Plant
           AND RPT_RTPSequence_AuditReport.SkuCude = RPT_RTP_U_OpenMORQty.PO_BasePartNum
    LEFT OUTER JOIN MIMDISTN.dbo.RPT_RTP_U_MIMStk
        ON RPT_RTPSequence_AuditReport.Plant = RPT_RTP_U_MIMStk.Plant
           AND RPT_RTPSequence_AuditReport.SkuCude = RPT_RTP_U_MIMStk.BasePartNum
WHERE RPT_RTPSequence_AuditReport.Plant = 'FB'