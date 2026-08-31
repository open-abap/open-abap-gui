CLASS ltcl_gg_control_showcase_base DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS custom_container FOR TESTING.
    METHODS splitter FOR TESTING.
    METHODS easy_splitter FOR TESTING.
    METHODS docking FOR TESTING.
    METHODS dialogbox FOR TESTING.
    METHODS textedit FOR TESTING.
    METHODS readonly_textedit FOR TESTING.
    METHODS picture FOR TESTING.
    METHODS toolbar FOR TESTING.
    METHODS calendar FOR TESTING.
    METHODS selector FOR TESTING.
    METHODS html_viewer FOR TESTING.
    METHODS dynamic_document FOR TESTING.
    METHODS document_events FOR TESTING.
    METHODS nested_registry FOR TESTING.
    METHODS refresh FOR TESTING.
    METHODS validation FOR TESTING.
    METHODS document_editor FOR TESTING.
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

CLASS ltcl_gg_control_showcase_base IMPLEMENTATION.

  METHOD custom_container.
    check_html( io_report = NEW zcl_gg_ex_117( )
                iv_text   = 'CUSTOM_CONTAINER' ).
  ENDMETHOD.

  METHOD splitter.
    check_html( io_report = NEW zcl_gg_ex_118( )
                iv_text   = 'SPLITTER_CONTAINER' ).
  ENDMETHOD.

  METHOD easy_splitter.
    check_html( io_report = NEW zcl_gg_ex_119( )
                iv_text   = 'EASY_SPLITTER' ).
  ENDMETHOD.

  METHOD docking.
    check_html( io_report = NEW zcl_gg_ex_120( )
                iv_text   = 'DOCKING_CONTAINER' ).
  ENDMETHOD.

  METHOD dialogbox.
    check_html( io_report = NEW zcl_gg_ex_121( )
                iv_text   = 'DIALOGBOX_CONTAINER' ).
  ENDMETHOD.

  METHOD textedit.
    check_html( io_report = NEW zcl_gg_ex_122( )
                iv_text   = '<textarea' ).
  ENDMETHOD.

  METHOD readonly_textedit.
    check_html( io_report = NEW zcl_gg_ex_123( )
                iv_text   = '<textarea' ).
  ENDMETHOD.

  METHOD picture.
    check_html( io_report = NEW zcl_gg_ex_124( )
                iv_text   = 'PICTURE' ).
  ENDMETHOD.

  METHOD toolbar.
    check_html( io_report = NEW zcl_gg_ex_125( )
                iv_text   = 'role="toolbar"' ).
    check_command( io_report = NEW zcl_gg_ex_125( )
                   iv_ucomm  = 'RUN'
      iv_text                = 'toolbar RUN dispatched by the server' ).
  ENDMETHOD.

  METHOD calendar.
    check_html( io_report = NEW zcl_gg_ex_126( )
                iv_text   = 'aria-label="Calendar"' ).
  ENDMETHOD.

  METHOD selector.
    check_html( io_report = NEW zcl_gg_ex_127( )
                iv_text   = 'aria-label="Selector"' ).
  ENDMETHOD.

  METHOD html_viewer.
    check_html( io_report = NEW zcl_gg_ex_128( )
                iv_text   = 'title="HTML viewer"' ).
  ENDMETHOD.

  METHOD dynamic_document.
    check_html( io_report = NEW zcl_gg_ex_129( )
                iv_text   = 'Dynamic document' ).
    check_command( io_report = NEW zcl_gg_ex_129( )
                   iv_ucomm  = 'SAVE_DOC'
      iv_text                = 'document saved by the server' ).
  ENDMETHOD.

  METHOD document_events.
    check_html( io_report = NEW zcl_gg_ex_130( )
                iv_text   = 'Typed event dispatch' ).
    check_command( io_report = NEW zcl_gg_ex_130( )
                   iv_ucomm  = 'OPEN_DOC'
      iv_text                = 'event OPEN_DOC dispatched by the server' ).
  ENDMETHOD.

  METHOD nested_registry.
    check_html( io_report = NEW zcl_gg_ex_131( )
                iv_text   = 'CUSTOM_CONTAINER' ).
    check_command( io_report = NEW zcl_gg_ex_131( )
                   iv_ucomm  = 'APPLY'
      iv_text                = 'nested control action applied by the server' ).
  ENDMETHOD.

  METHOD refresh.
    check_html( io_report = NEW zcl_gg_ex_132( )
                iv_text   = 'CUSTOM_CONTAINER' ).
    check_command( io_report = NEW zcl_gg_ex_132( )
                   iv_ucomm  = 'REFRESH'
      iv_text                = 'control refresh 1' ).
  ENDMETHOD.

  METHOD validation.
    check_html( io_report = NEW zcl_gg_ex_133( )
                iv_text   = 'data-control-id' ).
  ENDMETHOD.

  METHOD document_editor.
    check_html( io_report = NEW zcl_gg_ex_134( )
                iv_text   = 'CUSTOM_CONTAINER' ).
  ENDMETHOD.

  METHOD check_html.
    DATA(ls_result) = zcl_gg_host=>run( io_report = io_report ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS iv_text ) ).
  ENDMETHOD.

  METHOD rejects_undeclared_command.
    DATA lt_reports TYPE STANDARD TABLE OF REF TO zif_gg_report_v1 WITH DEFAULT KEY.
    APPEND NEW zcl_gg_ex_125( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_129( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_130( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_131( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_132( ) TO lt_reports.
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

  METHOD check_command.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = io_report ).
    DATA(ls_result) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_command
      ucomm      = iv_ucomm ) ).
    cl_abap_unit_assert=>assert_true( act = ls_result-valid ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS iv_text ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
