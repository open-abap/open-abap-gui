CLASS ltcl_ex_97 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS submits_to_memory FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_97 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA(ls_transaction) = zcl_gg_ex_097=>zif_gg_transaction_v1~get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_097' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD submits_to_memory.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_097( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-navigation-kind
                                        exp = 'SUBMIT_RETURN' ).
  ENDMETHOD.

ENDCLASS.
