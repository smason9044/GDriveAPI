SELECT OrderWipStatus.SC_UpdateUTCDate,
	   OrderWipStatus.SC_OrdNum,
       OrderWipStatus.SC_SSCC,
       OrderWipStatus.SC_Status,
       OrderWipStatus.BinNum,
	   OrderWipStatus.FormFactor,
	   v_Part.Platform,
       OrderWipStatus.SC_MIMPartNum,
	   OrderWipStatus.SC_Qty,
	   OrderWipStatus.WipOrderStatus,      
	   OrderWipStatus.OrdQty,
	   OrderWipStatus.StartedQty,
       OrderWipStatus.CompletedQty
FROM WreckingBall.dbo.OrderWipStatus
    LEFT OUTER JOIN PRODDIST.dbo.v_Part
        ON OrderWipStatus.SC_MIMPartNum = v_Part.PartNum
WHERE OrderWipStatus.WipOrderStatus <> 'CLOSED'
      AND OrderWipStatus.SC_Plant = N'FB'
ORDER BY v_Part.PlanGroup,
         v_Part.FormFactor,
         v_Part.Platform,
         OrderWipStatus.WipOrderStatus