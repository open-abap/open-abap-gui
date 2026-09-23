CLASS ltcl_ex_52 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS resumes_after_screen FOR TESTING.
    METHODS pauses_at_call_screen FOR TESTING.
    METHODS roundtrips_call_screen FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_52 IMPLEMENTATION.

  METHOD resumes_after_screen.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_052( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `back` ) ) ).
  ENDMETHOD.

  METHOD pauses_at_call_screen.
    DATA(ls_screen) = zcl_gg_host=>run( NEW zcl_gg_ex_052( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_screen-navigation-kind
      exp = zcx_gg_control_flow=>kind_call_screen ).
    cl_abap_unit_assert=>assert_equals( act = ls_screen-navigation-target
                                        exp = '0100' ).
  ENDMETHOD.

  METHOD roundtrips_call_screen.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_screen) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_052( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_screen-page_kind
      exp = zif_gg_host_html_v1=>page_navigation ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_screen-html CS 'Continue to' ) ).
    DATA(ls_screen_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_screen-session_id
      page_id    = ls_screen-page_id
      action     = zif_gg_host_html_v1=>action_submit ) ).
    cl_abap_unit_assert=>assert_true( ls_screen_next-valid ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_screen_next-compatibility-lines[ table_line = 'back' ] ) ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
