REPORT zgg_ex_159.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_date_selected FOR EVENT date_selected OF cl_gui_calendar
      IMPORTING date_begin date_end.
ENDCLASS.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_calendar TYPE REF TO cl_gui_calendar.
DATA gt_events TYPE cntl_simple_events.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_week_begin TYPE d.
DATA gv_week_end TYPE d.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_date_selected.
    gv_week_begin = date_begin.
    gv_week_end = date_end.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_CALENDAR'.
    CREATE OBJECT go_calendar
      EXPORTING
        parent          = go_container
        selection_style = cnca_sel_week
        focus_date      = '20260830'.
    gt_events = VALUE #( ( eventid    = cl_gui_calendar=>m_id_date_selected
                           appl_event = abap_true ) ).
    go_calendar->set_registered_events( gt_events ).
    SET HANDLER lcl_handler=>on_date_selected FOR go_calendar.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  cl_gui_cfw=>dispatch( ).
  CASE gv_ok_code.
    WHEN 'NEXT_YEAR'.
      go_calendar->go_to_date( '20270830' ).
    WHEN 'THIS_YEAR'.
      go_calendar->go_to_date( '20260830' ).
    WHEN 'CLEAR'.
      go_calendar->reset_selection( ).
      CLEAR: gv_week_begin, gv_week_end.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
