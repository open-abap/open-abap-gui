REPORT zgg_ex_064.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_title TYPE c LENGTH 30.
DATA gv_note TYPE c LENGTH 40.
DATA gv_count TYPE i.
DATA gv_cursor TYPE c LENGTH 30 VALUE 'GV_TITLE'.
DATA gv_field TYPE c LENGTH 30.
DATA gt_excluded TYPE STANDARD TABLE OF sy-ucomm WITH DEFAULT KEY.

START-OF-SELECTION.
  CALL SCREEN 100.

* The title counts the notes, Remove is only offered with a note, and the
* cursor waits in the field to fill next.
MODULE status_0100 OUTPUT.
  CLEAR gt_excluded.
  IF gv_count = 0.
    APPEND 'UNDO' TO gt_excluded.
  ENDIF.
  SET PF-STATUS 'MAIN' EXCLUDING gt_excluded.
  SET TITLEBAR 'MAIN' WITH gv_count.
  SET CURSOR FIELD gv_cursor.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  GET CURSOR FIELD gv_field.
  CASE gv_ok_code.
    WHEN 'ADD'.
      gv_count = gv_count + 1.
      gv_cursor = 'GV_NOTE'.
      MESSAGE |Note { gv_count } added, cursor was in { gv_field }| TYPE 'S'.
    WHEN 'UNDO'.
      gv_count = gv_count - 1.
      gv_cursor = 'GV_TITLE'.
      MESSAGE |Note removed, cursor was in { gv_field }| TYPE 'S'.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
