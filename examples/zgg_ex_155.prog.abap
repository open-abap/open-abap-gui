REPORT zgg_ex_155.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_close FOR EVENT close OF cl_gui_dialogbox_container
      IMPORTING sender.
ENDCLASS.

DATA go_dialog TYPE REF TO cl_gui_dialogbox_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_left TYPE i VALUE 360.
DATA gv_top TYPE i VALUE 100.
DATA gv_width TYPE i VALUE 320.
DATA gv_height TYPE i VALUE 160.
DATA gv_count TYPE i.
DATA gv_state TYPE c LENGTH 60.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_close.
    sender->free( ).
    CLEAR: go_dialog, go_editor.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'OPEN'.
      IF go_dialog IS INITIAL.
        CREATE OBJECT go_dialog
          EXPORTING
            width   = gv_width
            height  = gv_height
            top     = gv_top
            left    = gv_left
            caption = 'Flight notes'.
        SET HANDLER lcl_handler=>on_close FOR go_dialog.
        CREATE OBJECT go_editor
          EXPORTING
            parent = go_dialog.
        go_editor->set_textstream( 'LH 0400 leaves Frankfurt at 10:10.' ).
        gv_state = 'Dialog box open'.
      ENDIF.
    WHEN 'MOVE'.
      IF go_dialog IS NOT INITIAL.
        gv_left = gv_left + 40.
        gv_top = gv_top + 20.
        go_dialog->set_position( left = gv_left
                                 top  = gv_top ).
        gv_state = |Dialog box at { gv_left }, { gv_top }|.
      ENDIF.
    WHEN 'RESIZE'.
      IF go_dialog IS NOT INITIAL.
        gv_width = gv_width + 40.
        gv_height = gv_height + 20.
        go_dialog->set_width( gv_width ).
        go_dialog->set_height( gv_height ).
        gv_state = |Dialog box { gv_width } x { gv_height }|.
      ENDIF.
    WHEN 'COUNT'.
      gv_count = gv_count + 1.
      gv_state = |Main screen used { gv_count } times|.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
