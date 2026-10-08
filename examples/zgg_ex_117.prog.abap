REPORT zgg_ex_117.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_generation TYPE i.
DATA gv_large TYPE abap_bool.
DATA gv_state TYPE c LENGTH 60.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_MAIN' ).
    PERFORM create_editor.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'RESIZE'.
      gv_large = xsdbool( gv_large = abap_false ).
      IF gv_large = abap_true.
        go_editor->set_position( left   = 4
                                 top    = 4
                                 width  = 560
                                 height = 300 ).
      ELSE.
        go_editor->set_position( left   = 16
                                 top    = 12
                                 width  = 380
                                 height = 180 ).
      ENDIF.
      gv_state = 'Child geometry changed'.
    WHEN 'REPLACE'.
      go_editor->free( ).
      FREE go_editor.
      PERFORM create_editor.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.

FORM create_editor.
  gv_generation = gv_generation + 1.
  go_editor = NEW #( parent = go_container ).
  go_editor->set_textstream( |Text editor in custom container CC_MAIN, generation { gv_generation }| ).
  gv_state = |Child created, generation { gv_generation }|.
ENDFORM.
