CLASS ltcl_ex_163 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS renders_salv_after_cast FOR TESTING.
    METHODS teardown.

ENDCLASS.

CLASS ltcl_ex_163 IMPLEMENTATION.

  METHOD teardown.
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD renders_salv_after_cast.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program   = NEW zcl_gg_ex_163( )
      iv_submitted = abap_false ).

    cl_abap_unit_assert=>assert_equals( act = ls_result-title
                                        exp = 'Event status' ).
    cl_abap_unit_assert=>assert_initial( ls_result-messages ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'class="gg-alv"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-fieldname="TRAFFIC_LIGHT"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>BUS2032<' ) ).
  ENDMETHOD.

ENDCLASS.
