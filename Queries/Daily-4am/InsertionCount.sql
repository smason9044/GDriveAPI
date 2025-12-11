SELECT Plant,
       Cable,
       Rack,
       Slot_Qty,
       Slot_Threshold,
       Slot_Disabled_Qty,
       Slot_Disabled_Percent,
       LastMaintenanceDate
FROM CMMS.dbo.InsertionCount
ORDER BY Plant,
         Cable,
         Rack


