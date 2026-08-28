CLASS ltcl_ex_45 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS records_title FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_45 IMPLEMENTATION.

  METHOD records_title.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_45( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-title
      exp = 'MAIN' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `body` ) ) ).
  ENDMETHOD.

ENDCLASS.
