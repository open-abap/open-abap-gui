REPORT zgg_ex_103.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_delivery TYPE c LENGTH 1.
DATA gv_address TYPE c LENGTH 30.

START-OF-SELECTION.
  CALL SCREEN 100.

* The address is only shown, and then required, with a separate delivery.
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  LOOP AT SCREEN.
    IF screen-name = 'GV_ADDRESS' OR screen-name = 'LBL_ADDRESS'.
      IF gv_delivery = 'X'.
        screen-active = 1.
        IF screen-name = 'GV_ADDRESS'.
          screen-required = 1.
        ENDIF.
      ELSE.
        screen-active = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CLEAR gv_ok_code.
ENDMODULE.
