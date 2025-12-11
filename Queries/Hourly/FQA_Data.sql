SET NOCOUNT ON;
SELECT 
       ISNULL(A.Plant, B.Plant) AS Plant,
       ISNULL(A.YRWK, 'No Data') AS YRWK,
       TrandateShift,
       AssetTagNum,
       TLAPartNumber,
       WorkOrderNum,
       PlanGroup,
       Platform,
       PlatformUpdated,
       MachType,
       DATE,
       QAStatus,
       QAOperator,
       EMP_ShiftDesc,
       --TestStep,
       test_error,
       --DebugOperator,
       DebugAction,
       DefectPartLoc,
       DefectPartNum,
       DefectSerialNum,
       ISNULL(lineAssign, B.lineAssigned) AS LineAssign,
       TestCount,
       BOXYRWK,
       --PlatformUpdated,
       --TrandateShift,
       DebugActionUpdated,
       PartLoc,
       FQAYRWKDY,
       Day,notes
FROM
(
    SELECT DISTINCT
           Plant,
           lineAssign AS lineAssigned,
           CONCAT(DATEPART(YEAR, GETDATE()), 'W', RIGHT('0' + CAST(DATEPART(ISO_WEEK, GETDATE()) AS VARCHAR), 2)) AS YRWK
    FROM ShopFloorN.dbo.[order]
    WHERE lineAssign IN ( 'A11', 'A10', 'A12', 'A13', 'A08' )
) B
    FULL OUTER JOIN
    (
        SELECT *,
               CASE
                   WHEN Platform LIKE 'ARCADIA%' THEN
                       'ARCADIA'
                   WHEN Platform LIKE 'INDUS-C%' THEN
                       'INDUS-C'
                   WHEN Platform LIKE 'RACKBACK%' THEN
                       'RACKBACK'
                   WHEN Platform LIKE 'FLATBACK%' THEN
                       'FLATBACK'
                   WHEN Platform LIKE 'BIJLEE%' THEN
                       'BIJLEE'
                   WHEN Platform LIKE 'MACTRUCK%' THEN
                       'MACTRUCK'
                   WHEN Platform LIKE 'ICEBLINK%' THEN
                       'ICEBLINK'
                   WHEN Platform LIKE 'ABERDEEN%' THEN
                       'ABERDEEN'
                   WHEN Platform LIKE 'INTERLAKEN%' THEN
                       'INTERLAKEN'
                   WHEN Platform LIKE 'DRAGONFISH%' THEN
                       'DRAGONFISH'
                   WHEN Platform LIKE 'INDUS-S%' THEN
                       'INDUS-S'
                   WHEN Platform LIKE 'JELLYDONUT%' THEN
                       'JELLYDONUT'
                   WHEN Platform LIKE 'JELLYFISH%' THEN
                       'JELLYFISH'
                   WHEN Platform LIKE 'IXION%' THEN
                       'IXION'
                   ELSE
                       Platform
               END AS PlatformUpdated,
               CASE
                   WHEN DATENAME(weekday, DATE) IN ( 'Friday', 'Saturday', 'Sunday' ) THEN
                       'SHIFT WE'
                   WHEN DATEPART(hour, DATE) >= 0
                        AND DATEPART(hour, DATE) < 4 THEN
                       'SHIFT 2'
                   WHEN DATEPART(hour, DATE) >= 4
                        AND DATEPART(hour, DATE) < 16 THEN
                       'SHIFT 1'
                   WHEN DATEPART(hour, DATE) >= 16 THEN
                       'SHIFT 2'
               END AS TrandateShift,
               CASE
                   WHEN DebugAction LIKE '%ASSEMBLY-OPERATOR-ERROR%' THEN
                       'ASSEMBLY-OPERATOR-ERROR'
                   WHEN DebugAction LIKE '%TEST-OPERATOR-ERROR%' THEN
                       'TEST-OPERATOR-ERROR'
                   ELSE
                       DebugAction
               END AS DebugActionUpdated,
               CASE
                   WHEN DefectPartLoc LIKE '%BIOS%' THEN
                       'BIOS'
                   WHEN DefectPartLoc LIKE '%BMC%' THEN
                       'BMC'
                   WHEN DefectPartLoc LIKE '%CPU%' THEN
                       'CPU'
                   WHEN DefectPartLoc LIKE '%DIMM%' THEN
                       'DIMM'
                   WHEN DefectPartLoc LIKE '%FAN%' THEN
                       'FAN'
                   WHEN DefectPartLoc LIKE '%HEATSINK%' THEN
                       'HEATSINK'
                   WHEN DefectPartLoc LIKE '%I2COOL%' THEN
                       'I2COOL'
                   WHEN DefectPartLoc LIKE '%NCSI%' THEN
                       'NCSI'
                   WHEN DefectPartLoc LIKE '%PE%' THEN
                       'PE'
                   WHEN DefectPartLoc LIKE '%CSSD%' THEN
                       'CSSD'
                   WHEN DefectPartLoc LIKE '%TANG%' THEN
                       'TANG'
                   WHEN DefectPartLoc LIKE '%KA%' THEN
                       'KA'
                   WHEN DefectPartLoc LIKE '%HDD%' THEN
                       'HDD'
                   WHEN DefectPartLoc LIKE '%SATA%' THEN
                       'SATA'
                   WHEN DefectPartLoc LIKE '%PWR%' THEN
                       'PWR'
                   WHEN DefectPartLoc LIKE '%MOBO%' THEN
                       'MOBO'
                   WHEN DefectPartLoc LIKE '%PCBA%' THEN
                       'PCBA'
                   WHEN DefectPartLoc LIKE '%PSU%' THEN
                       'PSU'
                   WHEN DefectPartLoc LIKE '%THERMAL%' THEN
                       'THERMAL'
                   WHEN DefectPartLoc LIKE '%RISER%' THEN
                       'RISER'
                   WHEN DefectPartLoc LIKE '%LUFTIG%' THEN
                       'LUFTIG'
                   WHEN DefectPartLoc LIKE '%KOOL_AID%' THEN
                       'KOOLAID'
                   WHEN DefectPartLoc LIKE '%MAIN_BOARD%' THEN
                       'MAIN BOARD'
                   WHEN DefectPartLoc LIKE '%PCIE%' THEN
                       'PCIE'
                   WHEN DefectPartLoc LIKE '%STELE_CABLE%' THEN
                       'STELE_CABLE'
                   WHEN DefectPartLoc LIKE '%SSD%' THEN
                       'SSD'
                   WHEN DefectPartLoc LIKE '%QSFP%' THEN
                       'QSFP'
                   WHEN DefectPartLoc LIKE '%CAT5%' THEN
                       'CAT5'
                   WHEN DefectPartLoc LIKE '%LOOPBACK%' THEN
                       'LOOPBACK'
                   WHEN DefectPartLoc LIKE '%CDFP%' THEN
                       'CDFP'
                   ELSE
                       DefectPartLoc
               END AS PartLoc,
               CONVERT(VARCHAR, YEAR(DATEADD(wk, DATEDIFF(d, 0, DATE) / 7, 3))) + 'W'
               + REPLICATE('0', 2 - LEN(DATEPART(ISO_WEEK, DATE))) + CONVERT(VARCHAR, DATEPART(ISO_WEEK, DATE)) + 'D'
               + REPLICATE('0',
                           2 - LEN(   CASE
                                          WHEN DATEPART(weekday, DATE) = 1 THEN
                                              7
                                          ELSE
                                              DATEPART(weekday, DATE) - 1
                                      END
                                  )
                          ) + CAST(CASE
                                       WHEN DATEPART(weekday, DATE) = 1 THEN
                                           7
                                       ELSE
                                           DATEPART(weekday, DATE) - 1
                                   END AS VARCHAR) AS FQAYRWKDY,
               REPLICATE('0',
                         2 - LEN(   CASE
                                        WHEN DATEPART(weekday, DATE) = 1 THEN
                                            7
                                        ELSE
                                            DATEPART(weekday, DATE) - 1
                                    END
                                )
                        ) + CAST(CASE
                                     WHEN DATEPART(weekday, DATE) = 1 THEN
                                         7
                                     ELSE
                                         DATEPART(weekday, DATE) - 1
                                 END AS VARCHAR) AS Day
        FROM ShopFloorN.[dbo].[RPT_FQAData]
        /*WHERE PlanGroup = 'TRAY-ASM' 
              AND MachType = 'VANILLA'*/
    ---AND plant = 'FB' --and MONTH(Date)=MONTH(GETDATE())
    ) A
        ON --A.yrwk=b.YRWK AND
        A.lineAssign = B.lineAssigned
OPTION (RECOMPILE);
--where MONTH(Date)=MONTH(GETDATE())
--ORDER BY [Date]