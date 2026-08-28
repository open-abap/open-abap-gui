CLASS ltcl_gg_html_examples DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-METHODS assert_document
      IMPORTING
        iv_html TYPE string.
    METHODS classic_examples FOR TESTING.
    METHODS selection_examples FOR TESTING.
    METHODS selection_integration FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_html_examples IMPLEMENTATION.

  METHOD assert_document.
    cl_abap_unit_assert=>assert_true( act = xsdbool( iv_html CS '<!doctype html>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( iv_html CS '<html' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( iv_html CS '<main' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( iv_html CS 'data-page-kind=' ) ).
  ENDMETHOD.

  METHOD classic_examples.
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_01( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_02( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_03( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_04( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_05( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_06( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_07( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_08( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_09( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_10( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_11( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_12( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_13( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_14( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_43( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_44( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_45( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_46( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_47( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_48( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_49( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_50( ) )-html ).
  ENDMETHOD.

  METHOD selection_examples.
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_15( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_16( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_17( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_18( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_19( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_20( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_21( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_22( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_23( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_24( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_25( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_26( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_27( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_28( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_29( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_30( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_31( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_32( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_33( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_34( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_35( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_36( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_37( ) )-html ).
    assert_document( zcl_gg_host=>run( NEW zcl_gg_ex_38( ) )-html ).
  ENDMETHOD.

  METHOD selection_integration.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_selection( 'DEFAULT' ) ).
    assert_document( ls_result-html ).
    ls_result = zcl_gg_host=>run( NEW zcl_gg_integration_selection( 'REQUIRED' ) ).
    assert_document( ls_result-html ).
    ls_result = zcl_gg_host=>run( NEW zcl_gg_integration_selection( 'RANGE' ) ).
    assert_document( ls_result-html ).
    ls_result = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_selection( 'VALUE_REQUEST' )
      iv_value_request = 'S_CARR' ).
    assert_document( ls_result-html ).
    ls_result = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_selection( 'DATE_REQUEST' )
      iv_value_request = 'S_DATE' ).
    assert_document( ls_result-html ).
  ENDMETHOD.

ENDCLASS.
