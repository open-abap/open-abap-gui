CLASS ltcl_ex_80 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS runs_every_validation_event FOR TESTING.
    METHODS field_error_stops FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_80 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_080( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_080' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD runs_every_validation_event.
* The field events come first and AT SELECTION-SCREEN itself last.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_080( )
      it_input  = VALUE #( ( name = 'P_FLD' value = 'good' )
                          ( name = 'P_REQ' value = 'ok' ) ) ).
    DATA(lv_order) = ls_result-lines[ 1 ].
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_order CP 'FIELD>*>SCREEN' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_order CS 'RADIO' AND lv_order CS 'BLOCK' AND lv_order CS 'END' ) ).
  ENDMETHOD.

  METHOD field_error_stops.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_080( )
      it_input  = VALUE #( ( name = 'P_FLD' value = 'bad' )
                          ( name = 'P_REQ' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_true( ls_result-selection_active ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Field validation failed' ).
  ENDMETHOD.

ENDCLASS.
