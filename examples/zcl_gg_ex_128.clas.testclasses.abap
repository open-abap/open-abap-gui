CLASS ltcl_ex_128 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_128 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_128( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_128' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

ENDCLASS.

