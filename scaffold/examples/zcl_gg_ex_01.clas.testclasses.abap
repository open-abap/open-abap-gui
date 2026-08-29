CLASS ltcl_ex_01 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS writes_the_literal FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_01 IMPLEMENTATION.

  METHOD writes_the_literal.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_01( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-title
      exp = 'ZCL_GG_EX_01' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `hello world` ) ) ).
  ENDMETHOD.

ENDCLASS.
