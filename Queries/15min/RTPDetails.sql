SELECT 
       "RPT_RTPSequence_C"."PartNum",
       "RPT_RTPSequence_C"."SchedQty",
       "RPT_RTPSequence_C"."AsmMachType",
       --"RPT_RTPSequence_C"."NPIFlag",
       --"RPT_RTPSequence_C"."FAFlag",
       --"RPT_RTPSequence_C"."Plant",
       --"RPT_RTPSequence_C"."BP_Comitted",
       "RPT_RTPSequence_C"."LineAsn",
       "RPT_RTPSequence_C"."SFBoxedQty",
       --"RPT_RTPSequence_C"."AsmFormFactor",
       "RPT_RTPSequence_C"."PlatFormGroup",
       --"RPT_RTPSequence_C"."PlatFormPart",
       "RPT_RTPSequence_C"."AsmPlatform",
       "RPT_RTPSequence_C"."AsmStartQty",
       --"RPT_RTPSequence_C"."BP_CommitStage",
       --"RPT_RTPSequence_C"."AsmLineType",
       --"RPT_RTPSequence_C"."WIPBin",
       "RPT_RTPSequence_C"."RTx",
       "RPT_RTPSequence_C"."SML_ActionedQty",
       "RPT_RTPSequence_C"."SMHrsRoom",
       "RPT_RTPSequence_C"."CLR_CLearFlag",
       "RPT_RTPSequence_C"."LineOrder",
       "RPT_RTPSequence_C"."UnitsPerHr",
       "RPT_RTPSequence_C"."RTPDateLT",
       CASE
           WHEN RPT_RTPSequence_C.CLR_CLearFlag = 0
                AND RPT_RTPSequence_C.RTx = 'RTP' THEN
               'CLEAR TO RELEASE TO FLOOR'
           WHEN RPT_RTPSequence_C.CLR_CLearFlag = 1
                AND RPT_RTPSequence_C.RTx = 'RTP' THEN
               'NOT CLEAR TO RELEASE'
           ELSE
               ''
       END AS ClearFlag,
	   "RPT_RTPSequence_C"."ProdNo",
       RPT_RTPSequence_C.AsmPlanGroup
FROM "MIMDISTN"."dbo"."RPT_RTPSequence_C" "RPT_RTPSequence_C"
WHERE "RPT_RTPSequence_C"."Plant" = 'FB'