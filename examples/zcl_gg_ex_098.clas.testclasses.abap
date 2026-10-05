CLASS ltcl_ex_98 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS filters_flights FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_98 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_098( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_098' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD filters_flights.
    DATA(ls_result) = zcl_gg_host=>run( io_report       = NEW zcl_gg_ex_098( )
                                        iv_user_command = 'FILTER' ).
* The basic list keeps all four flights; the detail list shown holds the
* filtered ones.
    cl_abap_unit_assert=>assert_equals( act = ls_result-list_level
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-lines )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-lines[ 1 ] CP 'LH*' AND ls_result-lines[ 2 ] CP 'LH*' ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-title
                                        exp = 'Flights: FILTERED' ).
  ENDMETHOD.

ENDCLASS.
