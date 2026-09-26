CLASS ltcl_gg_program DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS writes_the_list FOR TESTING.
    METHODS is_a_registered_program FOR TESTING.
    METHODS is_listed_under_reports FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_program IMPLEMENTATION.

  METHOD writes_the_list.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_program( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `started without a transaction` ) ) ).
  ENDMETHOD.

  METHOD is_a_registered_program.
    zcl_gg_program_registry=>clear( ).
    DATA(ls_registered) = zcl_gg_program_registry=>lookup( iv_program = `  zgg_int_program  ` ).
    cl_abap_unit_assert=>assert_equals( act = ls_registered-program
                                        exp = 'ZGG_INT_PROGRAM' ).
    cl_abap_unit_assert=>assert_equals( act = ls_registered-class_name
                                        exp = 'ZCL_GG_INTEGRATION_PROGRAM' ).
    cl_abap_unit_assert=>assert_equals( act = ls_registered-description
                                        exp = 'Report without transaction' ).
    cl_abap_unit_assert=>assert_initial(
      act = zcl_gg_program_registry=>lookup( iv_program = `ZGG_INT_UNKNOWN` ) ).
  ENDMETHOD.

  METHOD is_listed_under_reports.
    DATA lo_html TYPE REF TO zif_gg_raw_html_v1.

    lo_html = NEW zcl_gg_workbench( ).
    DATA(lv_html) = lo_html->get_html( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<nav aria-label="Reports">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '/program?name=ZGG_INT_PROGRAM' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Report without transaction' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '/transaction?tcode=ZGG_INT_PROGRAM' ) ).
  ENDMETHOD.

ENDCLASS.
