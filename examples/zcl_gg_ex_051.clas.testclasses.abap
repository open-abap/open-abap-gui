CLASS ltcl_ex_51 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS resumes_after_selection_screen FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_51 IMPLEMENTATION.

  METHOD resumes_after_selection_screen.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_051( )
      it_input  = VALUE #( ( name = 'P_B' value = 'X' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `X` ) ) ).
  ENDMETHOD.

ENDCLASS.
