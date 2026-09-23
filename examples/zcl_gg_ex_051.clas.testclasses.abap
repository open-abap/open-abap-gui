CLASS ltcl_ex_51 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS resumes_after_selection_screen FOR TESTING.
    METHODS pauses_at_selection_screen FOR TESTING.
    METHODS roundtrips_selection_screen FOR TESTING.

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

  METHOD pauses_at_selection_screen.
    DATA(ls_selection) = zcl_gg_host=>run(
      io_report              = NEW zcl_gg_ex_051( )
      iv_pause_at_navigation = abap_true ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_selection-navigation-kind
      exp = zcx_gg_control_flow=>kind_call_selection_screen ).
    cl_abap_unit_assert=>assert_equals( act = ls_selection-navigation-target
                                        exp = '0500' ).
    cl_abap_unit_assert=>assert_equals( act = ls_selection-navigation-continuation
                                        exp = 'AFTER_0500' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_selection-html CS 'gg-selection' ) ).
  ENDMETHOD.

  METHOD roundtrips_selection_screen.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_selection) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_051( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_selection-page_kind
      exp = zif_gg_host_html_v1=>page_selection ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_selection-html CS 'name="P_B"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_selection-html CS 'gg-modal-backdrop' ) ).
    DATA(ls_selection_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_selection-session_id
      page_id    = ls_selection-page_id
      action     = zif_gg_host_html_v1=>action_submit
      values     = VALUE #( ( name = 'P_B' value = 'X' ) ) ) ).
    cl_abap_unit_assert=>assert_true( ls_selection_next-valid ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_selection_next-compatibility-lines[ table_line = 'X' ] ) ) ).

    zcl_gg_host_runtime=>clear( ).
    DATA(ls_cancel) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_051( ) ).
    DATA(ls_cancel_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_cancel-session_id
      page_id    = ls_cancel-page_id
      action     = zif_gg_host_html_v1=>action_exit ) ).
    cl_abap_unit_assert=>assert_true( ls_cancel_next-valid ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( line_exists( ls_cancel_next-compatibility-lines[ table_line = 'X' ] ) ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
