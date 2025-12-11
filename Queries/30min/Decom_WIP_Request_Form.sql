SELECT --"RPT_DecomWipRequest"."WorkCenter",
       "RPT_DecomWipRequest"."PartNum",
	   "RPT_DecomWipRequest"."Plant",
	   "RPT_DecomWipRequest"."Quantity",
       "RPT_DecomWipRequest"."PalletCount",
       "RPT_DecomWipRequest"."PlanGroup",
       "RPT_DecomWipRequest"."FormFactor",
       "RPT_DecomWipRequest"."Platform",
       "RPT_DecomWipRequest"."AsmType"
FROM "PRODDIST"."dbo"."RPT_DecomWipRequest" "RPT_DecomWipRequest"
WHERE "RPT_DecomWipRequest"."Plant" = N'FB'