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
    zcl_gg_gui_runtime=>clear( ).
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
    zcl_gg_gui_runtime=>clear( ).
  ENDMETHOD.

  METHOD renders_countdown.
    zcl_gg_gui_runtime=>clear( ).
    DATA(lo_timer) = NEW cl_gui_timer( ).
    lo_timer->interval = 2.

    cl_abap_unit_assert=>assert_true( act = xsdbool( zcl_gg_gui_runtime=>render_html( ) CS 'data-running="false"' ) ).
    lo_timer->run( ).
    DATA(lv_html) = zcl_gg_gui_runtime=>render_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS |data-interval="2" aria-hidden="true" hidden><button type="submit" name="gg_control_event" value="{ zcl_gg_gui_runtime=>get_control_id( control = lo_timer ) }\|FINISHED"| ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<script>' ) ).
    zcl_gg_gui_runtime=>clear( ).
  ENDMETHOD.
ENDCLASS.
