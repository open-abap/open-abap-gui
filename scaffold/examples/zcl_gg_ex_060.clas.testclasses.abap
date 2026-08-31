CLASS ltcl_ex_60 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS preserves_icon_order FOR TESTING.
ENDCLASS.
CLASS ltcl_ex_60 IMPLEMENTATION.
  METHOD preserves_icon_order.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_060( ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-status-icon_bar )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-status-icon_bar[ 1 ]-ucomm
                                        exp = 'FIRST' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-status-icon_bar[ 2 ]-ucomm
                                        exp = 'SECOND' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-status-icon_bar[ 2 ]-separator = abap_true ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'wb-toolbar-separator' ) ).
  ENDMETHOD.
ENDCLASS.
