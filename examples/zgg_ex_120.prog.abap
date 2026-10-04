REPORT zgg_ex_120.

DATA go_dock TYPE REF TO cl_gui_docking_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_extension TYPE i VALUE 180.
DATA gv_side TYPE i.
DATA gv_state TYPE c LENGTH 60.

START-OF-SELECTION.
  gv_side = cl_gui_docking_container=>dock_at_left.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_dock IS INITIAL.
    CREATE OBJECT go_dock
      EXPORTING
        repid     = sy-repid
        dynnr     = sy-dynnr
        side      = gv_side
        extension = gv_extension
        caption   = 'Docked tools'.
    CREATE OBJECT go_editor
      EXPORTING
        parent = go_dock.
    go_editor->set_textstream( 'Docked content' ).
    gv_state = |Docked left, { gv_extension } pixels|.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'EXTEND'.
      gv_extension = COND #( WHEN gv_extension = 180 THEN 320 ELSE 180 ).
      go_dock->set_extension( gv_extension ).
      gv_state = |Dock extension { gv_extension } pixels|.
    WHEN 'DOCK_RIGHT'.
      go_dock->dock_at( cl_gui_docking_container=>dock_at_right ).
      gv_state = 'Docked right'.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
