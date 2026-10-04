CLASS ltcl_ex_88 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS writes_icons FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_88 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_088( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_088' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD writes_icons.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_088( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-render_lines[ 1 ]-fragments[ 1 ]-kind
                                        exp = 'ICON' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-render_lines[ 1 ]-fragments[ 2 ]-kind
                                        exp = 'SYMBOL' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-render_lines[ 1 ]-fragments[ 3 ]-kind
                                        exp = 'CHECKBOX' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-render_lines[ 1 ]-fragments[ 1 ]-format-quickinfo
                                        exp = 'Icon & <safe>' ).
  ENDMETHOD.

ENDCLASS.
