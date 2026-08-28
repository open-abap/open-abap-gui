CLASS ltcl_ex_12 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS initializes_parameter FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_12 IMPLEMENTATION.

  METHOD initializes_parameter.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_12( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `20260101` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_DATE' ]-value
      exp = '20260101' ).
  ENDMETHOD.

ENDCLASS.
