CLASS ltcl_ex_08 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS changes_page_for_new_page FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_08 IMPLEMENTATION.

  METHOD changes_page_for_new_page.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_08( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `page one` )
        ( `page two` ) ) ).
  ENDMETHOD.

ENDCLASS.
