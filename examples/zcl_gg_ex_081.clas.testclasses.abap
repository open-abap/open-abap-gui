CLASS ltcl_ex_81 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS keeps_values_on_error FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_81 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_081( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_081' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD keeps_values_on_error.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_081( )
      it_input  = VALUE #( ( name = 'P_GOOD' value = 'kept' )
                          ( name = 'P_BAD' value = 'bad' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Failing value rejected' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_GOOD' ]-value
      exp = 'kept' ).
  ENDMETHOD.

ENDCLASS.
