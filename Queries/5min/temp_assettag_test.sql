SELECT A.asset_tag_num,
       A.slot_num,
       A.m_form_factor,
       A.current_test,
       A.new_status,
       A.result,
       A.create_date,
       A.rack_name,
       A.end_time,
       A.symptons,
       A.test_error,
       a.test_step,
       A.test_station_id,
       A.disposition,
       A.turn,
       A.level,
       A.action,
       A.comment,
       A.debug_suggestion_auto_id,
       A.start_time,
       A.who,
       A.firstFailureSymptom,
       A.green_slot_num,
       C.AsmPlatform
FROM ShopFloorN.dbo.temp_asset_tag_test A
    LEFT JOIN ShopFloorN.dbo.asset_tag_gen B
        ON A.asset_tag_num = B.asset_tag_num
           AND A.plant = B.plant
    LEFT JOIN ShopFloorN.dbo.SFOrderView C
        ON B.work_order_num = C.WorkOrdNum
           AND B.plant = C.Plant
WHERE A.plant = 'FB'
      AND create_date >= GETDATE() - 30
ORDER BY create_date


