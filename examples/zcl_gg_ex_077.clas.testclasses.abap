CLASS ltcl_ex_77 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS function_key_sets_action FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_77 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_077( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_077' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD function_key_sets_action.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_077( )
      iv_ucomm  = 'FC02'
      it_input  = VALUE #( ( name = 'P_REQ' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_ACT' ]-value
      exp = 'beta' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ kind = 'FUNCTION_KEY' number = 2 ]-text
      exp = 'Beta action' ).
  ENDMETHOD.

ENDCLASS.
