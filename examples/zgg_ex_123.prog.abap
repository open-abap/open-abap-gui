REPORT zgg_ex_123.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_editor TYPE REF TO cl_gui_textedit.

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
    go_editor->set_textstream( |Read-only text{ cl_abap_char_utilities=>newline }This cannot be edited| ).
    go_editor->set_readonly_mode( cl_gui_textedit=>true ).
  ENDIF.
ENDMODULE.
