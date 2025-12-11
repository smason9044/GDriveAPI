DECLARE @query_hint VARCHAR(100)
DECLARE @EmpID INT

-- TODO: Set parameter values here.

EXECUTE ControlDB.dbo.Certification_GET @query_hint = 'MostRecentPass',
                                        @EmpID = NULL