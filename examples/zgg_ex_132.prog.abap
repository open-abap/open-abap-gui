REPORT zgg_ex_132.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_refreshes TYPE i.
DATA gv_enabled TYPE abap_bool VALUE abap_true.
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
    go_editor->set_toolbar_mode( cl_gui_textedit=>true ).
    go_editor->set_statusbar_mode( cl_gui_textedit=>true ).
  ENDIF.
  go_editor->set_textstream( |Control refreshed { gv_refreshes } times| ).
  go_editor->set_enable( gv_enabled ).
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'REFRESH'.
      gv_refreshes = gv_refreshes + 1.
      gv_state = |Refresh { gv_refreshes }|.
    WHEN 'TOGGLE'.
      gv_enabled = xsdbool( gv_enabled = abap_false ).
      gv_state = COND #( WHEN gv_enabled = abap_true THEN 'Editor enabled' ELSE 'Editor disabled' ).
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
