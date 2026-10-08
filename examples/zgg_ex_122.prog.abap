REPORT zgg_ex_122.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_text TYPE string.
DATA gv_state TYPE c LENGTH 60.

START-OF-SELECTION.
  gv_text = |First line{ cl_abap_char_utilities=>newline }Second line{ cl_abap_char_utilities=>newline }Third line|.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_MAIN' ).
    go_editor = NEW #( parent                     = go_container
                       wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
                       wordwrap_position          = 72
                       wordwrap_to_linebreak_mode = cl_gui_textedit=>true ).
    go_editor->set_toolbar_mode( cl_gui_textedit=>true ).
    go_editor->set_statusbar_mode( cl_gui_textedit=>true ).
    go_editor->set_font_fixed( cl_gui_textedit=>true ).
    go_editor->set_textstream( gv_text ).
    go_editor->protect_lines( from_line = 1
                              to_line   = 1 ).
    go_editor->go_to_line( 2 ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'SAVE_TEXT'.
    go_editor->get_textstream( IMPORTING text = gv_text ).
    cl_gui_cfw=>flush( ).
    gv_state = |Saved { strlen( gv_text ) } characters|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
