SELECT DISTINCT
       FORMAT(DATE, 'yyyy-MM-dd') as Date,
       YRWK,
       Day,
       EmpID,
       LongName,
       Agency,
       ExpenseType,
       Dept,
       SUM(RoundedHoursWorked) OVER (PARTITION BY DATE,
                                                  YRWK,
                                                  Day,
                                                  EmpID,
                                                  LongName,
                                                  ShiftNo,
                                                  Agency,
                                                  ExpenseType,
                                                  Dept
                                     ORDER BY DATE
                                    ) AS workedHrs
FROM TimeClock.dbo.RPTMaster_DailyHours
WHERE ([DATE]
      BETWEEN DATEADD(day, -7, GETDATE()) AND DATEADD(day, 0, GETDATE())
      )
      AND Day IN ( 5, 6, 7 )
      AND PayRateType = 'H'
      AND COALESCE(ActualHoursWorked, RoundedHoursWorked) != 0.00
