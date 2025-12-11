SELECT *,
       CASE
           WHEN Day IN ( 5, 6, 7 ) THEN
               'SHIFT WE'
           ELSE
               ShiftNo
       END AS UpdatedShift,
       CASE
           WHEN LEFT(Dept, CHARINDEX(' ', Dept + ' ') - 1) = 'RACKS' THEN
               'RACK-ASM'
           WHEN LEFT(Dept, CHARINDEX(' ', Dept + ' ') - 1) = 'TRAYS' THEN
               'TRAY-ASM'
           ELSE
               LEFT(Dept, CHARINDEX(' ', Dept + ' ') - 1)
       END AS PlanGroup,
       CASE
           WHEN (
                    Dept LIKE 'RACK%'
                    OR Dept LIKE 'TRAY%'
                )
                AND CHARINDEX(' ', Dept) > 0 THEN
               RIGHT(Dept, LEN(Dept) - CHARINDEX(' ', Dept))
           ELSE
               ''
       END AS MachType
FROM TimeClock.dbo.DeptHrs11Weeks