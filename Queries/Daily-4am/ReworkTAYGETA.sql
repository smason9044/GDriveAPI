SELECT Plant,
       SSCC,
       MIMPartNum,
       WKNum,
       OrderDate,
       QtyOrdered,
       QtyCompleted,
       QtyOpen,
       DecomDate
FROM WreckingBall.dbo.RPT_TAYGETARework
ORDER BY Plant,
         WKNum