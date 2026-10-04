CLASS ltcl_gui_timer DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA mv_finished TYPE i.
    METHODS on_finished FOR EVENT finished OF cl_gui_timer.
    METHODS finishes_once_per_run FOR TESTING.
    METHODS renders_countdown FOR TESTING.
ENDCLASS.

CLASS cl_gui_timer DEFINITION LOCAL FRIENDS ltcl_gui_timer.

CLASS ltcl_gui_timer IMPLEMENTATION.
  METHOD on_finished.
    mv_finished = mv_finished + 1.
  ENDMETHOD.

  METHOD finishes_once_per_run.
    cl_gui_control=>clear( ).
    DATA(lo_timer) = NEW cl_gui_timer( ).
    SET HANDLER on_finished FOR lo_timer.
    lo_timer->interval = 1.

    cl_abap_unit_assert=>assert_false( act = lo_timer->is_running( ) ).
    lo_timer->run( ).
    cl_abap_unit_assert=>assert_true( act = lo_timer->is_running( ) ).
    cl_abap_unit_assert=>assert_false( act = lo_timer->is_application_event( 'FINISHED' ) ).
    lo_timer->dispatch_frontend_event( event  = 'FINISHED'
                                       params = VALUE #( ) ).
    cl_abap_unit_assert=>assert_equals( act = mv_finished
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_false( act = lo_timer->is_running( ) ).

* A late FINISHED of a timer that is no longer running is ignored.
    lo_timer->dispatch_frontend_event( event  = 'FINISHED'
                                       params = VALUE #( ) ).
    lo_timer->run( ).
    lo_timer->cancel( ).
    lo_timer->dispatch_frontend_event( event  = 'FINISHED'
                                       params = VALUE #( ) ).
    cl_abap_unit_assert=>assert_equals( act = mv_finished
                                        exp = 1 ).
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD renders_countdown.
    cl_gui_control=>clear( ).
    DATA(lo_timer) = NEW cl_gui_timer( ).
    lo_timer->interval = 2.

    cl_abap_unit_assert=>assert_true( act = xsdbool( cl_gui_control=>render_html( ) CS 'data-running="false"' ) ).
    lo_timer->run( ).
    DATA(lv_html) = cl_gui_control=>render_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS |data-interval="2" aria-hidden="true" hidden><button type="submit" name="gg_control_event" value="{ lo_timer->control_id }\|FINISHED"| ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<script>' ) ).
    cl_gui_control=>clear( ).
  ENDMETHOD.
ENDCLASS.
