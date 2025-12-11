SELECT A.ProdNo,
       CASE
           WHEN A.ProdStatus = 'S' THEN
               'CLOSED'
           ELSE
               'OPEN'
       END AS OrderStatus,
       A.CTBDate,
       A.AsmFormFactor,
       A.AsmPlatform,
       ROW_NUMBER() OVER (PARTITION BY A.LineAsn ORDER BY A.ProdNo, A.LineAsn) AS Count_ProdNum,
       A.AsmMachType,
       CASE
           WHEN A.FAFlag = 'Y' THEN
               'FA'
           ELSE
               ''
       END AS FA_Flag,
       CASE
           WHEN A.NPIFlag = 'Y' THEN
               'NPI'
           ELSE
               ''
       END AS NPI_Flag,
       CASE
           WHEN A.BP_Comitted = 'Y' THEN
               'C'
           ELSE
               ''
       END AS Committed,
       A.PartNum,
       A.LineAsn,
       (A.AsmSchedQty - A.AsmStartQty) * B.STD_TTMinPerUnit AS MinPerWO,
       A.PlatFormGroup,
       A.PlatFormPart,
       CASE
           WHEN A.SML_Order = 0 THEN
               'Y'
           ELSE
               ''
       END AS SM_Flag,
       A.SML_ActionedQty,
       CASE
           WHEN A.SFC = 'Y' THEN
               'Y'
           ELSE
               ''
       END AS SFC_Flag,
       A.RTFSFCDate,
       A.SFAsmLine,
       A.SchedQty,
       A.AsmStartQty,
       A.SFBoxedQty,
       A.SchedQty - A.SFBoxedQty AS Due_Qty,
       CASE
           WHEN A.SchedQty = 0 THEN
               0
           ELSE
       (A.SFBoxedQty / A.SchedQty) * 100
       END AS Completed,
       AsmPlanGroup
FROM MIMDISTN.dbo.RPT_RTFSequence_B A
    FULL OUTER JOIN MIMDISTN.dbo.Base_ProcessTheoreticalValues B
        ON A.Plant = B.Plant
           AND A.SkuCode = B.AsmBasePartNum
WHERE A.Plant = 'FB'
      AND NOT (
                  A.ProdNo = 918924
                  OR A.ProdNo = 934128
                  OR A.ProdNo = 1062220
                  OR A.ProdNo = 1062221
                  OR A.ProdNo = 1062222
                  OR A.ProdNo = 1062223
              )
      AND NOT (
                  A.PartNum = '1063474-01'
                  OR A.PartNum = '1063475-01'
                  OR A.PartNum = '1114424'
              )