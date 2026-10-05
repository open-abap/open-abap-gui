CLASS ltcl_ex_71 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS connections_follow_carrier FOR TESTING.
    METHODS rejects_foreign_connection FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_71 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_071( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_071' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD connections_follow_carrier.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_071( )
      it_input  = VALUE #( ( name = 'P_CAR' value = 'LH' )
                          ( name = 'P_CON' value = 'LH-1' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `LH` ) ( `LH-1` ) ) ).
  ENDMETHOD.

  METHOD rejects_foreign_connection.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_071( )
      it_input  = VALUE #( ( name = 'P_CAR' value = 'AA' )
                          ( name = 'P_CON' value = 'LH-1' ) ) ).
    cl_abap_unit_assert=>assert_true( ls_result-selection_active ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Connection does not belong to the carrier' ).
  ENDMETHOD.

ENDCLASS.
