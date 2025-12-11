SELECT PH_CreateDateLT,
       PH_MTFromLoc,
       PH_MTFromProj,
       PD_PartNum,
       PD_OrdQty,
       PH_PutAwayZone,
       ASN_Qty,
       MT_MORNO
FROM PRODDIST.dbo.RPT_InboundOpenMT
WHERE PH_Plant = 'FB'
      AND CONVERT(DATE, PH_CreateDateLT) >= CONVERT(DATE, GETDATE() - 28)
---AND MT_MORNO NOT  LIKE 'MOR%'
ORDER BY PH_CreateDateLT DESC
 
