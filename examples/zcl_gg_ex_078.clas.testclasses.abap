CLASS ltcl_ex_78 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS value_help_offers_carriers FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_78 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_078( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_078' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD value_help_offers_carriers.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report        = NEW zcl_gg_ex_078( )
      iv_value_request = 'P_CAR' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-values[ name = 'P_CAR' ]-ranges )
      exp = 3 ).
  ENDMETHOD.

ENDCLASS.
