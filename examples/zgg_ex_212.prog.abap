REPORT zgg_ex_212.

* Two PAI modules, each passing a literal to a FORM that changes its USING
* parameter, and a FORM performed inside the PBO's LOOP AT SCREEN. The
* modules become one method of the class. The FORM checks the field's
* modification group 2.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_input TYPE c LENGTH 30 VALUE 'input'.
DATA gv_output TYPE c LENGTH 40 VALUE 'output'.
DATA gv_check TYPE c LENGTH 1 VALUE 'X'.
DATA gv_alpha TYPE c LENGTH 1 VALUE 'X'.
DATA gv_beta TYPE c LENGTH 1.
DATA gv_list TYPE c LENGTH 10 VALUE 'A'.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  LOOP AT SCREEN.
    PERFORM protect_output.
    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.

MODULE exit_0100 INPUT.
  PERFORM describe USING 'Leaving'.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'APPLY'.
    PERFORM describe USING 'Applied'.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.

FORM describe USING iv_text TYPE c.
  CONCATENATE iv_text gv_input INTO gv_output SEPARATED BY space.
  iv_text = space.
ENDFORM.

FORM protect_output.
  IF screen-group2 = 'OUT'.
    screen-input = 0.
  ENDIF.
ENDFORM.
