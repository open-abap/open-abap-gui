REPORT zgg_ex_126.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_date FOR EVENT date_selected OF cl_gui_calendar
      IMPORTING date_begin date_end.
ENDCLASS.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_calendar TYPE REF TO cl_gui_calendar.
DATA gt_events TYPE cntl_simple_events.
DATA gv_state TYPE c LENGTH 60.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_date.
    gv_state = |Selected { date_begin } to { date_end }|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_MAIN'.
    CREATE OBJECT go_calendar
      EXPORTING
        parent = go_container.
    go_calendar->go_to_date( '20260830' ).
    go_calendar->set_selection( date_begin = '20260830'
                                date_end   = '20260901' ).
    gt_events = VALUE #( ( eventid    = cl_gui_calendar=>m_id_date_selected
                           appl_event = abap_true ) ).
    go_calendar->set_registered_events( gt_events ).
    SET HANDLER lcl_handler=>on_date FOR go_calendar.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  cl_gui_cfw=>dispatch( ).
ENDMODULE.
