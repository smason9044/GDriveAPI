SELECT PlanGroup,
       GooCommCode,
       FormFactor,
       Platform,
       BasePartNum,
       Plant,
       STD_TTSecPerUnit,
       STD_TTMinPerUnit,
	   --CAST(STD_UnitsPerMin AS DECIMAL(10, 4)) as STD_UnitsPerMin1,
       STD_UnitsPerMin,
       HC_Assemblers,
       HC_MaterialHandlers,
       HC_TestDebug,
       HC_QA,
       HC_Boxing,
       HC_Lead,
       TOT_HC,
       AsmStage,
       PartDesc
FROM
(
    SELECT DISTINCT
           t2.PlanGroup,
           t2.G_FullCommCode AS GooCommCode,
           t2.FormFactor,
           t2.Platform,
           AsmBasePartNum,
           REPLACE(REPLACE(REPLACE(AsmBasePartNum, CHAR(13), ''), CHAR(10), ''), ' ', '') BasePartNum,
           [Plant],
           STD_TTSecPerUnit,
           STD_TTMinPerUnit,
           STD_UnitsPerMin,
           HC_Assemblers,
           HC_MaterialHandlers,
           HC_TestDebug,
           HC_QA,
           HC_Boxing,
           HC_Lead,
           (HC_Assemblers + HC_MaterialHandlers + HC_TestDebug + HC_QA + HC_Boxing + HC_Lead) AS TOT_HC,
           t2.MachType AS AsmStage,
           t2.PartDesc
    FROM
    (
        SELECT PEID,
               Plant,
               PartNo AS AsmBasePartNum,
               TaktTime,
               CASE
                   WHEN TaktTime != 0 THEN
                       TaktTime * 1.30
                   ELSE
                       0
               END AS STD_TTSecPerUnit,
               CASE
                   WHEN TaktTime != 0 THEN
                       TaktTime * 1.3 / 60.00
                   ELSE
                       0
               END AS STD_TTMinPerUnit,
               CASE
                   WHEN TaktTime != 0 THEN
                       60.00 / (TaktTime * 1.3)
                   ELSE
                       0
               END AS STD_UnitsPerMin,
               Assemblers AS HC_Assemblers,
               MaterialHandlers AS HC_MaterialHandlers,
               TestDebug AS HC_TestDebug,
               QA AS HC_QA,
               Boxing AS HC_Boxing,
               Lead AS HC_Lead,
               Notes,
               CreateDate,
               LastModifiedDate,
               Link
        FROM ProcessDetails.dbo.ProcessTheoreticalValues
    ) t
        LEFT JOIN MIMDISTN.dbo.part_info t2
            ON AsmBasePartNum = t2.MIMPartNum
) t1
ORDER BY Plant,
         PlanGroup,
         GooCommCode,
         FormFactor