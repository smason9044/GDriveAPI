SELECT AuditArea,
       RedRabbitDescription AS Description,
       AssetTagNumber AS AssetTagNum,
       Status,
       Active,
       Line,
       LeadID,
       QAAuditorID,
       QAOperID,
       EMP_LongName AS QAOperLongName,
       EMP_ShiftDesc AS QAOperShiftDesc,
       TestStep,
       AsmPartNum AS BasePartNum,
       AsmPlatform AS Platform,
       RR_CreateDate AS CreateDate,
       YRWK,
       BreakDown,
       AsmPlanGroup AS PlanGroup
FROM
(
    SELECT DISTINCT
           Plant,
           ObjectID,
           AuditArea,
           CASE
               WHEN AuditArea LIKE '%CERT%' THEN
                   ROW_NUMBER() OVER (PARTITION BY QAOperID, AuditArea ORDER BY RR_CreateDate DESC)
               ELSE
                   0
           END AS rownum,
           RedRabbitDescription,
           AssetTagNumber,
           Status,
           Active,
           Line,
           LeadID,
           QAAuditorID,
           QAOperID,
           Base_EMPBasic.EMP_LongName,
           Base_EMPBasic.EMP_JobTitle,
           Base_EMPBasic.EMP_ShiftDesc,
           Room,
           TestStep,
           WorkOrdNum,
           AsmPartNum,
           AsmPlanGroup,
           AsmMachType,
           AsmPlatform,
           RR_CreateDate,
           YRWK,
           RR_LastStatusUpdDate,
           LEFT(LTRIM(EMP_JobTitle), COALESCE(NULLIF(CHARINDEX(' ', LTRIM(EMP_JobTitle)), 0) - 1, LEN(LTRIM(EMP_JobTitle)))) AS BreakDown
    --SUBSTRING(EMP_JobTitle, 1, CHARINDEX(' ', EMP_JobTitle) - 1) AS BreakDown
    --case when LEFT(EMP_JobTitle,1) = 'N' then 'NTLA' else 'RTLA' end as BreakDown
    FROM [CMMS].[dbo].[RedRabbitReport]
        JOIN PRODDIST.dbo.Base_EMPBasic
            ON Base_EMPBasic.EMP_EmpID = RedRabbitReport.QAOperID
    WHERE (
              (
                  AuditArea LIKE '%CERT%'
                  AND CONVERT(DATE, RR_CreateDate) > '2023-05-01'
              )
              OR
              (
                  AuditArea NOT LIKE '%CERT%'
                  AND CONVERT(DATE, RR_CreateDate) > CONVERT(DATE, GETDATE() - 365)
              )
          )
          AND RedRabbitReport.[Status] != 'CANCEL'
          AND Base_EMPBasic.EMP_EmpStatusDesc = 'ACTIVE'
) t1
--and QAOperID = '123231' and AuditArea like '%CERT%'
WHERE rownum < 6
ORDER BY RR_CreateDate DESC


/*select *
from (SELECT distinct [Plant]
      ,[ObjectID]
      ,[AuditArea]
      ,case when AuditArea like '%CERT%' then ROW_NUMBER() OVER (PARTITION BY QAOperID,AuditArea order by RR_CreateDate desc) else 0 end as rownum
      ,[RedRabbitDescription]
      ,[AssetTagNumber]
      ,[Status]
      ,[Active]
      ,[Line]
      ,[LeadID]
      ,[QAAuditorID],QAOperID,Base_EMPBasic.EMP_LongName,Base_EMPBasic.EMP_JobTitle,Base_EMPBasic.EMP_ShiftDesc
      ,[Room]
      ,[TestStep]
      ,[WorkOrdNum]
      ,[AsmPartNum]
      ,[AsmPlanGroup]
      ,[AsmMachType]
      ,[AsmPlatform]
      ,[RR_CreateDate]
      ,[YRWK]
      ,[RR_LastStatusUpdDate],case when LEFT(EMP_JobTitle,1) = 'N' then 'NTLA' else 'RTLA' end as BreakDown
FROM [CMMS].[dbo].[RedRabbitReport]
join PRODDIST.dbo.Base_EMPBasic on Base_EMPBasic.EMP_EmpID =RedRabbitReport.QAOperID
where /* convert(date,RR_CreateDate)>convert(date,GETDATE()-365) and */RedRabbitReport.[Status] !='CANCEL' and Base_EMPBasic.EMP_EmpStatusDesc = 'ACTIVE') t1
--and QAOperID = '123231' and AuditArea like '%CERT%'
where rownum < 6
order by RR_CreateDate desc */


