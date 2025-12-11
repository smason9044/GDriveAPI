SELECT EmployeeID AS Badge,
       EMP_LongName AS Name,
       EMP_ExpenseType AS PayType,
       EMP_ShiftDesc AS Shift,
       EMP_JobTitle AS Title,
       Description,
       DateSubmitted
FROM TimeClock.dbo.OpenTermRequest
