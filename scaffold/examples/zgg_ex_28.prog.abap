REPORT zgg_ex_28.

PARAMETERS p_a TYPE c LENGTH 1.
PARAMETERS p_b TYPE c LENGTH 1 MODIF ID hid.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-group1 = 'HID'.
      screen-invisible = '1'.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
