CLASS ltcl_gg_rich_list_base DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS paging FOR TESTING.
    METHODS find_next FOR TESTING.
    METHODS print_view FOR TESTING.
    METHODS download FOR TESTING.
    METHODS rejects_undeclared_command FOR TESTING.
ENDCLASS.

CLASS ltcl_gg_rich_list_base IMPLEMENTATION.

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

  METHOD rejects_undeclared_command.
    DATA lt_line_reports TYPE STANDARD TABLE OF REF TO zif_gg_report_v1 WITH DEFAULT KEY.
    DATA lt_reports TYPE STANDARD TABLE OF REF TO zif_gg_report_v1 WITH DEFAULT KEY.
    APPEND NEW zcl_gg_ex_085( ) TO lt_reports.
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

ENDCLASS.
