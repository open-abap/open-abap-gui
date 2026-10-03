REPORT zgg_ex_076.

TABLES sscrfields.

PARAMETERS p_der TYPE c LENGTH 30.
SELECTION-SCREEN PUSHBUTTON /1(20) TEXT-001 USER-COMMAND derive.
PARAMETERS p_req TYPE c LENGTH 20 OBLIGATORY.

AT SELECTION-SCREEN.
  IF sscrfields-ucomm = 'DERIVE'.
    p_der = 'derived by pushbutton'.
    MESSAGE 'Derived value updated' TYPE 'S'.
  ENDIF.

START-OF-SELECTION.
  WRITE p_der.
