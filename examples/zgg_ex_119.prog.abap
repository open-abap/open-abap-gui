REPORT zgg_ex_119.

TYPES ty_html_line TYPE c LENGTH 255.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_splitter TYPE REF TO cl_gui_easy_splitter_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA go_viewer TYPE REF TO cl_gui_html_viewer.
DATA gt_html TYPE STANDARD TABLE OF ty_html_line WITH DEFAULT KEY.
DATA gv_url TYPE c LENGTH 255.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_sash TYPE i VALUE 40.
DATA gv_state TYPE c LENGTH 60.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_MAIN'.
    CREATE OBJECT go_splitter
      EXPORTING
        parent        = go_container
        orientation   = cl_gui_easy_splitter_container=>orientation_horizontal
        sash_position = gv_sash.
    CREATE OBJECT go_editor
      EXPORTING
        parent = go_splitter->top_left_container.
    go_editor->set_textstream( 'Easy splitter content' ).
    CREATE OBJECT go_viewer
      EXPORTING
        parent = go_splitter->bottom_right_container.
    gt_html = VALUE #( ( '<h3>Easy splitter viewer</h3><p>The second pane is HTML content.</p>' ) ).
    go_viewer->load_data( IMPORTING assigned_url = gv_url
                          CHANGING  data_table   = gt_html ).
    go_viewer->show_url( url = gv_url ).
    gv_state = |Sash at { gv_sash } %|.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'MOVE_SASH'.
    gv_sash = COND #( WHEN gv_sash = 40 THEN 70 ELSE 40 ).
    go_splitter->set_sash_position( gv_sash ).
    gv_state = |Sash at { gv_sash } %|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
