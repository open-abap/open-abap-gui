CLASS ltcl_ex_09 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS writes_page_header FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_09 IMPLEMENTATION.

  METHOD writes_page_header.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_09( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `header` )
        ( `body` ) ) ).
  ENDMETHOD.

ENDCLASS.
