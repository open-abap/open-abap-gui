CLASS ltcl_ex_24 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_pushbutton FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_24 IMPLEMENTATION.

  METHOD builds_pushbutton.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_24( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'PB_LOAD' ]-kind
      exp = 'PUSHBUTTON' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'PB_LOAD' ]-text
      exp = 'Load defaults' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'PB_LOAD' ]-position
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'PB_LOAD' ]-length
      exp = 20 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'PB_LOAD' ]-ucomm
      exp = 'LOAD' ).
  ENDMETHOD.

ENDCLASS.
