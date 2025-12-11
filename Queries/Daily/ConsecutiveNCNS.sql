SELECT EmpID,
       EMP_LongName,
       EMP_ShiftDesc,
       EMP_ExpenseType,
       EMP_Dept,
       EMP_JobTitle,
       YRWK,
       ConsDays,
       CONVERT(DATE, LastSeen) AS date,
	   EMP_Agency
FROM TimeClock.dbo.NCNS
ORDER BY EMP_ExpenseType,
         EmpID,
         EMP_LongName

