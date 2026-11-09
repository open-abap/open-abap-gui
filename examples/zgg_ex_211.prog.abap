REPORT zgg_ex_211.

* SCREEN is a global work area: a FORM performed inside LOOP AT SCREEN
* reads and changes the row the loop is on.

PARAMETERS p_lock AS CHECKBOX DEFAULT 'X' USER-COMMAND lock.
PARAMETERS p_name TYPE c LENGTH 20 MODIF ID nam.
PARAMETERS p_city TYPE c LENGTH 20 MODIF ID nam.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    PERFORM set_input.
    MODIFY SCREEN.
  ENDLOOP.

START-OF-SELECTION.
  WRITE: / 'Name:', p_name.
  WRITE: / 'City:', p_city.

FORM set_input.
  IF screen-group1 = 'NAM'.
    IF p_lock = 'X'.
      screen-input = 0.
    ELSE.
      screen-input = 1.
    ENDIF.
  ENDIF.
ENDFORM.
