CLASS ltcl_gg_table_tree_base DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS alv_grid FOR TESTING.
    METHODS alv_edit FOR TESTING.
    METHODS alv_criteria FOR TESTING.
    METHODS alv_selection FOR TESTING.
    METHODS alv_events FOR TESTING.
    METHODS simple_tree FOR TESTING.
    METHODS column_trees FOR TESTING.
    METHODS tree_events FOR TESTING.
    METHODS alv_tree FOR TESTING.
    METHODS salv_basics FOR TESTING.
    METHODS salv_aggregation FOR TESTING.
    METHODS salv_layout FOR TESTING.
    METHODS salv_events FOR TESTING.
    METHODS bar_chart FOR TESTING.
    METHODS chart_engine FOR TESTING.
    METHODS rejects_undeclared_command FOR TESTING.
    METHODS check_html
      IMPORTING
        io_report TYPE REF TO zif_gg_report_v1
        iv_text   TYPE string.
    METHODS check_command
      IMPORTING
        io_report TYPE REF TO zif_gg_report_v1
        iv_ucomm  TYPE string
        iv_text   TYPE string.
ENDCLASS.

CLASS ltcl_gg_table_tree_base IMPLEMENTATION.

  METHOD alv_grid.
    check_html( io_report = NEW zcl_gg_ex_135( ) iv_text = 'data-control-kind="ALV_GRID"' ).
    check_html( io_report = NEW zcl_gg_ex_135( ) iv_text = 'Lufthansa' ).
  ENDMETHOD.

  METHOD alv_edit.
    check_html( io_report = NEW zcl_gg_ex_136( ) iv_text = 'Editable ALV grid' ).
    check_command( io_report = NEW zcl_gg_ex_136( ) iv_ucomm = 'SAVE_GRID' iv_text = 'changed data accepted' ).
  ENDMETHOD.

  METHOD alv_criteria.
    check_html( io_report = NEW zcl_gg_ex_137( ) iv_text = 'data-criteria="server-owned"' ).
    check_command( io_report = NEW zcl_gg_ex_137( ) iv_ucomm = 'APPLY_CRITERIA' iv_text = 'criteria applied server-side' ).
  ENDMETHOD.

  METHOD alv_selection.
    check_html( io_report = NEW zcl_gg_ex_138( ) iv_text = 'FLIGHT-2' ).
    check_command( io_report = NEW zcl_gg_ex_138( ) iv_ucomm = 'SELECT_ROW' iv_text = 'opaque row' ).
  ENDMETHOD.

  METHOD alv_events.
    check_html( io_report = NEW zcl_gg_ex_139( ) iv_text = 'ALV toolbar event' ).
    check_command( io_report = NEW zcl_gg_ex_139( ) iv_ucomm = 'ALV_EVENT' iv_text = 'event delivered' ).
  ENDMETHOD.

  METHOD simple_tree.
    check_html( io_report = NEW zcl_gg_ex_140( ) iv_text = 'Simple tree' ).
    check_html( io_report = NEW zcl_gg_ex_140( ) iv_text = 'Hidden audit node' ).
  ENDMETHOD.

  METHOD column_trees.
    check_html( io_report = NEW zcl_gg_ex_141( ) iv_text = 'Column tree' ).
    check_html( io_report = NEW zcl_gg_ex_141( ) iv_text = 'On time' ).
  ENDMETHOD.

  METHOD tree_events.
    check_html( io_report = NEW zcl_gg_ex_142( ) iv_text = 'NODE-LH400' ).
    check_command( io_report = NEW zcl_gg_ex_142( ) iv_ucomm = 'TREE_SELECT' iv_text = 'node NODE-LH400' ).
  ENDMETHOD.

  METHOD alv_tree.
    check_html( io_report = NEW zcl_gg_ex_143( ) iv_text = 'data-control-kind="ALV_TREE"' ).
    check_html( io_report = NEW zcl_gg_ex_143( ) iv_text = 'LH400' ).
  ENDMETHOD.

  METHOD salv_basics.
    check_html( io_report = NEW zcl_gg_ex_144( ) iv_text = 'SALV table basics' ).
    check_html( io_report = NEW zcl_gg_ex_144( ) iv_text = 'Functions: sort, filter, export' ).
  ENDMETHOD.

  METHOD salv_aggregation.
    check_html( io_report = NEW zcl_gg_ex_145( ) iv_text = 'data-aggregation="total"' ).
    check_command( io_report = NEW zcl_gg_ex_145( ) iv_ucomm = 'SALV_FILTER' iv_text = 'SALV filter applied' ).
  ENDMETHOD.

  METHOD salv_layout.
    check_html( io_report = NEW zcl_gg_ex_146( ) iv_text = 'SALV header and layout' ).
    check_html( io_report = NEW zcl_gg_ex_146( ) iv_text = 'Prepared by the analytics team' ).
  ENDMETHOD.

  METHOD salv_events.
    check_html( io_report = NEW zcl_gg_ex_147( ) iv_text = 'ROW-2' ).
    check_command( io_report = NEW zcl_gg_ex_147( ) iv_ucomm = 'SALV_LINK' iv_text = 'SALV link event' ).
  ENDMETHOD.

  METHOD bar_chart.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_148( ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-control-kind="BARCHART"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'Flights by carrier' ) ).
  ENDMETHOD.

  METHOD chart_engine.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_149( ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-control-kind="CHART_ENGINE"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'series=flights' ) ).
  ENDMETHOD.

  METHOD rejects_undeclared_command.
    DATA lt_reports TYPE STANDARD TABLE OF REF TO zif_gg_report_v1 WITH DEFAULT KEY.
    APPEND NEW zcl_gg_ex_136( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_137( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_138( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_139( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_142( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_145( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_147( ) TO lt_reports.
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
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD check_html.
    DATA(ls_result) = zcl_gg_host=>run( io_report = io_report ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS iv_text ) ).
  ENDMETHOD.

  METHOD check_command.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report        = io_report
      iv_user_command  = CONV #( iv_ucomm ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS iv_text ) ).
  ENDMETHOD.

ENDCLASS.
