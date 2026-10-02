REPORT zgg_ex_038.

TABLES sscrfields.

PARAMETERS p_a TYPE c LENGTH 1 DEFAULT 'X'.

INITIALIZATION.
  sscrfields-ucomm = 'ONLI'.

AT SELECTION-SCREEN OUTPUT.
  IF sy-batch = abap_true.
    " screen is not displayed
    RETURN.
  ENDIF.
