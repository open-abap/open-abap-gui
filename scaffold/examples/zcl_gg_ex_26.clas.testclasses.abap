CLASS ltcl_ex_26 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_tabbed_screen FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_26 IMPLEMENTATION.

  METHOD builds_tabbed_screen.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_26( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'TB' ]-kind
      exp = 'TABBED_BLOCK' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'TB' ]-lines
      exp = 10 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'TAB1' ]-text
      exp = 'General' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'TAB1' ]-subscreen
      exp = '0100' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'TAB1' ]-ucomm
      exp = 'UT1' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'TAB2' ]-text
      exp = 'Details' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'TAB2' ]-subscreen
      exp = '0200' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'TAB2' ]-ucomm
      exp = 'UT2' ).
  ENDMETHOD.

ENDCLASS.
