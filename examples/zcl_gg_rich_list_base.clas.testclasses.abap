CLASS ltcl_gg_rich_list_base DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS drill_down FOR TESTING.
    METHODS hidden_values FOR TESTING.
    METHODS refresh FOR TESTING.
    METHODS modify_lines FOR TESTING.
    METHODS fragments FOR TESTING.
    METHODS icons FOR TESTING.
    METHODS columns FOR TESTING.
    METHODS unicode FOR TESTING.
    METHODS unicode_text
      IMPORTING
        iv_hex         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
    METHODS page_breaks FOR TESTING.
    METHODS paging FOR TESTING.
    METHODS find_next FOR TESTING.
    METHODS print_view FOR TESTING.
    METHODS download FOR TESTING.
    METHODS messages FOR TESTING.
    METHODS list_memory FOR TESTING.
    METHODS workbench FOR TESTING.
    METHODS rejects_undeclared_command FOR TESTING.
ENDCLASS.

CLASS ltcl_gg_rich_list_base IMPLEMENTATION.

  METHOD drill_down.
    DATA lo_report TYPE REF TO zif_gg_report_v1.
    lo_report = NEW zcl_gg_ex_083( ).
    DATA(ls_detail) = zcl_gg_host=>run( io_report     = lo_report
                                        iv_line_index = 1 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_detail-lines[ table_line = 'Detail list' ] ) ) ).
    DATA(ls_subdetail) = zcl_gg_host=>run( io_report     = lo_report
                                           iv_line_index = 2 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_subdetail-lines[ table_line = 'Subdetail list' ] ) ) ).
  ENDMETHOD.

  METHOD hidden_values.
    DATA(ls_result) = zcl_gg_host=>run( io_report     = NEW zcl_gg_ex_084( )
                                        iv_line_index = 2 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-lines[ table_line = 'selected bravo' ] ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-render_lines[ 2 ]-fields[ name = 'SECRET' ]-value
                                        exp = 'bravo' ).
  ENDMETHOD.

  METHOD refresh.
    DATA(ls_result) = zcl_gg_host=>run( io_report       = NEW zcl_gg_ex_085( )
                                        iv_user_command = 'REFRESH' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-lines[ table_line = 'refreshed from server state' ] ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-status-status
                                        exp = 'REFRESHED' ).
  ENDMETHOD.

  METHOD modify_lines.
    DATA(ls_result) = zcl_gg_host=>run( io_report       = NEW zcl_gg_ex_086( )
                                        iv_user_command = 'MODIFY' ).
    cl_abap_unit_assert=>assert_true( act = ls_result-render_lines[ 1 ]-fragments[ 1 ]-format-intensified ).
    cl_abap_unit_assert=>assert_true( act = ls_result-render_lines[ 2 ]-fragments[ 1 ]-format-inverse ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-render_lines[ 1 ]-fragments )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-render_lines[ 1 ]-fields[ name = 'ROW' ]-value
                                        exp = '1' ).
  ENDMETHOD.

  METHOD fragments.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_087( ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-render_lines[ 1 ]-fragments )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_true( act = ls_result-render_lines[ 1 ]-fragments[ 1 ]-format-intensified ).
    cl_abap_unit_assert=>assert_true( act = ls_result-render_lines[ 1 ]-fragments[ 3 ]-format-inverse ).
  ENDMETHOD.

  METHOD icons.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_088( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-render_lines[ 1 ]-fragments[ 1 ]-kind
                                        exp = 'ICON' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-render_lines[ 1 ]-fragments[ 2 ]-kind
                                        exp = 'SYMBOL' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-render_lines[ 1 ]-fragments[ 3 ]-kind
                                        exp = 'CHECKBOX' ).
  ENDMETHOD.

  METHOD columns.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_089( ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-lines[ 1 ] CS '42.50' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-lines[ 1 ] CS '2026-08-30' ) ).
  ENDMETHOD.

  METHOD unicode.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_090( ) ).
    DATA(lv_text) = unicode_text( `E888AA` ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-lines[ 1 ] CS lv_text ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '&lt;wide&gt;' ) ).
  ENDMETHOD.

  METHOD page_breaks.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_091( ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lines( ls_result-model_events ) > 3 ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-lines[ table_line = 'header page 1' ] ) ) ).
  ENDMETHOD.

  METHOD paging.
    DATA lo_report TYPE REF TO zif_gg_report_v1.
    lo_report = NEW zcl_gg_ex_092( ).
    DATA(ls_result) = zcl_gg_host=>run( io_report       = lo_report
                                        iv_user_command = zif_gg_session_types_v1=>command_next_page ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-status-status
                                        exp = 'PAGE 2' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-lines[ table_line = 'Flight 4' ] ) ) ).
  ENDMETHOD.

  METHOD find_next.
    DATA(ls_result) = zcl_gg_host=>run( io_report       = NEW zcl_gg_ex_093( )
                                        iv_user_command = zif_gg_session_types_v1=>command_find ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-lines[ table_line = 'Found LH at row 1' ] ) ) ).
  ENDMETHOD.

  METHOD print_view.
    DATA(ls_result) = zcl_gg_host=>run( io_report       = NEW zcl_gg_ex_094( )
                                        iv_user_command = 'PRINT_VIEW' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-lines[ 2 ] CS 'PRINT VIEW' ) ).
  ENDMETHOD.

  METHOD download.
    DATA(ls_result) = zcl_gg_host=>run( io_report       = NEW zcl_gg_ex_095( )
                                        iv_user_command = 'DOWNLOAD' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-lines[ 4 ] CS 'flights.csv' ) ).
  ENDMETHOD.

  METHOD messages.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_096( ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-messages )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-type
                                        exp = zif_gg_session_types_v1=>message_type_success ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 2 ]-type
                                        exp = zif_gg_session_types_v1=>message_type_warning ).
  ENDMETHOD.

  METHOD list_memory.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_097( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-navigation-kind
                                        exp = 'SUBMIT_RETURN' ).
  ENDMETHOD.

  METHOD workbench.
    DATA(ls_result) = zcl_gg_host=>run( io_report       = NEW zcl_gg_ex_098( )
                                        iv_user_command = 'FILTER' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-status-status
                                        exp = 'FILTERED' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-lines[ 4 ] CS 'filtered' ) ).
  ENDMETHOD.

  METHOD rejects_undeclared_command.
    DATA lt_line_reports TYPE STANDARD TABLE OF REF TO zif_gg_report_v1 WITH DEFAULT KEY.
    DATA lt_reports TYPE STANDARD TABLE OF REF TO zif_gg_report_v1 WITH DEFAULT KEY.
    APPEND NEW zcl_gg_ex_085( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_086( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_092( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_093( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_094( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_095( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_096( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_098( ) TO lt_reports.
    LOOP AT lt_reports INTO DATA(lo_report).
      zcl_gg_host_runtime=>clear( ).
      DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = lo_report ).
      DATA(ls_bad) = zcl_gg_host_runtime=>dispatch( VALUE #(
        session_id = ls_start-session_id
        page_id    = ls_start-page_id
        action     = zif_gg_host_html_v1=>action_command
        ucomm      = 'FORGED' ) ).
      cl_abap_unit_assert=>assert_false( act = ls_bad-valid ).
      cl_abap_unit_assert=>assert_equals(
        act = ls_bad-error
        exp = 'Command is not active for the current host page' ).
    ENDLOOP.

    APPEND NEW zcl_gg_ex_083( ) TO lt_line_reports.
    APPEND NEW zcl_gg_ex_084( ) TO lt_line_reports.
    LOOP AT lt_line_reports INTO DATA(lo_line_report).
      zcl_gg_host_runtime=>clear( ).
      DATA(ls_line_start) = zcl_gg_host_runtime=>start( io_report = lo_line_report ).
      DATA(ls_line_bad) = zcl_gg_host_runtime=>dispatch( VALUE #(
        session_id = ls_line_start-session_id
        page_id    = ls_line_start-page_id
        action     = zif_gg_host_html_v1=>action_line
        row        = 1
        token      = 'FORGED' ) ).
      cl_abap_unit_assert=>assert_false( act = ls_line_bad-valid ).
      cl_abap_unit_assert=>assert_equals( act = ls_line_bad-error
                                          exp = 'Invalid list action token' ).
    ENDLOOP.
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD unicode_text.
    DATA(lv_utf8) = CONV xstring( iv_hex ).
    DATA(lo_converter) = cl_abap_conv_in_ce=>create( input    = lv_utf8
                                                     encoding = 'UTF-8' ).
    lo_converter->read( IMPORTING data = rv_text ).
  ENDMETHOD.

ENDCLASS.
