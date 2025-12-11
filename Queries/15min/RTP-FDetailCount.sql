SELECT "RPT_RTFSequence_B"."ProdNo",
       "RPT_RTFSequence_B"."PartNum",
       "RPT_RTFSequence_B"."SchedQty",
       "RPT_RTFSequence_B"."AsmMachType",
       "RPT_RTFSequence_B"."CTBDate",
       "RPT_RTFSequence_B"."NPIFlag",
       "RPT_RTFSequence_B"."FAFlag",
       "RPT_RTFSequence_B"."Plant",
       "RPT_RTFSequence_B"."BP_Comitted",
       "RPT_RTFSequence_B"."LineAsn",
       "RPT_RTFSequence_B"."SFC",
       "RPT_RTFSequence_B"."SFBoxedQty",
       "RPT_RTFSequence_B"."AsmFormFactor",
       "RPT_RTFSequence_B"."PlatFormGroup",
       "RPT_RTFSequence_B"."PlatFormPart",
       "RPT_RTFSequence_B"."SeqNum",
       "RPT_RTFSequence_B"."AsmPlatform",
       "RPT_RTFSequence_B"."RTFSFCDate",
       "RPT_RTFSequence_B"."SML_ActionedQty",
       "RPT_RTFSequence_B"."AsmStartQty",
       SUM("RPT_RTFSequence_B"."AsmStartQty") OVER (PARTITION BY "RPT_RTFSequence_B"."PartNum",
                                                                 "RPT_RTFSequence_B"."PlatFormGroup",
                                                                 "RPT_RTFSequence_B"."AsmMachType",
                                                                 "RPT_RTFSequence_B"."SFAsmLine",
                                                                 "RPT_RTFSequence_B"."PlatFormPart"
                                                    ORDER BY "RPT_RTFSequence_B"."PartNum"
                                                   ) AS Count,
       "RPT_RTFSequence_B"."SFAsmLine",
       "RPT_RTFSequence_B"."SML_Order",
       "RPT_RTFSequence_B"."SML_ClearFlag",
       "RPT_RTFSequence_B"."ProdStatus",
       "RPT_RTFSequence_B"."STDTackTimeSec",
       "RPT_RTFSequence_B"."BP_CommitStage",
       "RPT_RTFSequence_B"."AsmLineType",
       "RPT_RTFSequence_B"."WIPBin",
       "RPT_RTFSequence_B"."SMHrsAsmLine",
       "RPT_RTFSequence_B"."AsmSchedQty",
       "RPT_RTFSequence_B"."SkuCode"
FROM "MIMDISTN"."dbo"."RPT_RTFSequence_B" "RPT_RTFSequence_B"
WHERE "RPT_RTFSequence_B"."Plant" = 'FB'
      AND "RPT_RTFSequence_B"."AsmPlanGroup" LIKE '%RACK%'
      AND "RPT_RTFSequence_B"."ProdStatus" != 'S'
      AND NOT (
                  "RPT_RTFSequence_B"."PartNum" = '1063474-01'
                  OR "RPT_RTFSequence_B"."PartNum" = '1063475-01'
                  OR "RPT_RTFSequence_B"."PartNum" = '1112451-02'
                  OR "RPT_RTFSequence_B"."PartNum" = '1114424'
              )
      AND NOT (
                  "RPT_RTFSequence_B"."ProdNo" = 918924
                  OR "RPT_RTFSequence_B"."ProdNo" = 934128
                  OR "RPT_RTFSequence_B"."ProdNo" = 1062220
                  OR "RPT_RTFSequence_B"."ProdNo" = 1062221
                  OR "RPT_RTFSequence_B"."ProdNo" = 1062222
                  OR "RPT_RTFSequence_B"."ProdNo" = 1062223
              )
      AND RPT_RTFSequence_B.SFC = 'Y' ---and "RPT_RTFSequence_B"."PartNum" ='1148813'
