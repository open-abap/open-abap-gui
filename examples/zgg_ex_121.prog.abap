REPORT zgg_ex_121.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_close FOR EVENT close OF cl_gui_dialogbox_container
      IMPORTING sender.
ENDCLASS.

DATA go_dialog TYPE REF TO cl_gui_dialogbox_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_close.
    sender->free( ).
    CLEAR: go_dialog, go_editor.
    gv_state = 'Dialog box closed'.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_dialog IS INITIAL AND gv_state IS INITIAL.
    PERFORM open_dialog.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'OPEN' AND go_dialog IS INITIAL.
    PERFORM open_dialog.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.

FORM open_dialog.
  go_dialog = NEW #( width   = 360
                     height  = 180
                     caption = 'Dialog content' ).
  SET HANDLER lcl_handler=>on_close FOR go_dialog.
  go_editor = NEW #( parent = go_dialog ).
  go_editor->set_textstream( 'Modal dialog body' ).
  gv_state = 'Dialog box open'.
ENDFORM.
