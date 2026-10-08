REPORT zgg_ex_128.

TYPES ty_html_line TYPE c LENGTH 255.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_sapevent FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING action.
ENDCLASS.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_viewer TYPE REF TO cl_gui_html_viewer.
DATA gt_html TYPE STANDARD TABLE OF ty_html_line WITH DEFAULT KEY.
DATA gt_events TYPE cntl_simple_events.
DATA gv_url TYPE c LENGTH 255.
DATA gv_state TYPE c LENGTH 60.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_sapevent.
    gv_state = |SAPEVENT { action }|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_MAIN' ).
    go_viewer = NEW #( parent = go_container ).
    gt_html = VALUE #(
      ( '<h2>Sandboxed viewer</h2>' )
      ( '<p>The content is HTML from the program; scripts do not run.</p>' )
      ( '<script>document.title = "script ran"</script>' )
      ( '<p><a href="SAPEVENT:CONFIRM">Confirm</a></p>' ) ).
    go_viewer->load_data( IMPORTING assigned_url = gv_url
                          CHANGING  data_table   = gt_html ).
    go_viewer->show_url( url = gv_url ).
    gt_events = VALUE #( ( eventid    = cl_gui_html_viewer=>m_id_sapevent
                           appl_event = abap_true ) ).
    go_viewer->set_registered_events( gt_events ).
    SET HANDLER lcl_handler=>on_sapevent FOR go_viewer.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  cl_gui_cfw=>dispatch( ).
ENDMODULE.
