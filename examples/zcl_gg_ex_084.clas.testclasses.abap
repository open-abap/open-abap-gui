CLASS ltcl_ex_84 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS restores_hidden_values FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_84 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_084( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_084' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD restores_hidden_values.
    DATA(ls_result) = zcl_gg_host=>run( io_report     = NEW zcl_gg_ex_084( )
                                        iv_line_index = 2 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-lines[ table_line = 'selected bravo' ] ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-render_lines[ 2 ]-fields[ name = 'GV_SECRET' ]-value
                                        exp = 'bravo' ).
  ENDMETHOD.

ENDCLASS.
