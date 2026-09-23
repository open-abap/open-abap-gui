CLASS ltcl_ex_54 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS submits_with_selection FOR TESTING.
    METHODS pauses_at_submit FOR TESTING.
    METHODS roundtrips_submit FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_54 IMPLEMENTATION.

  METHOD submits_with_selection.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report        = NEW zcl_gg_ex_054( )
      io_submit_report = NEW zcl_gg_ex_020( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `back` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-submit-program
      exp = 'ZGG_EX_020' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-submit-variant
      exp = 'STANDARD' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-submit-values[ name = 'S_CARR' ]-ranges[ 1 ]-low
      exp = 'LH' ).
  ENDMETHOD.

  METHOD pauses_at_submit.
    DATA(ls_submit) = zcl_gg_host=>run( NEW zcl_gg_ex_054( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_submit-navigation-kind
      exp = zcx_gg_control_flow=>kind_submit_return ).
    cl_abap_unit_assert=>assert_equals( act = ls_submit-navigation-target
                                        exp = 'ZGG_EX_020' ).
  ENDMETHOD.

  METHOD roundtrips_submit.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_submit) = zcl_gg_host_runtime=>start(
      io_report        = NEW zcl_gg_ex_054( )
      io_submit_report = NEW zcl_gg_ex_001( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_submit-page_kind
      exp = zif_gg_host_html_v1=>page_navigation ).
    DATA(ls_submit_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_submit-session_id
      page_id    = ls_submit-page_id
      action     = zif_gg_host_html_v1=>action_submit ) ).
    cl_abap_unit_assert=>assert_true( ls_submit_next-valid ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_submit_next-compatibility-lines[ table_line = 'back' ] ) ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
