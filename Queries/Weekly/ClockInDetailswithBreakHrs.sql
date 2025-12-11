SELECT A.YRWK,
       A.Day,
       UserID as EmpID,
       EMP_LongName,
       --EMP_Role,
       EMP_Dept,
       --EMP_ReportsTo,
       A.ShiftInTime,
       COALESCE(c.ModShiftInTime, C.ShiftInTime) AS SchShiftInTime,
       A.BreakOutTime,
       A.BreakInTime,
       A.ShiftOutTime,
       COALESCE(c.ModShiftoutTime, C.ShiftOutTime) AS SchShiftOutTime,
       BreakHrs, BreakHrs * 60 as Mins_On_Break,
       EMP_Agency,D.SupName
       --Deleted
FROM TimeClock.dbo.ClockMaster_Details A
    LEFT JOIN PRODDIST.DBO.Base_EMPBasic B
        ON A.UserID = TRY_CAST(B.EMP_EmpID AS INT)
    LEFT JOIN TimeClock.dbo.ActualSchedule C
        ON A.UserID = C.EmpID
           AND a.YRWK = c.YRWK
           AND a.Day = c.day
    Left Join TimeClock.dbo.RPTMaster_SupAssign_ALL D on TRY_CAST(D.EmpID AS INT) = A.UserID
WHERE A.YRWK BETWEEN CONCAT(
  YEAR(DATEADD(day, 4 - DATEPART(weekday, DATEADD(week,-3, GETDATE())),
                    DATEADD(week,-1, GETDATE()))),
  'W',
  RIGHT('0' + CAST(DATEPART(isowk, DATEADD(week,-3, GETDATE())) AS varchar(2)), 2)
) and CONCAT(
  YEAR(DATEADD(day, 4 - DATEPART(weekday, DATEADD(week,-1, GETDATE())),
                    DATEADD(week,-1, GETDATE()))),
  'W',
  RIGHT('0' + CAST(DATEPART(isowk, DATEADD(week,-1, GETDATE())) AS varchar(2)), 2)
)
      AND BreakHrs > 0
      AND c.SeqNo = 1 --and UserID ='115381' 
	  --and A.YRWK = '2025W43'
ORDER BY A.YRWK desc, a.UserID,
         day asc