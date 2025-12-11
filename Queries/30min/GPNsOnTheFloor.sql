SELECT DISTINCT
       RPT_BuildSchedule_TrayRackTLA.ProdNo AS WorkOrdNum,
       RPT_BuildSchedule_TrayRackTLA.PartNum,
       RPT_BuildSchedule_TrayRackTLA.Platform,
       RPT_BuildSchedule_TrayRackTLA.FormFactor,
       RPT_BuildSchedule_TrayRackTLA.CTBYRWk,
       RPT_BuildSchedule_TrayRackTLA.Current_YRWK,
       RPT_BuildSchedule_TrayRackTLA.PartDesc,
       RPT_BuildSchedule_TrayRackTLA.RTF,
       RPT_BuildSchedule_TrayRackTLA.SFC,
       RPT_BuildSchedule_TrayRackTLA.LineAsn,
       RPT_BuildSchedule_TrayRackTLA.WIPBin,
       'TLA' AS MachType
FROM MIMDISTN.dbo.RPT_BuildSchedule_TrayRackTLA RPT_BuildSchedule_TrayRackTLA
WHERE RPT_BuildSchedule_TrayRackTLA.SiteCode = 'FB'
      AND RPT_BuildSchedule_TrayRackTLA.PlanGroup = 'RACK-ASM'
      AND RPT_BuildSchedule_TrayRackTLA.ProdStatus <> 'S'
      AND RPT_BuildSchedule_TrayRackTLA.RTF = 'Y'
UNION ALL
SELECT DISTINCT
       RPT_BuildSchedule_NonRackTrayTLA.ProdNo,
       RPT_BuildSchedule_NonRackTrayTLA.PartNum,
       RPT_BuildSchedule_NonRackTrayTLA.Platform,
       RPT_BuildSchedule_NonRackTrayTLA.FormFactor,
       RPT_BuildSchedule_NonRackTrayTLA.CTBYRWk,
       RPT_BuildSchedule_NonRackTrayTLA.Current_YRWK,
       RPT_BuildSchedule_NonRackTrayTLA.PartDesc,
       RPT_BuildSchedule_NonRackTrayTLA.RTF,
       RPT_BuildSchedule_NonRackTrayTLA.SFC,
       RPT_BuildSchedule_NonRackTrayTLA.LineAsn,
       RPT_BuildSchedule_NonRackTrayTLA.WIPBin,
       'VANILLA' AS MachType
FROM MIMDISTN.dbo.RPT_BuildSchedule_NonTrayRackTLA RPT_BuildSchedule_NonRackTrayTLA
WHERE RPT_BuildSchedule_NonRackTrayTLA.SiteCode = 'FB'
      AND RPT_BuildSchedule_NonRackTrayTLA.PlanGroup = 'RACK-ASM'
      AND RPT_BuildSchedule_NonRackTrayTLA.ProdStatus <> 'S'
      AND RPT_BuildSchedule_NonRackTrayTLA.RTF = 'Y'


