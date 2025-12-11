SELECT distinct B.EMP_EmpID as EmpID,B.EMP_LongName as Name,B.EMP_Dept as Dept,B.EMP_Role as Role,B.EMP_JobTitle as JobTitle,
B.EMP_PayRateType as PayRateType, B.EMP_ExpenseType as ExpenseType,B.EMP_ShiftDesc,D.SupName as Manager,D.SupRole as ManagerRole,CategoryName as 'Off',StartDate as PTO_Date
  FROM [TimeClock].[dbo].[TORequest] A
  join PRODDIST.dbo.Base_EMPBasic B on try_convert(varchar,A.EmpID) = B.EMP_EmpID
  join TimeClock.dbo.PayCategories C on A.PCID = C.PCID
  left join RPTMaster_SupvAssign D on try_convert(varchar,A.EmpID) = D.EmpID
  where StartDate between convert(date,GETDATE()+1) and convert(date,GETDATE() + 30)
  and EMP_PayrolExempt != 'Y' and CategoryCode != 0 and EMP_EmpStatusDesc = ('ACTIVE') and EMP_Plant = 'FB'
  order by StartDate,EMP_EmpID