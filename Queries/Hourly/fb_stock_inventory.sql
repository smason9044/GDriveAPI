WITH cte
AS (SELECT a.SSCCBox,
           a.SysDateTime,
           format(b.SysDate,'yyyy-MM-dd') as SysDate,
           a.WareHouseCode,
           a.WareHouse2,
           a.BinNum,
           a.BinNum2,
           ROW_NUMBER() OVER (partition BY a.ssccbox ORDER BY a.SysDateTime DESC) AS rn
    FROM PRODDIST.erp.PartTranStk a
        LEFT JOIN PRODDIST.erp.MtlQueueHistory b
            ON a.SEQ = b.MtlQueueSeq
    WHERE a.Plant = 'FB'
          AND a.SysDateTime >= DATEADD(day, -30, GETDATE())),
     cte2
AS (SELECT e.*,
           f.PartDesc AS IM_PartDescription,
           f.FormFactor AS IM_FormFactor,
           f.PlanGroup AS IM_PlanGroup,
           f.PlanGroup AS IM_Platform,
           f.MachType AS IM_MachType,
           f.CommCodePrimCode AS IM_CommCodePrimCode,
           f.CommCodePrimDesc AS CC_PrimCodeDesc
    FROM
    (
        SELECT c.SSCCBox,
               c.SysDateTime,
               c.SysDate,
               c.WareHouseCode,
               c.WareHouse2,
               c.BinNum,
               c.BinNum2,
               d.SC_MIMPartNum,
               d.SC_BasePartNum,
               SC_Qty
        FROM cte C
            LEFT JOIN PRODDIST.dbo.Base_SSCCMaster d
                ON c.SSCCBox = d.SC_SSCC
        WHERE rn = 1
              AND WareHouse2 LIKE '%FBSTOCK%'
              AND BinNum2 NOT LIKE '%BR%'
              AND
              (
                  WareHouseCode LIKE '%FBSTOCK%'
                  OR WareHouseCode LIKE '%FBPUTWAY%'
              )
    ) e
        LEFT JOIN MIMDISTN.dbo.part_info f
            ON e.SC_MIMPartNum = f.MIMPartNum)
SELECT SSCCBox,
       SysDateTime,
       SysDate,
       WareHouseCode,
       WareHouse2,
       BinNum,
       BinNum2,
       SC_MIMPartNum,
       IM_PartDescription,
       CC_PrimCodeDesc,
       SC_Qty,
       IM_FormFactor,
       IM_PlanGroup,
       IM_Platform,
       IM_MachType
FROM cte2 e
ORDER BY e.SysDateTime DESC;