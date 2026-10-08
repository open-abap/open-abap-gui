REPORT zgg_ex_118.

TYPES ty_html_line TYPE c LENGTH 255.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_outer TYPE REF TO cl_gui_splitter_container.
DATA go_inner TYPE REF TO cl_gui_splitter_container.
DATA go_editor_top TYPE REF TO cl_gui_textedit.
DATA go_editor_left TYPE REF TO cl_gui_textedit.
DATA go_viewer TYPE REF TO cl_gui_html_viewer.
DATA gt_html TYPE STANDARD TABLE OF ty_html_line WITH DEFAULT KEY.
DATA gv_url TYPE c LENGTH 255.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_row_height TYPE i VALUE 45.
DATA gv_state TYPE c LENGTH 60.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_MAIN' ).
    go_outer = NEW #( parent  = go_container
                      rows    = 2
                      columns = 1 ).
    go_outer->set_row_height( id     = 1
                              height = gv_row_height ).
    DATA(lo_top) = go_outer->get_container( row    = 1
                                            column = 1 ).
    go_editor_top = NEW #( parent = lo_top ).
    go_editor_top->set_textstream( 'Outer editor pane' ).
    DATA(lo_bottom) = go_outer->get_container( row    = 2
                                               column = 1 ).
    go_inner = NEW #( parent  = lo_bottom
                      rows    = 1
                      columns = 2 ).
    DATA(lo_left) = go_inner->get_container( row    = 1
                                             column = 1 ).
    go_editor_left = NEW #( parent = lo_left ).
    go_editor_left->set_textstream( 'Nested editor pane' ).
    DATA(lo_right) = go_inner->get_container( row    = 1
                                              column = 2 ).
    go_viewer = NEW #( parent = lo_right ).
    gt_html = VALUE #( ( '<h3>HTML viewer pane</h3><p>Nested splitter content.</p>' ) ).
    go_viewer->load_data( IMPORTING assigned_url = gv_url
                          CHANGING  data_table   = gt_html ).
    go_viewer->show_url( url = gv_url ).
    gv_state = |Top row height { gv_row_height } %|.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'ROW_SASH'.
    gv_row_height = COND #( WHEN gv_row_height = 45 THEN 25 ELSE 45 ).
    go_outer->set_row_height( id     = 1
                              height = gv_row_height ).
    gv_state = |Top row height { gv_row_height } %|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
