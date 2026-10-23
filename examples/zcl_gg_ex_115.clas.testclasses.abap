CLASS ltcl_ex_115 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_115 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA(ls_transaction) = zcl_gg_ex_115=>zif_gg_transaction_v1~get_transaction( ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_115' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

ENDCLASS.
