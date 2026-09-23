CLASS ltcl_ex_01 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS writes_the_literal FOR TESTING.
    METHODS is_a_registered_transaction FOR TESTING.
    METHODS is_listed_in_the_workbench FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_01 IMPLEMENTATION.

  METHOD writes_the_literal.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_001( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-title
      exp = 'ZCL_GG_EX_001' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `hello world` ) ) ).
  ENDMETHOD.

  METHOD is_a_registered_transaction.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    DATA lo_report TYPE REF TO zif_gg_report_v1.
    DATA lo_example TYPE REF TO zcl_gg_ex_001.

    lo_example = NEW zcl_gg_ex_001( ).
    lo_metadata ?= lo_example.
    lo_report ?= lo_example.
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode
                                        exp = 'ZGG_EX_001' ).
    cl_abap_unit_assert=>assert_bound( act = lo_report ).

    zcl_gg_transaction_registry=>clear( ).
    DATA(ls_registered) = zcl_gg_transaction_registry=>lookup( iv_tcode = `  zgg_ex_001  ` ).
    cl_abap_unit_assert=>assert_equals( act = ls_registered-tcode
                                        exp = 'ZGG_EX_001' ).
    cl_abap_unit_assert=>assert_equals( act = ls_registered-class_name
                                        exp = 'ZCL_GG_EX_001' ).
  ENDMETHOD.

  METHOD is_listed_in_the_workbench.
    DATA lo_html TYPE REF TO zif_gg_raw_html_v1.

    lo_html = NEW zcl_gg_workbench( ).
    DATA(lv_html) = lo_html->get_html( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'ZGG_EX_001' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'WRITE literal' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '/transaction?tcode=ZGG_EX_001' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '/ZCL_GG_EX_001' ) ).
  ENDMETHOD.

ENDCLASS.
