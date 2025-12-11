SELECT Plant,
       IM_Platform,
       StartDate,
       StartTime,
       EndDate,
       EndTime,
       OriginalDate,
       Shift,
       YRWK,
       AsmLine,
       Room,
       StationId,
       Downtime,
       ReasonCode,
       ReasonDesc,
       IssueType,
       AssetTagNum,
       Comment,
       Who,
       Name
FROM ShopFloorN.dbo.LineTrackerWithPlatform
where len(assettagnum) = 12
ORDER BY CreateDate ASC