REPORT zexample_inline.
TYPES: BEGIN OF ty_row,
         name TYPE string,
       END OF ty_row.
TYPES ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.
PARAMETERS p_factor TYPE i OBLIGATORY DEFAULT 1.
DATA(lv_json) = ``.
DATA(lv_label) = 'DATA(lv_json)'.
DATA(lt_rows) = VALUE ty_rows( ( name = `a` ) ( name = `b` ) ).
LOOP AT lt_rows INTO DATA(ls_row).
  lv_json = lv_json && ls_row-name.
ENDLOOP.
PERFORM show.

FORM show.
  DATA(lv_local) = |{ lv_label } { lv_json } { p_factor }|.
  WRITE lv_local.
ENDFORM.
