CLASS ltcl_ex_04 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS formats_numeric_write FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_04 IMPLEMENTATION.

  METHOD formats_numeric_write.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_04( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `1234.50` ) ) ).
  ENDMETHOD.

ENDCLASS.
