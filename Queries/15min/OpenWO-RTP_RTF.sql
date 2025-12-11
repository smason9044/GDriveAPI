SELECT ProdNum,
       WhoEntered,
       CTBFlag,
       WONotes,
       CBPFlag,
       WOHoldFlag,
       RTP,
       RTPDate,
       RTPDateLT,
       RTF,
       SFC,
       SFCDate,
       LineAsn,
       GooPartNum,
       PlanGroup,
       Platform,
       MachType,
	   CloseDate,
	   CTBWkGrp,
	   CTBYRWk,
	   BP_BuildID,
	   FormFactor,
	   BP_Committed,
	   SchedQty,
	   DoneQty
FROM MIMDISTN.dbo.RPT_PDII_Schedule
WHERE SiteCode = 'FB' and CTBWkGrp >= -4 and CTBWkGrp < 10
order by RTPDateLT

/*SELECT ProdNum,
       WhoEntered,
       CTBFlag,
       WONotes,
       CBPFlag,
       WOHoldFlag,
       RTP,
       RTPDate,
       RTPDateLT,
       RTF,
       SFC,
       SFCDate,
       LineAsn,
       GooPartNum,
       PlanGroup,
       Platform,
       MachType
FROM MIMDISTN.dbo.RPT_PDII_Schedule
WHERE SiteCode = 'FB'
      AND CloseDate IS NULL
      AND CTBFlag = 'N'
      AND RTP = 'Y' 
ORDER BY RTPDateLT */