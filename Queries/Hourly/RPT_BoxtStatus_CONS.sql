SELECT --CONVERT(DATE, CreateDate) AS DATE,
	   format(CreateDate,'yyyy-MM-dd') as Date,
       CreateDate,
       BoxID,
       BoxName,
       BoxStatusDesc,
       BoxSource,
       BoxType,
       GooPartNum,
       BoxQty,
       Disposition,
       EmpID,
       EMPShortName,
       CONVERT(VARCHAR, YEAR(DATEADD(wk, DATEDIFF(d, 0, CreateDate) / 7, 3))) AS Year,
       DATENAME(month, createdate) AS Month,
       CONVERT(VARCHAR, YEAR(DATEADD(wk, DATEDIFF(d, 0, CreateDate) / 7, 3))) + 'W'
       + REPLICATE('0', 2 - LEN(DATEPART(ISO_WEEK, CreateDate))) + CONVERT(VARCHAR, DATEPART(ISO_WEEK, CreateDate)) YRWK,
       REPLICATE('0',
                 2 - LEN(   CASE
                                WHEN DATEPART(weekday, CreateDate) = 1 THEN
                                    7
                                ELSE
                                    DATEPART(weekday, CreateDate) - 1
                            END
                        )
                ) + CAST(CASE
                             WHEN DATEPART(weekday, CreateDate) = 1 THEN
                                 7
                             ELSE
                                 DATEPART(weekday, CreateDate) - 1
                         END AS VARCHAR) AS Day
FROM PRODDIST.dbo.RPT_BoxtStatus_CONS
WHERE BoxStatus = 'C'
      AND CONVERT(DATE, CreateDate) >= '2025-11-04'