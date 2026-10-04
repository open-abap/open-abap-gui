REPORT zgg_ex_133.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_text TYPE string.
DATA gv_state TYPE c LENGTH 60.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_MAIN'.
    CREATE OBJECT go_editor
      EXPORTING
        parent = go_container.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'CHECK'.
    CLEAR gv_ok_code.
    go_editor->get_textstream( IMPORTING text = gv_text ).
    cl_gui_cfw=>flush( ).
    IF gv_text IS INITIAL.
      MESSAGE 'Editor value is required' TYPE 'E'.
    ENDIF.
    gv_state = |Accepted { strlen( gv_text ) } characters|.
  ENDIF.
ENDMODULE.
