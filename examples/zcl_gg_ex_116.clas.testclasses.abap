CLASS ltcl_ex_116 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_116 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA(ls_transaction) = zcl_gg_ex_116=>zif_gg_transaction_v1~get_transaction( ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_116' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

ENDCLASS.
