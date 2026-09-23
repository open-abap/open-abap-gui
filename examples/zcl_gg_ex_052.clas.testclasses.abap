CLASS ltcl_ex_52 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS resumes_after_screen FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_52 IMPLEMENTATION.

  METHOD resumes_after_screen.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_052( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `back` ) ) ).
  ENDMETHOD.

ENDCLASS.
