CLASS ltcl_ex_05 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS formats_and_resets FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_05 IMPLEMENTATION.

  METHOD formats_and_resets.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_005( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `key column plain` ) ) ).
  ENDMETHOD.

ENDCLASS.
