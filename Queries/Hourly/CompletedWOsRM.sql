SELECT MaintenanceType,
       MaintenanceTitle,
       MaintenanceDescription,
       WOPerformUser,
       REPLACE(StatusUpdateDescription, CHAR(20), '') AS Status,
       UpdateTime,
       ObjectDescription
FROM
(
    SELECT WOCompletionDetails.MaintenanceType,
           WOCompletionDetails.MaintenanceTitle,
           WOCompletionDetails.MaintenanceDescription,
           WOCompletionDetails.WOPerformUser,
           WOCompletionDetails.StatusUpdateDescription,
           WOCompletionDetails.UpdateTime,
           WOCompletionDetails.ObjectDescription,
           ROW_NUMBER() OVER (PARTITION BY ObjectDescription,
                                           MaintenanceDescription
                              ORDER BY UpdateTime DESC
                             ) AS RowNum
    FROM CMMS.dbo.WOCompletionDetails
    WHERE WOCompletionDetails.Plant = N'FB'
          AND WOCompletionDetails.WOPerformUserDept = N'TEST'
          AND WOCompletionDetails.MaintenanceDescription IN ( 'Busbar', 'QSFP', 'QSFP Cables', 'iPASS Cables',
                                                              'S16 Cables'
                                                            )
) t1
WHERE RowNum = 1
ORDER BY ObjectDescription,
         MaintenanceDescription,
         UpdateTime


