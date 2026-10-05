CLASS ltcl_ex_76 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS pushbutton_derives FOR TESTING.
    METHODS rejects_undeclared_command FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_76 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_076( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_076' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD pushbutton_derives.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_076( )
      iv_ucomm  = 'DERIVE'
      it_input  = VALUE #( ( name = 'P_REQ' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_DER' ]-value
      exp = 'derived by pushbutton' ).
  ENDMETHOD.

  METHOD rejects_undeclared_command.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_076( )
      iv_ucomm  = 'FORGED' ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( line_exists( ls_result-messages[
        text = 'Undeclared selection command FORGED' ] ) ) ).
  ENDMETHOD.

ENDCLASS.
