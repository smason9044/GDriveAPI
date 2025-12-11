SELECT Plant,
       WorkOrderNumber,
       MaintenanceType,
       MaintenanceID,
       MaintenanceTitle,
       MaintenanceDescription,
       CreatedUser,
       WOPerformUser,
       WOPerformUserDept,
       StatusUpdateDescription,
       UpdateTime,
       NextMaintenanceDate,
       ObjectName,
       AssetTagNumber,
       Location,
       ObjectDescription
FROM [CMMS].[dbo].[WOCompletionDetails]
WHERE UpdateTime >= GETDATE() - 30
      AND Plant = 'FB'
      AND WOPerformUserDept = 'TEST'
ORDER BY UpdateTime DESC
