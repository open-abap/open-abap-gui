CLASS ltcl_ex_48 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS writes_nested_header FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_48 IMPLEMENTATION.

  METHOD writes_nested_header.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report     = NEW zcl_gg_ex_48( )
      iv_line_index = 1
      iv_line_level = 1 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `row` )
        ( `detail header, level 1` )
        ( `detail` ) ) ).
  ENDMETHOD.

ENDCLASS.
