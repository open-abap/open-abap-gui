REPORT zgg_ex_186.

* A parameter declared without a type is c of length 1.

PARAMETERS p_flag NO-DISPLAY.

FORM show USING iv_flag TYPE abap_bool.
  WRITE / iv_flag.
ENDFORM.

START-OF-SELECTION.
  p_flag = abap_true.
  PERFORM show USING p_flag.
