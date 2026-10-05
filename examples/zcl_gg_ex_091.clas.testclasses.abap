CLASS ltcl_ex_91 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS breaks_pages FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_91 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_091( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_091' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD breaks_pages.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_091( ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-lines[ table_line = 'header page 1' ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-lines[ table_line = 'footer page 1' ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-lines[ table_line = 'header page 2' ] ) ) ).
  ENDMETHOD.

ENDCLASS.
