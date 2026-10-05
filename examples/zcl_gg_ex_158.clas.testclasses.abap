CLASS ltcl_ex_158 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS lists_flights_below_airlines FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_158 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_158( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_158' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD lists_flights_below_airlines.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_158( ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'Flights by airline' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>United Airlines</td>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-fieldname="SEATSOCC">630</td>' ) ).
  ENDMETHOD.

ENDCLASS.
