REPORT zexample_selection.

TABLES sflight.

PARAMETERS: p_count  TYPE i DEFAULT 5,
            p_date   TYPE d,
            p_amount TYPE p LENGTH 8 DECIMALS 2,
            p_name   TYPE c LENGTH 20 LOWER CASE,
            p_flag   AS CHECKBOX DEFAULT 'X',
            p_opt1   RADIOBUTTON GROUP grp DEFAULT 'X',
            p_opt2   RADIOBUTTON GROUP grp.

SELECT-OPTIONS s_carr FOR sflight-carrid.

DATA gv_next TYPE i.

START-OF-SELECTION.
  gv_next = p_count + 1.
  WRITE: / p_count, gv_next, p_date, p_amount, p_name, p_flag.
  IF p_opt1 = abap_true.
    WRITE: / 'Option 1'.
  ELSE.
    WRITE: / 'Option 2'.
  ENDIF.
  LOOP AT s_carr INTO DATA(ls_carr).
    WRITE: / ls_carr-sign, ls_carr-option, ls_carr-low, ls_carr-high.
  ENDLOOP.
