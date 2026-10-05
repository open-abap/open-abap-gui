CLASS ltcl_ex_48 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS writes_nested_header FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_48 IMPLEMENTATION.

  METHOD writes_nested_header.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report     = NEW zcl_gg_ex_048( )
      iv_line_index = 1 ).

* The detail list is level 1, with its own page header.
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-list_level
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `detail header` )
        ( `detail` ) ) ).
  ENDMETHOD.

ENDCLASS.
