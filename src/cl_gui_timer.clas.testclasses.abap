CLASS ltcl_gui_timer DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS lifecycle_is_explicit FOR TESTING.
ENDCLASS.

CLASS ltcl_gui_timer IMPLEMENTATION.
  METHOD lifecycle_is_explicit.
    cl_gui_control=>clear( ).
    DATA(lo_timer) = NEW cl_gui_timer( ).
    cl_gui_control=>initialize( control = lo_timer
                                kind    = 'TIMER' ).
    lo_timer->interval = 250.

    cl_abap_unit_assert=>assert_false( act = lo_timer->is_running( ) ).
    lo_timer->run( ).
    cl_abap_unit_assert=>assert_true( act = lo_timer->is_running( ) ).
    lo_timer->tick( ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_timer->get_tick_count( )
      exp = 1 ).
    lo_timer->cancel( ).
    lo_timer->tick( ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_timer->get_tick_count( )
      exp = 1 ).
    cl_gui_control=>clear( ).
  ENDMETHOD.
ENDCLASS.
