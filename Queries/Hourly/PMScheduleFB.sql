SELECT Plant,
	   Status,
       MaintenanceType,
       MaintenanceTitle,
       MaintenanceDescription,
       Department,
       DueDays,
       ObjectDescription,
       AssetTagNumber,
       Location
FROM CMMS.dbo.WorkOrders WorkOrders
WHERE WorkOrders.Status <> N'Completed'
      AND WorkOrders.MaintenanceType <> N'Calibration'
      AND WorkOrders.Department = N'TEST'
      AND NOT (
                  WorkOrders.MaintenanceTitle = N'ESD'
                  OR WorkOrders.MaintenanceTitle = N'Floor ESD'
                  OR WorkOrders.MaintenanceTitle = N'Workbench ESD'
              )
      AND WorkOrders.Plant = N'FB'
      AND WorkOrders.DueDays <= 120
      AND WorkOrders.MaintenanceType != 'Ad-Hoc'
ORDER BY WorkOrders.DueDays


