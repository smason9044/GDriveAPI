DECLARE @query_hint varchar(100) = 'MostRecentCerts'
DECLARE @EmpID int = NULL

-- TODO: Set parameter values here.

EXECUTE ControlDB.[dbo].[Certification_GET] 
   @query_hint
  ,@EmpID