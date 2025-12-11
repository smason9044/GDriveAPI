WITH CQA_Results
AS (SELECT WorkOrdNum,
           MAX(   CASE
                      WHEN s.TestStep = 'CQA' THEN
                          s.RouteStatus
                      ELSE
                          NULL
                  END
              ) AS CQA_Status
    FROM ShopFloorN.dbo.SFTranHistoryView s
    WHERE s.TestStep <> ''
    GROUP BY s.WorkOrdNum),
     Hipot_Result
AS (SELECT WorkOrdNum,
           COUNT(s.TranType) AS Hipot_Pass
    FROM ShopFloorN.dbo.SFTranHistoryView s
    WHERE s.TestStep = 'IKEAHIPOT'
          AND RouteStatus = 'P'
    GROUP BY s.WorkOrdNum)
SELECT A_SP_AssetTagSummaryViewFiltered.O_WorkOrdNum,
       A_SP_AssetTagSummaryViewFiltered.O_AsmLine,
       A_SP_AssetTagSummaryViewFiltered.O_PartNum,
       A_SP_AssetTagSummaryViewFiltered.O_QtyOrdered,
       A_SP_AssetTagSummaryViewFiltered.BoxedQty,
       A_SP_AssetTagRouteCnt_RTLA.AssetTagNum,
       A_SP_AssetTagRouteCnt_RTLA.apply_cnt,
       A_SP_AssetTagRouteCnt_RTLA.pop_cnt,
       CASE
           WHEN Hipot_Result.Hipot_Pass > 0 THEN
               Hipot_Pass
           ELSE
               0
       END AS Hipot_Pass,
       CASE
           WHEN A_SP_AssetTagRouteCnt_RTLA.pwr_results = 'P' THEN
               1
           ELSE
               0
       END AS pwr_results,
       CASE
           WHEN CQA_Results.CQA_Status = 'P' THEN
               1
           ELSE
               0
       END AS CQA_status,
       A_SP_AssetTagSummaryViewFiltered.EP_Status
FROM ShopFloorN.dbo.A_SP_AssetTagSummaryViewFiltered
    LEFT OUTER JOIN ShopFloorN.dbo.A_SP_AssetTagRouteCnt_RTLA
        ON A_SP_AssetTagSummaryViewFiltered.O_WorkOrdNum = A_SP_AssetTagRouteCnt_RTLA.WorkOrdNum
           AND A_SP_AssetTagSummaryViewFiltered.O_AsmLine = A_SP_AssetTagRouteCnt_RTLA.ATRS_AsmLine
           AND A_SP_AssetTagSummaryViewFiltered.O_Plant = A_SP_AssetTagRouteCnt_RTLA.Plant
    LEFT OUTER JOIN CQA_Results
        ON A_SP_AssetTagSummaryViewFiltered.O_WorkOrdNum = CQA_Results.WorkOrdNum
    LEFT OUTER JOIN Hipot_Result
        ON A_SP_AssetTagSummaryViewFiltered.O_WorkOrdNum = Hipot_Result.WorkOrdNum