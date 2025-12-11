SELECT EMP_empID,
       EMP_LongName,
       EMP_ShiftDesc,
       EMP_ExpenseType,
       EMP_Dept,
       EMP_JobTitle,
       EMP_Agency,
       OccurrenceHandling_,
       a.OccurrenceHandlingPoints,
       FORMAT(a.DATE, 'yyyy-MM-dd') AS DATE,
       Status,
       RPTMaster_SupvAssign.SupName,
       RPTMaster_SupvAssign.SupRole
FROM TimeClock.dbo.OccurrencesView a
    LEFT OUTER JOIN TimeClock.dbo.RPTMaster_SupvAssign
        ON a.EMP_EmpID = RPTMaster_SupvAssign.EmpID
ORDER BY EMP_empID,
         DATE