CLASS ltcl_ex_162 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS renders_grid_on_screen FOR TESTING.
    METHODS keeps_grid_after_refresh FOR TESTING.
    METHODS teardown.

ENDCLASS.

CLASS ltcl_ex_162 IMPLEMENTATION.

  METHOD teardown.
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD renders_grid_on_screen.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program   = NEW zcl_gg_ex_162( )
      iv_submitted = abap_false ).

    cl_abap_unit_assert=>assert_equals( act = ls_result-title
                                        exp = 'Paused events' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-control-kind="ALV_GRID"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>BUS2032<' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>Paused by<' ) ).
  ENDMETHOD.

  METHOD keeps_grid_after_refresh.
    DATA(lo_program) = NEW zcl_gg_ex_162( ).

    zcl_gg_host_dynpro=>run(
      io_program   = lo_program
      iv_submitted = abap_false ).
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program   = lo_program
      iv_ucomm     = 'REFRESH'
      iv_submitted = abap_true ).

    cl_abap_unit_assert=>assert_initial( ls_result-messages ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>BUS2105<' ) ).
  ENDMETHOD.

ENDCLASS.
