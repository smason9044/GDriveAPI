SELECT Plant,
       DayName,
       AsmLineID,
       ShiftSeq,
       EndPeriod,
       CAST(DATEADD(SECOND, EndPeriod * 3600, CAST(0 AS DATETIME)) AS TIME) AS TIME,
       --CAST(CONVERT(VARCHAR, DATEADD(SECOND, EndPeriod * 3600, 0), 108) AS TIME) AS TIME,
       Shift,
       Platform,
       ExpQty,
       ActQty,
       SumPerc
FROM ShopFloorN.dbo.VDashLineRate_Final
WHERE Shift = 'SHIFT 1'
      AND Platform != ' '