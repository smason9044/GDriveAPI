SELECT
        pl_part_no,
        r_request_date,
        r_commit_date,
        r_due_date,
        r_qty_ord,
        r_qty_received,
        r_qty_due,
        r_status,
        p_po_no,
        p_site_code
    FROM MIMDISTN.dbo.PO_MMIMPurPlRel
    WHERE r_status = 'O'
      AND (im_description LIKE '%LOOPBACK%' OR pl_part_no IN ('30003314','30002973'))