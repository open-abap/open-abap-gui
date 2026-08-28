CLASS ltcl_ex_43 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS selects_hidden_line FOR TESTING.
    METHODS renders_accessible_list FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_43 IMPLEMENTATION.

  METHOD selects_hidden_line.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report    = NEW zcl_gg_ex_43( )
      iv_line_index = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `1` )
        ( `2` )
        ( `3` )
        ( `2` ) ) ).
  ENDMETHOD.

  METHOD renders_accessible_list.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_43( ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '<form method="post" action="/dispatch">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'aria-label="Select line 1"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-action-token="' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS 'data-hide-value' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS 'name="GV_ID"' ) ).
  ENDMETHOD.

ENDCLASS.
