CLASS ltcl_ex_82 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS saves_and_loads_variant FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_82 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_082( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_082' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD saves_and_loads_variant.
    zcl_gg_host_variant=>clear( ).
    zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_082( )
      iv_ucomm  = 'VAR_SAVE'
      it_input  = VALUE #( ( name = 'P_NAME' value = 'UNIT' )
                          ( name = 'P_VALUE' value = 'saved' ) ) ).
    DATA(ls_loaded) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_082( )
      iv_ucomm  = 'VAR_LOAD'
      it_input  = VALUE #( ( name = 'P_NAME' value = 'UNIT' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_loaded-values[ name = 'P_VALUE' ]-value
      exp = 'saved' ).
  ENDMETHOD.

ENDCLASS.
