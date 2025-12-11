SELECT YRWK,
       Agency,
       Dept,
       ShiftNo,
       EmpID,
       FirstName,
       LastName,
       JobTitle,
       HoursWorked,
       MAX(daysworked) AS Daysworked
FROM
(
    SELECT YRWK,
           Agency,
           Dept,
           ShiftNo,
           EmpID,
           FirstName,
           LastName,
           JobTitle,
           ROW_NUMBER() OVER (partition BY EmpID, YRWK ORDER BY YRWK, Day DESC) AS daysworked,
           SUM(RoundedHoursWorked) OVER (PARTITION BY YRWK, EmpID) AS HoursWorked
    FROM TimeClock.dbo.RPTMaster_DailyHours
    WHERE Paid = 1
          AND CategoryCode = 1001
          AND RoundedHoursWorked != 0
          AND PayRateType != 'S'
          AND DATE
          BETWEEN CONVERT(DATE, CONVERT(DATETIME, DATEDIFF(day, 7, GETDATE() - DATEDIFF(day, 0, GETDATE()) % 7))) AND CONVERT(
                                                                                                                                 DATE,
                                                                                                                                 CONVERT(
                                                                                                                                            DATETIME,
                                                                                                                                            DATEDIFF(
                                                                                                                                                        day,
                                                                                                                                                        -7,
                                                                                                                                                        GETDATE()
                                                                                                                                                        - DATEDIFF(
                                                                                                                                                                      day,
                                                                                                                                                                      0,
                                                                                                                                                                      GETDATE()
                                                                                                                                                                  )
                                                                                                                                                        % 7
                                                                                                                                                    )
                                                                                                                                        )
                                                                                                                             )
) t1
GROUP BY YRWK,
         Agency,
         Dept,
         ShiftNo,
         EmpID,
         FirstName,
         LastName,
         JobTitle,
         HoursWorked
ORDER BY HoursWorked DESC