SELECT Snap_WhseCode,
       Snap_ProjCode,
       B.PlanGroup AS IM_PlanGroup,
       Snap_PartNum,
       B.FormFactor AS IM_FormFactor,
       B.Platform AS IM_Platform,
       B.MachType AS IM_MachType,
       Snap_AllocQty,
       Snap_AvailQty,
       Snap_OnHandQty,
       Snap_Plant,
       Snap_Dept,
       Snap_LocType,
       Snap_InTranFlag,
       Snap_NonNetFlag
FROM PRODDIST.dbo.Goo_InvSnapshotView A
    LEFT JOIN MIMDISTN.dbo.part_info B
        ON A.Snap_PartNum = B.MIMPartNum
WHERE Snap_Plant = 'FB'
ORDER BY Snap_WhseCode,
         Snap_ProjCode