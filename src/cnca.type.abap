TYPE-POOL cnca.

TYPES cnca_utc_date TYPE c LENGTH 8.
TYPES cnca_format TYPE c LENGTH 80.

CONSTANTS cnca_sel_day TYPE i VALUE 1.
CONSTANTS cnca_sel_week TYPE i VALUE 2.
CONSTANTS cnca_sel_month TYPE i VALUE 4.
CONSTANTS cnca_sel_interval TYPE i VALUE 8.

TYPES: BEGIN OF cnca_s_selection,
         date_begin TYPE cnca_utc_date,
         date_end   TYPE cnca_utc_date,
       END OF cnca_s_selection.
TYPES cnca_itab_selection TYPE STANDARD TABLE OF cnca_s_selection WITH DEFAULT KEY.

TYPES: BEGIN OF cnca_s_day_info,
         date  TYPE d,
         color TYPE i,
         text  TYPE c LENGTH 80,
       END OF cnca_s_day_info.
TYPES cnca_itab_day_info TYPE STANDARD TABLE OF cnca_s_day_info WITH DEFAULT KEY.
