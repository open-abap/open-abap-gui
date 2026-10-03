REPORT zgg_ex_074.

TABLES zsflight.

TYPES: BEGIN OF ty_carrier,
         carrid TYPE c LENGTH 3,
       END OF ty_carrier.

DATA gt_carriers TYPE STANDARD TABLE OF ty_carrier WITH DEFAULT KEY.
DATA gt_return TYPE STANDARD TABLE OF ddshretval WITH DEFAULT KEY.

SELECT-OPTIONS s_mul FOR zsflight-carrid NO-EXTENSION.
PARAMETERS p_req TYPE c LENGTH 20 OBLIGATORY.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_mul-low.
  gt_carriers = VALUE #( ( carrid = 'AA' ) ( carrid = 'LH' ) ( carrid = 'SQ' ) ).
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CARRID'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'S_MUL-LOW'
      value_org       = 'S'
      multiple_choice = 'X'
    TABLES
      value_tab       = gt_carriers
      return_tab      = gt_return.
  CLEAR s_mul[].
  LOOP AT gt_return INTO DATA(ls_return).
    APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_return-fieldval ) TO s_mul.
  ENDLOOP.

START-OF-SELECTION.
  LOOP AT s_mul.
    WRITE: / s_mul-sign, s_mul-option, s_mul-low, s_mul-high.
  ENDLOOP.
