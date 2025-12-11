SELECT DISTINCT
       EMP_EmpID,
       EMP_LongName,
       EMP_JobTitle,
       EMP_ShiftDesc,
       AsmPlatform,
       AsmFormFactor,
       CASE
           WHEN AsmFormFactor LIKE 'M%' THEN
               'MACHINE'
           WHEN (
                    AsmFormFactor = 'NRACK.IKEA3S'
                    AND
                    (
                        AsmPlatform in ('MINIGATE','ZOID2','QSFP-48V+','HYPERGATE')
                    )
                )
                OR
                (
                    AsmFormFactor = 'NRACK.IKEAS'
                    AND
                    (
                        AsmPlatform = 'ZOID2'
                        OR AsmPlatform = 'SPINE'
                    )
                ) THEN
               'NETWORK'
           WHEN (
                    AsmFormFactor = 'NRACK.IKEAS'
                    AND
                    (
                        AsmPlatform = 'ZOID2-C'
                        OR AsmPlatform = 'SB400-C'
                    )
                )
                OR
                (
                    AsmFormFactor = 'NRACK.IKEA3S'
                    AND AsmPlatform = 'FBR200'
                ) THEN
               'SPECIALTY'
           ELSE
               NULL
       END AS Categorized,
       /*CASE
           WHEN
           (
               (
                   Updated LIKE 'MC'
                   AND AsmFormFactor LIKE 'NRACK%'
               )
               OR Updated LIKE '%GATE'
               OR Updated LIKE 'RHO'
               OR Updated LIKE 'NRACK.IKEA3S'
               OR Updated LIKE 'SPOCS'
           ) THEN
               'NETWORK'
           WHEN
           (
               Updated LIKE 'RHO200'
               OR Updated LIKE 'FBR200'
               OR Updated LIKE 'SPINE'
               OR Updated LIKE 'ZOID2-C'
           ) THEN
               'SPECIALTY'
           WHEN
           (
               Updated LIKE 'PF'
               OR Updated LIKE 'VF'
           ) THEN
               'HYBRID'
           WHEN AsmFormFactor LIKE '%S%' THEN
               'SLIMS'
           ELSE
               'MACHINE'
       END AS 'Categorized',*/
       COUNT(StartTime) AS ScanIns
FROM
(
    SELECT EMP_EmpID,
           EMP_LongName,
           EMP_JobTitle,
           EMP_ShiftDesc,
           AsmPlatform,
           AsmFormFactor,
           StartTime
    /*CASE
        WHEN AsmPlatform LIKE 'QSFP-48V+' THEN
            AsmFormFactor
        ELSE
            AsmPlatform
    END AS Updated*/
    FROM ShopFloorN.dbo.Cable_Scan_1year t1
        LEFT JOIN PRODDIST.dbo.Base_EMPBasic B
            ON t1.EmpID = B.EMP_EmpID
    WHERE EMP_EmpStatus = 'A'
          AND CreateDate >= EMP_StartDate --and AsmPlatform = 'SPINE'
) t2
GROUP BY AsmPlatform,
         AsmFormFactor,
         EMP_EmpID,
         EMP_LongName,
         EMP_Jobtitle,
         EMP_ShiftDesc
ORDER BY EMP_EmpID,
         ScanIns DESC
