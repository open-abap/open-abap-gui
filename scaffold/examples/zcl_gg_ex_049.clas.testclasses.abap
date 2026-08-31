CLASS ltcl_ex_49 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS dispatches_pf5 FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_49 IMPLEMENTATION.

  METHOD dispatches_pf5.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_049( )
      iv_pf_key = 5 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `body` )
        ( `pf5` ) ) ).
    cl_abap_unit_assert=>assert_true(
      act = line_exists( ls_result-status-active_pf_keys[ table_line = 5 ] ) ).
  ENDMETHOD.

ENDCLASS.
