REPORT zgg_ex_077.

TABLES sscrfields.

SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN FUNCTION KEY 2.

PARAMETERS p_act TYPE c LENGTH 20.
PARAMETERS p_req TYPE c LENGTH 20 OBLIGATORY.

INITIALIZATION.
  sscrfields-functxt_01 = 'Alpha action'.
  sscrfields-functxt_02 = 'Beta action'.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      p_act = 'alpha'.
      MESSAGE 'Alpha action selected' TYPE 'S'.
    WHEN 'FC02'.
      p_act = 'beta'.
      MESSAGE 'Beta action selected' TYPE 'S'.
  ENDCASE.

START-OF-SELECTION.
  WRITE p_act.
