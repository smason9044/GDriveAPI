 SELECT CreatedOn,
               LastModifiedOn,
               EmpID,
               B.EMP_LongName,
               B.EMP_JobTitle,
               B.EMP_Agency,
               B.EMP_Dept,
               CASE
                   WHEN CHARINDEX(' ', B.EMP_JobTitle) > 0 THEN
                       LEFT(B.EMP_JobTitle, CHARINDEX(' ', B.EMP_JobTitle) - 1)
                   ELSE
                       B.EMP_JobTitle
               END AS Edited_Dept,
               B.EMP_ShiftDesc,
               E.ViolationType,
               C.ViolationDate,
               C.ViolationDetails,
               D.ViolationSummary,
               F.RecomndOutcome,
               A.RecomndAction,
               G.CorrActStatus
        FROM [CorrAct].[dbo].[CorrAction] A
            JOIN PRODDIST.dbo.Base_EMPBasic B
                ON A.EmpID = TRY_CONVERT(INT, B.EMP_EmpID)
            JOIN CorrAct.dbo.ViolationDetails C
                ON A.CorrActID = C.CorrActID
            JOIN CorrAct.dbo.ViolationSummary D
                ON C.ViolationSummaryID = D.ViolationSummaryID
            JOIN CorrAct.dbo.ViolationType E
                ON D.ViolationTypeID = E.ViolationTypeID
            JOIN CorrAct.dbo.RecomndOutcome F
                ON A.RecomndOutcomeID = F.RecomndOutcomeID
            JOIN CorrAct.dbo.CorrActStatus G
                ON A.CorrActStatusID = G.CorrActStatusID
        WHERE EMP_EmpStatusDesc = 'ACTIVE'
              AND IsDeleted = 0
              AND IsActive = 1
              AND COALESCE(LastModifiedOn, CreatedOn) >= DATEADD(MONTH, -6, CAST(GETDATE() AS DATE))
        ORDER BY CreatedOn DESC