REPORT zgg_ex_191.

* A MODULE that PERFORMs two FORMs with a local DATA of the same name but
* different types, with a popup FORM between them.

DATA ok_code LIKE sy-ucomm.
DATA gv_text TYPE c LENGTH 10.
DATA gv_number TYPE i.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM show_text.
  PERFORM show_number.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF ok_code = 'BACK'.
    PERFORM confirm_leave.
  ENDIF.
ENDMODULE.

FORM show_text.
  DATA lv_value TYPE c LENGTH 10.
  lv_value = 'text'.
  gv_text = lv_value.
ENDFORM.

FORM confirm_leave.
  DATA lv_answer TYPE c LENGTH 1.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question = 'Leave?'
    IMPORTING
      answer        = lv_answer.
  IF lv_answer = '1'.
    LEAVE TO SCREEN 0.
  ENDIF.
ENDFORM.

FORM show_number.
  DATA lv_value TYPE i.
  lv_value = lv_value + 1.
  gv_number = lv_value.
ENDFORM.
