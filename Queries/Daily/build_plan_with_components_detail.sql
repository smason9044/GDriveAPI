SELECT a.CTBYRWk,
               a.CTBWkGrp,
               a.ProdNo,
               a.PartNum,
               CASE
                   WHEN a.PL_PartNum LIKE '%-R' THEN
                       LEFT(a.PL_PartNum, CHARINDEX('R', a.PL_PartNum, 0) - 2)
                   ELSE
                       a.PL_PartNum
               END AS ComponentPN,
               b.IM_CommCodePrimDesc,
               b.IM_CommCodePrimCode,
               a.SchedQty,
               a.DoneQty,
               a.RTP,
               a.RTF,
               a.SFC,
               a.LineAsn,
               a.PlanGroup,
               a.FormFactor,
               a.Platform,
               a.MachType,
               a.PL_PlanQty,
               a.PartDesc,
               format(a.SchedDate, 'yyyy-MM-dd') as SchedDate,
               a.SchedQty * 8 AS UsageQty,
               format(a.CTBDate, 'yyyy-MM-dd') as CTBDate,
               WIPBin
        FROM
        (
            (SELECT CTBYRWk,
                    SiteCode,
                    CTBWkGrp,
                    CONVERT(DATE, SchedDate) AS SchedDate,
                    CONVERT(DATE, CTBDate) AS CTBDate,
                    ProdNo,
                    PartNum,
                    PL_PartNum,
                    SchedQty,
                    DoneQty,
                    RTP,
                    RTF,
                    SFC,
                    LineAsn,
                    PlanGroup,
                    FormFactor,
                    Platform,
                    MachType,
                    PL_PlanQty,
                    PartDesc,
                    WIPBin
             FROM MIMDISTN.dbo.RPT_SiteAllocationWorkOrder
             WHERE SiteCode = 'FB'
                   AND (CTBWkGrp
                   BETWEEN 0 AND 2
                       )
                   AND ProdStatus = 'N'
                   AND ProdNo NOT IN
                       (
                           SELECT DISTINCT
                                  ProdNo
                           FROM MIMDISTN.dbo.RPT_Produce_ProdList
                           WHERE SiteCode = 'FB'
                                 AND ProdStatusDesc != 'CLOSED'
                                 AND
                                 (
                                     RTP = 'Y'
                                     OR RTF = 'Y'
                                     OR SFC = 'Y'
                                 )
                       ))
            UNION
            (SELECT CTBYRWk,
                    SiteCode,
                    CTBWkGrp,
                    CONVERT(DATE, SchedDate) AS SchedDate,
                    CONVERT(DATE, CTBDate) AS CTBDate,
                    ProdNo,
                    PartNum,
                    PL_PartNum,
                    SchedQty,
                    DoneQty,
                    RTP,
                    RTF,
                    SFC,
                    LineAsn,
                    PlanGroup,
                    FormFactor,
                    Platform,
                    MachType,
                    PL_PlanQty,
                    PartDesc,
                    WIPBin
             FROM MIMDISTN.dbo.RPT_Produce_ProdList
             WHERE SiteCode = 'FB'
                   AND ProdStatusDesc != 'CLOSED'
                   AND
                   (
                       RTP = 'Y'
                       OR RTF = 'Y'
                       OR SFC = 'Y'
                   ))
        ) a
            LEFT JOIN
            (
                SELECT DISTINCT
                       MIMPartNum AS IM_PartNum,
                       CommCodePrimCode AS IM_CommCodePrimCode,
                       CommCodePrimDesc AS IM_CommCodePrimDesc
                FROM MIMDISTN.dbo.part_info
            ) b
                ON a.PL_PartNum = b.IM_PartNum
        WHERE CTBYRWk != '2424W19'
        ORDER BY CTBWkGrp ASC,
                 ProdNo


    