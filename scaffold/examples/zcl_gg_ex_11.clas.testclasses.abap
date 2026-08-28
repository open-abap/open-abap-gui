CLASS ltcl_ex_11 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS loads_before_selection FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_11 IMPLEMENTATION.

  METHOD loads_before_selection.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_11( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `loaded started` ) ) ).
  ENDMETHOD.

ENDCLASS.
