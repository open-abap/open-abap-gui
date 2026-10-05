CLASS ltcl_ex_86 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS modifies_lines FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_86 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_086( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_086' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD modifies_lines.
    DATA(ls_result) = zcl_gg_host=>run( io_report     = NEW zcl_gg_ex_086( )
                                        iv_line_index = 1 ).
    cl_abap_unit_assert=>assert_true( act = ls_result-render_lines[ 1 ]-fragments[ 1 ]-format-intensified ).
    cl_abap_unit_assert=>assert_true( act = ls_result-render_lines[ 2 ]-fragments[ 1 ]-format-inverse ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-render_lines[ 1 ]-fragments )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-render_lines[ 1 ]-fields[ name = 'GV_ROW' ]-value
                                        exp = '1' ).
  ENDMETHOD.

ENDCLASS.
