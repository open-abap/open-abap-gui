CLASS ltcl_ex_170 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS submits_selection_table FOR TESTING.
    METHODS roundtrips_submit FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_170 IMPLEMENTATION.

  METHOD submits_selection_table.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report        = NEW zcl_gg_ex_170( )
      io_submit_report = NEW zcl_gg_ex_073( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `back` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-submit-program
      exp = 'ZGG_EX_073' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-submit-values[ name = 'P_REQ' ]-value
      exp = `Weekly report` ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-submit-values[ name = 'S_MUL' ]-ranges
      exp = VALUE zif_gg_selection_screen_types=>ty_ranges(
        ( sign = 'I' option = 'EQ' low = `LH` )
        ( sign = 'I' option = 'BT' low = `AA` high = `BA` ) ) ).
  ENDMETHOD.

  METHOD roundtrips_submit.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_submit) = zcl_gg_host_runtime=>start(
      io_report        = NEW zcl_gg_ex_170( )
      io_submit_report = NEW zcl_gg_ex_073( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_submit-page_kind
      exp = zif_gg_host_html_v1=>page_navigation ).
    DATA(ls_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_submit-session_id
      page_id    = ls_submit-page_id
      action     = zif_gg_host_html_v1=>action_submit ) ).
    cl_abap_unit_assert=>assert_true( ls_next-valid ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( ls_next-compatibility-lines[ table_line = 'back' ] ) ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
