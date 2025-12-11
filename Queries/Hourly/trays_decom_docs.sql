SELECT doc_name AS DocName,
       doc_desc AS Description,
       doc_date AS DATE,
       doc_scan_code,
       m_fg_platform AS Platform,
       m_fg_mach_type AS MatchType,
       OrderType
FROM ShopfloorN.dbo.reference_doc
WHERE YEAR(doc_date) >= YEAR(GETDATE()) - 2
      AND doc_type = 'WB'
ORDER BY doc_date DESC