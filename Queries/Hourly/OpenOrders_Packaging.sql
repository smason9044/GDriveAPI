SELECT PCK_OrderNum,
       PCK_MTNum,
       PCK_FromLoc,
       PCK_FromProj,
       --GPN,
       UpdatedGPN,
       PCK_Quantity,
       MT_MORNO,
       MTR_MTID,
       MT_ShipQty,
       IM_PartDescription,
       PCK_CreateLTDate,
       MT_LineTranStatus,
       MTR_EDIICN,
       PCK_ToLoc,
       PCK_ToProj,
       CASE
           WHEN OrdStatus = 'SHIPPED'
                AND DATEDIFF(day, PCK_CreateLTDate, GETDATE()) > 5 THEN
               'Y'
           WHEN OrdStatus <> 'SHIPPED'
                AND DATEDIFF(day, PCK_CreateLTDate, GETDATE()) > 8 THEN
               'Y'
           ELSE
               'N'
       END Closed,
       CASE
           WHEN GPN LIKE '%-R' THEN
               '-R'
           ELSE
               ''
       END AS RFlag
FROM
(
    SELECT DISTINCT
           Base_PackagingOrder.PCK_OrderNum,
           Base_PackagingOrder.PCK_MTNum,
           Base_PackagingOrder.PCK_FromLoc,
           Base_PackagingOrder.PCK_FromProj,
           Base_PackagingOrder.GPN,
           CASE
               WHEN RIGHT(Base_PackagingOrder.GPN, 2) = '-R' THEN
                   LEFT(Base_PackagingOrder.GPN, LEN(Base_PackagingOrder.GPN) - 2)
               ELSE
                   Base_PackagingOrder.GPN
           END AS UpdatedGPN,
           Base_PackagingOrder.PCK_Quantity,
           Base_PackagingOrder.PCK_CreateUTCDate,
           Goo_InboundStatusExt.MT_MORNO,
           Goo_InboundStatusExt.TotalStatus,
           Goo_InboundStatusExt.MTR_MTID,
           Goo_InboundStatusExt.BColor1,
           Goo_InboundStatusExt.Bcolor2,
           Goo_InboundStatusExt.BColor3,
           Goo_InboundStatusExt.FColor1,
           Goo_InboundStatusExt.FColor2,
           Goo_InboundStatusExt.FColor3,
           Goo_InboundStatusExt.MT_ShipQty,
           part_info.PartDesc AS IM_PartDescription,
           Base_PackagingOrder.PCK_CreateLTDate,
           Goo_InboundStatusExt.MT_LineTranStatus,
           Base_PackagingOrder.PCK_Plant,
           Goo_InboundStatusExt.MTR_EDIICN,
           Base_PackagingOrder.PCK_ToLoc,
           Base_PackagingOrder.PCK_ToProj,
           CASE
               WHEN Goo_InboundStatusExt.MTR_MTID IS NULL THEN
                   'NOT CRATED'
               WHEN Goo_InboundStatusExt.MT_LineTranStatus = 'PARTIALLY_SHIPPED' THEN
                   'SHIPPED'
               ELSE
                   Goo_InboundStatusExt.TotalStatus
           END OrdStatus
    FROM PRODDIST.dbo.Base_PackagingOrder Base_PackagingOrder
        INNER JOIN MIMDISTN.dbo.part_info
            ON Base_PackagingOrder.GPN = part_info.MIMPartNum
        LEFT OUTER JOIN PRODDIST.dbo.Goo_ReplenStatusExt Goo_InboundStatusExt
            ON Base_PackagingOrder.PCK_MTNum = Goo_InboundStatusExt.MTR_MTNO
    WHERE Base_PackagingOrder.PCK_Plant = N'FB'
--(Base_PackagingOrder.PCK_FromLoc= 'WHGAFB2PK'or Base_PackagingOrder.PCK_FromLoc='WHGANO1PK')
) T1
WHERE CASE
          WHEN OrdStatus = 'SHIPPED'
               AND DATEDIFF(day, PCK_CreateLTDate, GETDATE()) > 5 THEN
              'Y'
          WHEN OrdStatus <> 'SHIPPED'
               AND DATEDIFF(day, PCK_CreateLTDate, GETDATE()) > 8 THEN
              'Y'
          ELSE
              'N'
      END = 'N'
      AND
      (
          MT_LineTranStatus != 'FULLY_RECEIVED'
          OR MT_LineTranStatus IS NULL
      )
      AND (PCK_FromLoc IN ( 'WHGAFB2PK', 'WHGANO1PK' ))