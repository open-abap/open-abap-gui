REPORT zgg_ex_068.

PARAMETERS p_show AS CHECKBOX USER-COMMAND toggle.
PARAMETERS p_detail TYPE c LENGTH 20 MODIF ID det.
PARAMETERS p_req TYPE c LENGTH 20 OBLIGATORY.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-group1 = 'DET'.
      IF p_show = abap_true.
        screen-active = 1.
        screen-required = 1.
      ELSE.
        screen-active = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

START-OF-SELECTION.
  WRITE p_req.
  WRITE / p_detail.
