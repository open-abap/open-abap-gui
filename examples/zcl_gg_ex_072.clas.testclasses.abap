CLASS ltcl_ex_72 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS keeps_range_signs FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_72 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_072( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_072' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD keeps_range_signs.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_072( )
      it_input  = VALUE #(
        ( name = 'S_CAR' ranges = VALUE #(
          ( sign = 'I' option = 'EQ' low = 'AA' )
          ( sign = 'E' option = 'BT' low = 'LH' high = 'SQ' ) ) )
        ( name = 'P_REQ' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'S_CAR' ]-ranges[ 2 ]-sign
      exp = 'E' ).
  ENDMETHOD.

ENDCLASS.
