WITH CTE1
AS (SELECT
        --dateadd(hh,3,[SysDateTime]) as Updated_date,
        CONVERT(DATE, DATEADD(hh, 3, [SysDateTime])) AS DATE,
        FORMAT(CONVERT(DATE, DATEADD(hh, 3, [SysDateTime])), 'dddd') AS day,
        CONCAT(
                  YEAR(DATEADD(hh, 3, [SysDateTime])),
                  'W',
                  FORMAT(DATEPART(iso_week, DATEADD(hh, 3, [SysDateTime])), '00')
              ) AS YRWK,
        WareHouseCode,
        BinNum,
        WareHouse2,
        BinNum2,
        EMI AS EmpID,
        'In' AS dir
    FROM PRODDIST.erp.PartTranStk
    WHERE Plant = 'FB'
          AND SysDateTime >= DATEADD(week, DATEDIFF(week, 0, GETDATE()), -21)
          AND EntryPerson LIKE 'FBHAND%'
          AND EMI <> ''
    UNION ALL
    SELECT --dateadd(hh,3,[SysDateTime]) as Updated_date,
        CONVERT(DATE, DATEADD(hh, 3, [SysDateTime])) AS DATE,
        FORMAT(CONVERT(DATE, DATEADD(hh, 3, [SysDateTime])), 'dddd') AS day,
        CONCAT(
                  YEAR(DATEADD(hh, 3, [SysDateTime])),
                  'W',
                  FORMAT(DATEPART(iso_week, DATEADD(hh, 3, [SysDateTime])), '00')
              ) AS YRWK,
        WareHouseCode,
        BinNum,
        WareHouse2,
        BinNum2,
        CASE
            WHEN EMO = ''
                 AND PRE = 'ABB' THEN
                EMI
            WHEN EMO <> '' THEN
                EMO
        END AS ScanOutEmpID,
        'Out' AS dir
    FROM PRODDIST.erp.PartTranStk
    WHERE Plant = 'FB'
          AND SysDateTime >= DATEADD(week, DATEDIFF(week, 0, GETDATE()), -21)
          AND EntryPerson LIKE 'FBHAND%')
SELECT YRWK,
       DATE,
       Day,
       T1.EMP_ShiftDesc AS Shift,
       T1.EMP_EmpID AS ID,
       EMP_LongName AS Name,
       EMP_Role AS Role,
       EMP_JobTitle AS Title,
       CASE
           WHEN EMP_Role = 'SUPERVISOR'
                AND
                (
                    EMP_JobTitle LIKE 'INBOUND%'
                    OR EMP_JobTitle LIKE 'OUTBOUND%'
                ) THEN
               'OTHER'
           WHEN EMP_Role = 'TRAINER'
                AND EMP_JobTitle LIKE 'OUTBOUND%' THEN
               'OTHER'
           WHEN EMP_JobTitle LIKE 'INBOUND%'
                OR EMP_JobTitle LIKE 'ASRS%' THEN
               SUBSTRING(EMP_JobTitle, 1, (CHARINDEX(' ', EMP_JobTitle + ' ') - 1))
           WHEN EMP_JobTitle LIKE 'OUTBOUND%' THEN
               SUBSTRING(EMP_JobTitle, 0, CHARINDEX(' ', EMP_JobTitle, CHARINDEX(' ', EMP_JobTitle, 0) + 1))
           WHEN EMP_JobTitle LIKE 'PROD SUPPORT ____ TRAYS%'
                OR EMP_JobTitle LIKE 'PROD SUPPORT TRAYS%' THEN
               'PROD SUPPORT TRAYS'
           WHEN EMP_JobTitle LIKE 'PROD SUPPORT ____ RACKS%'
                OR EMP_JobTitle LIKE 'PROD SUPPORT RACKS%' THEN
               'PROD SUPPORT RACKS'
           ELSE
               'OTHER'
       END AS STitle,
       BinNum,
       BinNum2,
       SUM(   CASE
                  WHEN dir = 'In' THEN
                      1
                  ELSE
                      0
              END
          ) AS ScanIn,
       SUM(   CASE
                  WHEN dir = 'Out' THEN
                      1
                  ELSE
                      0
              END
          ) AS ScanOut
FROM CTE1
    JOIN PRODDIST.dbo.Base_EMPBasic T1
        ON CTE1.EmpID = TRY_CONVERT(INT, T1.EMP_EmpID)
WHERE T1.EMP_EmpStatus = 'A'
GROUP BY YRWK,
         DATE,
         day,
         T1.EMP_ShiftDesc,
         T1.EMP_EmpID,
         EMP_LongName,
         EMP_Role,
         EMP_JobTitle,
         BinNum,
         BinNum2
ORDER BY DATE,
         ID,
		 BinNum,
		 BinNum2