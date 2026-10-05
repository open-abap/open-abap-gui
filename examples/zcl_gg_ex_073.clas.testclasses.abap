CLASS ltcl_ex_73 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS writes_every_row FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_73 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_073( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_073' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD writes_every_row.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_073( )
      it_input  = VALUE #(
        ( name = 'S_MUL' ranges = VALUE #(
          ( sign = 'I' option = 'EQ' low = 'AA' )
          ( sign = 'I' option = 'EQ' low = 'LH' ) ) )
        ( name = 'P_REQ' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 2 ).
  ENDMETHOD.

ENDCLASS.
