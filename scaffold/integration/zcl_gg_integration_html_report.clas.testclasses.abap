CLASS ltcl_gg_html_report DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS starts_on_selection FOR TESTING.
    METHODS requests_carrier_values FOR TESTING.
    METHODS returns_carrier_help FOR TESTING.
    METHODS rejects_unknown_carrier FOR TESTING.
    METHODS renders_selected_flights FOR TESTING.
    METHODS recovers_hidden_flight FOR TESTING.
    METHODS runs_runtime_sequence FOR TESTING.
    METHODS isolates_runtime_sessions FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_html_report IMPLEMENTATION.

  METHOD class_setup.
    zcl_gg_db_helper=>create( ).
  ENDMETHOD.

  METHOD setup.
    zcl_gg_db_helper=>reset( ).
  ENDMETHOD.

  METHOD class_teardown.
    zcl_gg_db_helper=>destroy( ).
  ENDMETHOD.

  METHOD starts_on_selection.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_html_report( ) ).

    cl_abap_unit_assert=>assert_true( ls_result-selection_active ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-page_kind
      exp = zif_gg_host_html_v1=>page_selection ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Enter a carrier' ).
  ENDMETHOD.

  METHOD requests_carrier_values.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report        = NEW zcl_gg_integration_html_report( )
      iv_value_request = 'P_CARR' ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-values[ name = 'P_CARR' ]-ranges )
      exp = 3 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_CARR' ]-ranges[ 1 ]-low
      exp = 'AA' ).
  ENDMETHOD.

  METHOD returns_carrier_help.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report    = NEW zcl_gg_integration_html_report( )
      iv_help_name = 'P_CARR' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-help_text
      exp = 'Enter a carrier from the integration fixture.' ).
  ENDMETHOD.

  METHOD rejects_unknown_carrier.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_html_report( )
      it_input  = VALUE #( ( name = 'P_CARR' value = 'ZZZ' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Unknown carrier' ).
    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

  METHOD renders_selected_flights.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_html_report( )
      it_input  = VALUE #( ( name = 'P_CARR' value = 'AA' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `AA/0017 20260101` )
        ( `AA/0018 20260115` ) ) ).
    cl_abap_unit_assert=>assert_not_initial( ls_result-render_lines[ 1 ]-token ).
  ENDMETHOD.

  METHOD recovers_hidden_flight.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report     = NEW zcl_gg_integration_html_report( )
      it_input      = VALUE #( ( name = 'P_CARR' value = 'AA' ) )
      iv_line_index = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 3 ]
      exp = 'Selected flight: AA/0018 20260115' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 4 ]
      exp = 'Cursor: CARRID=AA line=2' ).
  ENDMETHOD.

  METHOD runs_runtime_sequence.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_integration_html_report( ) ).
    cl_abap_unit_assert=>assert_true( ls_start-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_start-page_kind
      exp = zif_gg_host_html_v1=>page_selection ).

    DATA(ls_values) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_value_help
      target     = 'P_CARR' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_values-compatibility-values[ name = 'P_CARR' ]-ranges )
      exp = 3 ).

    DATA(ls_help) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_values-session_id
      page_id    = ls_values-page_id
      action     = zif_gg_host_html_v1=>action_help
      target     = 'P_CARR' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_help-html CS 'Enter a carrier from the integration fixture.' ) ).

    DATA(ls_invalid) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_help-session_id
      page_id    = ls_help-page_id
      action     = zif_gg_host_html_v1=>action_submit
      values     = VALUE #( ( name = 'P_CARR' value = 'ZZZ' ) ) ) ).
    cl_abap_unit_assert=>assert_true( ls_invalid-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_invalid-messages[ 1 ]-text
      exp = 'Unknown carrier' ).

    DATA(ls_list) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_invalid-session_id
      page_id    = ls_invalid-page_id
      action     = zif_gg_host_html_v1=>action_submit
      values     = VALUE #( ( name = 'P_CARR' value = 'AA' ) ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_list-page_kind
      exp = zif_gg_host_html_v1=>page_list ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_list-compatibility-lines[ table_line = 'AA/0018 20260115' ] ) ) ).

    DATA(ls_detail) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_list-session_id
      page_id    = ls_list-page_id
      action     = zif_gg_host_html_v1=>action_line
      row        = 2
      token      = 'H-1-2' ) ).
    cl_abap_unit_assert=>assert_true( ls_detail-valid ).
    DATA(lv_detail_found) = xsdbool( line_exists( ls_detail-compatibility-lines[
      table_line = 'Selected flight: AA/0018 20260115' ] ) ).
    cl_abap_unit_assert=>assert_true( lv_detail_found ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD isolates_runtime_sessions.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_first) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_integration_html_report( ) ).
    DATA(ls_second) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_integration_html_report( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_first-session_id
                                        exp = 'HOST-1' ).
    cl_abap_unit_assert=>assert_equals( act = ls_second-session_id
                                        exp = 'HOST-2' ).

    DATA(ls_first_list) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_first-session_id
      page_id    = ls_first-page_id
      action     = zif_gg_host_html_v1=>action_submit
      values     = VALUE #( ( name = 'P_CARR' value = 'AA' ) ) ) ).
    DATA(ls_second_list) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_second-session_id
      page_id    = ls_second-page_id
      action     = zif_gg_host_html_v1=>action_submit
      values     = VALUE #( ( name = 'P_CARR' value = 'LH' ) ) ) ).
    DATA(lv_first_aa) = xsdbool( ls_first_list-html CS 'AA/0017 20260101' ).
    DATA(lv_second_lh) = xsdbool( ls_second_list-html CS 'LH/0400 20260228' ).
    DATA(lv_first_lh) = xsdbool( ls_first_list-html CS 'LH/0400 20260228' ).
    DATA(lv_second_aa) = xsdbool( ls_second_list-html CS 'AA/0017 20260101' ).
    cl_abap_unit_assert=>assert_true( lv_first_aa ).
    cl_abap_unit_assert=>assert_true( lv_second_lh ).
    cl_abap_unit_assert=>assert_false( lv_first_lh ).
    cl_abap_unit_assert=>assert_false( lv_second_aa ).

    zcl_gg_host_runtime=>close( ls_first-session_id ).
    DATA(ls_closed) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_first_list-session_id
      page_id    = ls_first_list-page_id
      action     = zif_gg_host_html_v1=>action_line
      row        = 1
      token      = 'H-1-1' ) ).
    cl_abap_unit_assert=>assert_false( ls_closed-valid ).
    DATA(ls_second_again) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_second_list-session_id
      page_id    = ls_second_list-page_id
      action     = zif_gg_host_html_v1=>action_line
      row        = 1
      token      = 'H-1-1' ) ).
    cl_abap_unit_assert=>assert_true( ls_second_again-valid ).

    zcl_gg_host_runtime=>clear( ).
    DATA(ls_reset) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_integration_html_report( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_reset-session_id
                                        exp = 'HOST-1' ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
