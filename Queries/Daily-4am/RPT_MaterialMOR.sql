SELECT DISTINCT
       BPA_CreateUTCDate,
       BPA_GPN,
       BPA_Quantity,
       BPA_FromLoc,
       BPA_FromProj,
       BPA_ToLoc,
       BPA_ToProj,
       MORNO,
       MOR_TranStatus
FROM PRODDIST.dbo.RPT_MaterialMOR
WHERE plant = 'FB'
      AND MOR_OrdStatus = 'OPEN'
      AND BPA_ToLoc = 'WHGAFB2PD'
ORDER BY BPA_CreateUTCDate DESC