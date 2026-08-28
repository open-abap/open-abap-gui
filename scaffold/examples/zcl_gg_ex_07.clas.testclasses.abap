CLASS ltcl_ex_07 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS writes_with_list_settings FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_07 IMPLEMENTATION.

  METHOD writes_with_list_settings.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_07( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `body` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-settings-line_size
      exp = 120 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-settings-line_count
      exp = 65 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-settings-footer_lines
      exp = 3 ).
    cl_abap_unit_assert=>assert_true( ls_result-settings-no_standard_page_head ).
  ENDMETHOD.

ENDCLASS.
