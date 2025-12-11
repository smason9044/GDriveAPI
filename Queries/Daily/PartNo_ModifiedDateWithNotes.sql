SELECT Plant,
       PartNo,
       LastModifiedDate,
       LTRIM(RTRIM(REPLACE(
                              REPLACE(
                                         REPLACE(REPLACE(REPLACE(Notes, '  ', ''), CHAR(10), ' '), CHAR(13), ' '),
                                         CHAR(9),
                                         ' '
                                     ),
                              CHAR(160),
                              ' '
                          )
                  )
            ) AS Notes,
       PlanGroup,
       MachType
FROM ProcessDetails.dbo.ProcessTheoreticalValues A
    LEFT JOIN MIMDISTN.dbo.part_info B
        ON A.PartNo = B.MIMPartNum
ORDER BY Plant,
         LastModifiedDate