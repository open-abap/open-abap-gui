CLASS ltcl_ex_46 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS modifies_line_format FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_46 IMPLEMENTATION.

  METHOD modifies_line_format.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report      = NEW zcl_gg_ex_46( )
      iv_line_index  = 1 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `row one` ) ) ).
    cl_abap_unit_assert=>assert_true( ls_result-line_formats[ 1 ]-intensified ).
  ENDMETHOD.

ENDCLASS.
