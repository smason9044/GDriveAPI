SELECT YRWK,
       Day,
       EMP_ShiftDesc,
       WareHouseCode,
       BinNum,
       WareHouse2,
       BinNum2,
       EmpID,
       EMP_LongName,
       Edited_Title,
       Count
FROM PRODDIST.[dbo].[PalletCount2weeks]
ORDER BY YRWK,
         day,
         EMP_ShiftDesc