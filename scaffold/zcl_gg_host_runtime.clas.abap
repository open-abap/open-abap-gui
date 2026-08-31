CLASS zcl_gg_host_runtime DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Stateful, transport-neutral session facade for HTML clients. The existing
* zcl_gg_host=>run remains the deterministic single-request API; this class
* owns the server-side state needed between browser requests.

  PUBLIC SECTION.
    CLASS-METHODS start
      IMPORTING
        io_report                TYPE REF TO zif_gg_report_v1 OPTIONAL
        io_dynpro_program        TYPE REF TO zif_gg_dynpro_v1 OPTIONAL
        io_submit_report         TYPE REF TO zif_gg_report_v1 OPTIONAL
        iv_program               TYPE zif_gg_session_types_v1=>ty_program OPTIONAL
        iv_batch                 TYPE abap_bool DEFAULT abap_false
        iv_selection_screen_only TYPE abap_bool DEFAULT abap_false
        it_input                 TYPE zif_gg_selection_screen_types=>ty_values OPTIONAL
      RETURNING
        VALUE(rs_response)       TYPE zif_gg_host_html_v1=>ty_response.

    CLASS-METHODS dispatch
      IMPORTING
        is_request         TYPE zif_gg_host_html_v1=>ty_request
      RETURNING
        VALUE(rs_response) TYPE zif_gg_host_html_v1=>ty_response.

    CLASS-METHODS close
      IMPORTING
        iv_session_id TYPE string.

    CLASS-METHODS close_current
      IMPORTING
        iv_session_id   TYPE string
        iv_page_id      TYPE string
      RETURNING
        VALUE(rv_error) TYPE string.

    CLASS-METHODS clear.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_session,
             session_id         TYPE string,
             program            TYPE zif_gg_session_types_v1=>ty_program,
             batch              TYPE abap_bool,
             report             TYPE REF TO zif_gg_report_v1,
             submit_report      TYPE REF TO zif_gg_report_v1,
             dynpro_program     TYPE REF TO zif_gg_dynpro_v1,
             next_page          TYPE i,
             pending_navigation TYPE zif_gg_host_html_v1=>ty_navigation,
             pending_submit     TYPE zif_gg_session_types_v1=>ty_submit,
             last_result        TYPE zcl_gg_host=>ty_result,
             last_dynpro        TYPE zcl_gg_host_dynpro=>ty_result,
             results            TYPE STANDARD TABLE OF zcl_gg_host=>ty_result WITH DEFAULT KEY,
             pages              TYPE zif_gg_host_html_v1=>ty_pages,
           END OF ty_session.
    TYPES ty_sessions TYPE STANDARD TABLE OF ty_session WITH DEFAULT KEY.

    CLASS-DATA mt_sessions TYPE ty_sessions.
    CLASS-DATA mv_session_id TYPE i.

    CLASS-METHODS next_session_id
      RETURNING
        VALUE(rv_id) TYPE string.

    CLASS-METHODS response_for
      IMPORTING
        is_session         TYPE ty_session
      RETURNING
        VALUE(rs_response) TYPE zif_gg_host_html_v1=>ty_response.

    CLASS-METHODS invalid_response
      IMPORTING
        iv_error           TYPE string
      RETURNING
        VALUE(rs_response) TYPE zif_gg_host_html_v1=>ty_response.

    CLASS-METHODS action_error
      IMPORTING
        is_request      TYPE zif_gg_host_html_v1=>ty_request
        is_page         TYPE zif_gg_host_html_v1=>ty_page
      RETURNING
        VALUE(rv_error) TYPE string.

    CLASS-METHODS dispatch_dynpro
      IMPORTING
        is_request         TYPE zif_gg_host_html_v1=>ty_request
        is_session         TYPE ty_session
      RETURNING
        VALUE(rs_response) TYPE zif_gg_host_html_v1=>ty_response.

    CLASS-METHODS dispatch_report
      IMPORTING
        is_request         TYPE zif_gg_host_html_v1=>ty_request
        is_session         TYPE ty_session
      RETURNING
        VALUE(rs_response) TYPE zif_gg_host_html_v1=>ty_response.

    CLASS-METHODS report_for_submit
      IMPORTING
        iv_program       TYPE zif_gg_session_types_v1=>ty_program
      RETURNING
        VALUE(ro_report) TYPE REF TO zif_gg_report_v1.
ENDCLASS.

CLASS zcl_gg_host_runtime IMPLEMENTATION.

  METHOD start.
    DATA ls_session TYPE ty_session.
    DATA lv_session_id TYPE string.
    DATA ls_result TYPE zcl_gg_host=>ty_result.
    DATA ls_dynpro TYPE zcl_gg_host_dynpro=>ty_result.

    lv_session_id = next_session_id( ).
    IF io_dynpro_program IS BOUND.
      ls_dynpro = zcl_gg_host_dynpro=>run(
        io_program    = io_dynpro_program
        iv_submitted  = abap_false
        iv_session_id = lv_session_id
        iv_page_id    = |{ lv_session_id }-1| ).
    ELSEIF io_report IS BOUND.
      ls_result = zcl_gg_host=>run(
        io_report              = io_report
        io_submit_report       = io_submit_report
        iv_program             = iv_program
        iv_batch               = iv_batch
        it_input               = it_input
        iv_stop_before_start   = iv_selection_screen_only
        iv_session_id          = lv_session_id
        iv_page_id             = |{ lv_session_id }-1|
        iv_pause_at_navigation = abap_true ).
    ELSE.
      rs_response = invalid_response( 'A report or dynpro program is required' ).
      RETURN.
    ENDIF.
    ls_session-session_id = lv_session_id.
    ls_session-program = iv_program.
    ls_session-batch = iv_batch.
    ls_session-report = io_report.
    ls_session-submit_report = io_submit_report.
    ls_session-dynpro_program = io_dynpro_program.
    ls_session-next_page = 2.
    IF io_dynpro_program IS BOUND.
      ls_session-last_dynpro = ls_dynpro.
      APPEND ls_dynpro-page TO ls_session-pages.
    ELSE.
      ls_session-last_result = ls_result.
      IF ls_result-navigation-kind = zcx_gg_control_flow=>kind_call_selection_screen
          OR ls_result-navigation-kind = zcx_gg_control_flow=>kind_call_screen
          OR ls_result-navigation-kind = zcx_gg_control_flow=>kind_submit_return
          OR ls_result-navigation-kind = zcx_gg_control_flow=>kind_call_transaction.
        ls_session-pending_navigation = ls_result-navigation.
      ENDIF.
      ls_session-pending_submit = ls_result-submit.
      APPEND ls_result TO ls_session-results.
      APPEND ls_result-page TO ls_session-pages.
    ENDIF.
    APPEND ls_session TO mt_sessions.
    rs_response = response_for( ls_session ).
  ENDMETHOD.

  METHOD dispatch.
    DATA ls_session TYPE ty_session.
    DATA lv_current_page_id TYPE string.
    DATA ls_current_page TYPE zif_gg_host_html_v1=>ty_page.
    DATA lv_action_error TYPE string.

    READ TABLE mt_sessions INTO ls_session
      WITH KEY session_id = is_request-session_id.
    IF sy-subrc <> 0.
      rs_response = invalid_response( 'Unknown host session' ).
      RETURN.
    ENDIF.
    IF ls_session-dynpro_program IS BOUND.
      lv_current_page_id = ls_session-last_dynpro-page_id.
      ls_current_page = ls_session-last_dynpro-page.
    ELSE.
      lv_current_page_id = ls_session-last_result-page_id.
      ls_current_page = ls_session-last_result-page.
    ENDIF.
    IF is_request-page_id <> lv_current_page_id.
      rs_response = invalid_response( 'Stale host page' ).
      RETURN.
    ENDIF.
    IF ( ls_session-dynpro_program IS BOUND
        AND ls_session-last_dynpro-terminal_state = abap_true )
        OR ( ls_session-dynpro_program IS NOT BOUND
        AND ls_session-last_result-page_kind = zif_gg_host_html_v1=>page_terminal ).
      rs_response = invalid_response( 'Host session is terminal' ).
      RETURN.
    ENDIF.
    IF is_request-action IS INITIAL
        OR ( ls_session-dynpro_program IS BOUND
        AND is_request-action <> zif_gg_host_html_v1=>action_submit
        AND is_request-action <> zif_gg_host_html_v1=>action_command
        AND is_request-action <> zif_gg_host_html_v1=>action_pf
        AND is_request-action <> zif_gg_host_html_v1=>action_tab
        AND is_request-action <> zif_gg_host_html_v1=>action_screen
        AND is_request-action <> zif_gg_host_html_v1=>action_back
        AND is_request-action <> zif_gg_host_html_v1=>action_help
        AND is_request-action <> zif_gg_host_html_v1=>action_value_help
        AND is_request-action <> zif_gg_host_html_v1=>action_exit ).
      rs_response = invalid_response( 'Missing or unknown host action' ).
      RETURN.
    ENDIF.
    lv_action_error = action_error(
      is_request = is_request
      is_page    = ls_current_page ).
    IF lv_action_error IS NOT INITIAL.
      rs_response = invalid_response( lv_action_error ).
      RETURN.
    ENDIF.
    IF is_request-action = zif_gg_host_html_v1=>action_screen
        AND ( is_request-target IS INITIAL
          OR is_request-target CN '0123456789' ).
      rs_response = invalid_response( 'Invalid screen target' ).
      RETURN.
    ENDIF.
    IF is_request-action = zif_gg_host_html_v1=>action_line.
      IF is_request-row < 1
          OR is_request-row > lines( ls_session-last_result-render_lines ).
        rs_response = invalid_response( 'Invalid list row' ).
        RETURN.
      ENDIF.
      IF is_request-token IS INITIAL
          OR is_request-token <> ls_session-last_result-render_lines[ is_request-row ]-token.
        rs_response = invalid_response( 'Invalid list action token' ).
        RETURN.
      ENDIF.
    ENDIF.
    IF ls_session-dynpro_program IS BOUND.
      rs_response = dispatch_dynpro(
        is_request = is_request
        is_session = ls_session ).
      RETURN.
    ENDIF.
    rs_response = dispatch_report(
      is_request = is_request
      is_session = ls_session ).
  ENDMETHOD.

  METHOD dispatch_dynpro.
    DATA ls_session TYPE ty_session.
    DATA ls_dynpro TYPE zcl_gg_host_dynpro=>ty_result.
    DATA lt_dynpro_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    DATA lv_ucomm TYPE zif_gg_dynpro_types_v1=>ty_ucomm.
    DATA lv_page_id TYPE string.
    DATA ls_transaction TYPE zcl_gg_transaction_registry=>ty_transaction.
    DATA lo_object TYPE REF TO object.
    DATA lo_report TYPE REF TO zif_gg_report_v1.
    DATA lo_dynpro TYPE REF TO zif_gg_dynpro_v1.

    ls_session = is_session.
    lt_dynpro_values = is_request-dynpro_values.
    IF lt_dynpro_values IS INITIAL.
      lt_dynpro_values = ls_session-last_dynpro-values.
    ENDIF.
    lv_ucomm = CONV zif_gg_dynpro_types_v1=>ty_ucomm( is_request-ucomm ).
    IF lv_ucomm IS INITIAL.
      lv_ucomm = 'BACK'.
    ENDIF.
    lv_page_id = |{ ls_session-session_id }-{ ls_session-next_page }|.
    ls_dynpro = zcl_gg_host_dynpro=>run(
      io_program       = ls_session-dynpro_program
      iv_ucomm         = lv_ucomm
      iv_submitted     = xsdbool( is_request-action <> zif_gg_host_html_v1=>action_help
                                  AND is_request-action <> zif_gg_host_html_v1=>action_value_help )
      it_values        = lt_dynpro_values
      iv_field         = CONV zif_gg_dynpro_types_v1=>ty_name( is_request-target )
      iv_row           = is_request-row
      iv_cursor_field  = CONV zif_gg_dynpro_types_v1=>ty_name( is_request-cursor_field )
      iv_value_request = CONV zif_gg_dynpro_types_v1=>ty_name(
                           COND string( WHEN is_request-action = zif_gg_host_html_v1=>action_value_help
                                        THEN is_request-target ELSE `` ) )
      iv_help_request  = CONV zif_gg_dynpro_types_v1=>ty_name(
                           COND string( WHEN is_request-action = zif_gg_host_html_v1=>action_help
                                        THEN is_request-target ELSE `` ) )
      iv_screen        = ls_session-last_dynpro-screen
      iv_session_id    = ls_session-session_id
      iv_page_id       = lv_page_id ).
    IF ls_dynpro-navigation-kind = zcx_gg_control_flow=>kind_call_transaction
        OR ls_dynpro-navigation-kind = zcx_gg_control_flow=>kind_leave_to_transaction.
      ls_transaction = zcl_gg_transaction_registry=>lookup( iv_tcode = ls_dynpro-navigation-target ).
      IF ls_transaction-tcode IS INITIAL.
        rs_response = invalid_response( 'Transaction target is unknown or not authorized.' ).
        RETURN.
      ENDIF.
      TRY.
          CREATE OBJECT lo_object TYPE (ls_transaction-class_name).
          CASE ls_transaction-kind.
            WHEN zcl_gg_transaction_registry=>kind_report.
              lo_report ?= lo_object.
              close( ls_session-session_id ).
              rs_response = start( io_report = lo_report ).
            WHEN zcl_gg_transaction_registry=>kind_dynpro.
              lo_dynpro ?= lo_object.
              close( ls_session-session_id ).
              rs_response = start( io_dynpro_program = lo_dynpro ).
            WHEN OTHERS.
              rs_response = invalid_response( 'Transaction target has an unsupported executable kind.' ).
          ENDCASE.
        CATCH cx_root INTO DATA(lx_transaction).
          rs_response = invalid_response( |Unable to launch transaction target: { lx_transaction->get_text( ) }| ).
      ENDTRY.
      RETURN.
    ENDIF.
    IF ls_dynpro-navigation-kind = zcx_gg_control_flow=>kind_submit_return.
      lo_report = report_for_submit( CONV #( ls_dynpro-navigation-target ) ).
      IF lo_report IS NOT BOUND.
        rs_response = invalid_response( 'Submitted report is unknown or not executable.' ).
        RETURN.
      ENDIF.
      close( ls_session-session_id ).
      rs_response = start(
        io_report                = lo_report
        it_input                 = ls_dynpro-submit-values
        iv_selection_screen_only = ls_dynpro-submit-via_selection_screen ).
      RETURN.
    ENDIF.
    ls_session-next_page = ls_session-next_page + 1.
    ls_session-last_dynpro = ls_dynpro.
    APPEND ls_dynpro-page TO ls_session-pages.
    READ TABLE mt_sessions INTO DATA(ls_old_dynpro)
      WITH KEY session_id = ls_session-session_id.
    DATA(lv_index) = sy-tabix.
    IF sy-subrc = 0.
      MODIFY mt_sessions FROM ls_session INDEX lv_index.
    ENDIF.
    rs_response = response_for( ls_session ).
  ENDMETHOD.

  METHOD dispatch_report.
    DATA ls_session TYPE ty_session.
    DATA ls_result TYPE zcl_gg_host=>ty_result.
    DATA lv_index TYPE i.
    DATA lv_page_id TYPE string.
    DATA lv_ucomm TYPE zif_gg_session_types_v1=>ty_ucomm.
    DATA lt_input TYPE zif_gg_selection_screen_types=>ty_values.

    ls_session = is_session.
    lt_input = is_request-values.
    IF lt_input IS INITIAL.
      lt_input = ls_session-last_result-values.
    ENDIF.
    lv_ucomm = CONV zif_gg_session_types_v1=>ty_ucomm( is_request-ucomm ).
    IF lv_ucomm IS INITIAL.
      lv_ucomm = COND #( WHEN is_request-action = zif_gg_host_html_v1=>action_exit
                         THEN 'ECAN'
                         ELSE 'ONLI' ).
    ENDIF.
    IF ls_session-submit_report IS NOT BOUND
        AND ls_session-pending_navigation-kind = zcx_gg_control_flow=>kind_submit_return.
      ls_session-submit_report = report_for_submit( ls_session-pending_submit-program ).
    ENDIF.
    lv_page_id = |{ ls_session-session_id }-{ ls_session-next_page }|.

    IF is_request-action = zif_gg_host_html_v1=>action_back
        AND lines( ls_session-results ) <= 1.
      rs_response = invalid_response( 'No host back target' ).
      RETURN.
    ENDIF.
    IF is_request-action = zif_gg_host_html_v1=>action_back.
      DELETE ls_session-results INDEX lines( ls_session-results ).
      READ TABLE ls_session-results INTO ls_session-last_result INDEX lines( ls_session-results ).
      CLEAR ls_session-pending_navigation.
      CLEAR ls_session-pending_submit.
      rs_response = response_for( ls_session ).
      READ TABLE mt_sessions INTO DATA(ls_old_back)
        WITH KEY session_id = ls_session-session_id.
      lv_index = sy-tabix.
      IF sy-subrc = 0.
        MODIFY mt_sessions FROM ls_session INDEX lv_index.
      ENDIF.
      RETURN.
    ENDIF.

    CASE is_request-action.
      WHEN zif_gg_host_html_v1=>action_line.
        lv_index = is_request-row.
        ls_result = zcl_gg_host=>run(
          io_report              = ls_session-report
          io_submit_report       = ls_session-submit_report
          iv_program             = ls_session-program
          iv_batch               = ls_session-batch
          it_input               = lt_input
          iv_line_index          = lv_index
          iv_line_level          = 1
          iv_cursor_field        = CONV zif_gg_session_types_v1=>ty_name( is_request-cursor_field )
          iv_cursor_value        = is_request-cursor_value
          iv_session_id          = ls_session-session_id
          iv_page_id             = lv_page_id
          iv_can_back            = xsdbool( lines( ls_session-results ) > 0 )
          iv_pause_at_navigation = abap_true ).
      WHEN zif_gg_host_html_v1=>action_command.
        ls_result = zcl_gg_host=>run(
          io_report              = ls_session-report
          io_submit_report       = ls_session-submit_report
          iv_program             = ls_session-program
          iv_batch               = ls_session-batch
          it_input               = lt_input
          iv_user_command        = CONV zif_gg_list_processing_types_v1=>ty_ucomm( is_request-ucomm )
          iv_session_id          = ls_session-session_id
          iv_page_id             = lv_page_id
          iv_can_back            = xsdbool( lines( ls_session-results ) > 0 )
          iv_pause_at_navigation = abap_true ).
      WHEN zif_gg_host_html_v1=>action_pf.
        ls_result = zcl_gg_host=>run(
          io_report              = ls_session-report
          iv_program             = ls_session-program
          iv_batch               = ls_session-batch
          it_input               = lt_input
          iv_pf_key              = is_request-pf_key
          iv_session_id          = ls_session-session_id
          iv_page_id             = lv_page_id
          iv_can_back            = xsdbool( lines( ls_session-results ) > 0 )
          iv_pause_at_navigation = abap_true ).
      WHEN zif_gg_host_html_v1=>action_help.
        ls_result = zcl_gg_host=>run(
          io_report              = ls_session-report
          iv_program             = ls_session-program
          iv_batch               = ls_session-batch
          it_input               = lt_input
          iv_help_name           = CONV zif_gg_session_types_v1=>ty_name( is_request-target )
          iv_session_id          = ls_session-session_id
          iv_page_id             = lv_page_id
          iv_can_back            = xsdbool( lines( ls_session-results ) > 0 )
          iv_pause_at_navigation = abap_true ).
      WHEN zif_gg_host_html_v1=>action_value_help.
        ls_result = zcl_gg_host=>run(
          io_report              = ls_session-report
          iv_program             = ls_session-program
          iv_batch               = ls_session-batch
          it_input               = lt_input
          iv_value_request       = CONV zif_gg_session_types_v1=>ty_name( is_request-target )
          iv_session_id          = ls_session-session_id
          iv_page_id             = lv_page_id
          iv_can_back            = xsdbool( lines( ls_session-results ) > 0 )
          iv_pause_at_navigation = abap_true ).
      WHEN zif_gg_host_html_v1=>action_exit.
        ls_result = zcl_gg_host=>run(
          io_report     = ls_session-report
          iv_program    = ls_session-program
          iv_batch      = ls_session-batch
          it_input      = lt_input
          iv_exit_ucomm = lv_ucomm
          iv_ucomm      = lv_ucomm
          iv_session_id = ls_session-session_id
          iv_page_id    = lv_page_id
          iv_can_back   = xsdbool( lines( ls_session-results ) > 0 ) ).
      WHEN zif_gg_host_html_v1=>action_submit
          OR zif_gg_host_html_v1=>action_tab
          OR zif_gg_host_html_v1=>action_back.
        ls_result = zcl_gg_host=>run(
          io_report              = ls_session-report
          io_submit_report       = ls_session-submit_report
          iv_program             = ls_session-program
          iv_batch               = ls_session-batch
          it_input               = lt_input
          iv_ucomm               = lv_ucomm
          iv_user_command        = COND #(
            WHEN is_request-ucomm IS NOT INITIAL
            THEN CONV zif_gg_list_processing_types_v1=>ty_ucomm( is_request-ucomm ) )
          iv_selection_screen    = COND #(
            WHEN ls_session-pending_navigation-kind = zcx_gg_control_flow=>kind_call_selection_screen
            THEN CONV #( ls_session-pending_navigation-target )
            ELSE '1000' )
          is_resume_navigation   = ls_session-pending_navigation
          is_resume_submit       = ls_session-pending_submit
          iv_session_id          = ls_session-session_id
          iv_page_id             = lv_page_id
          iv_can_back            = xsdbool( lines( ls_session-results ) > 0 )
          iv_pause_at_navigation = abap_true ).
      WHEN zif_gg_host_html_v1=>action_screen.
        ls_result = zcl_gg_host=>run(
          io_report              = ls_session-report
          io_submit_report       = ls_session-submit_report
          iv_program             = ls_session-program
          iv_batch               = ls_session-batch
          it_input               = lt_input
          iv_ucomm               = lv_ucomm
          iv_selection_screen    = CONV zif_gg_selection_screen_types=>ty_screen_number( is_request-target )
          iv_session_id          = ls_session-session_id
          iv_page_id             = lv_page_id
          iv_can_back            = xsdbool( lines( ls_session-results ) > 0 )
          iv_pause_at_navigation = abap_true ).
      WHEN OTHERS.
        rs_response = invalid_response( 'Unknown host action' ).
        RETURN.
    ENDCASE.

    ls_session-next_page = ls_session-next_page + 1.
    ls_session-last_result = ls_result.
    CLEAR ls_session-pending_navigation.
    IF ls_result-navigation-kind = zcx_gg_control_flow=>kind_call_selection_screen
        OR ls_result-navigation-kind = zcx_gg_control_flow=>kind_call_screen
        OR ls_result-navigation-kind = zcx_gg_control_flow=>kind_submit_return
        OR ls_result-navigation-kind = zcx_gg_control_flow=>kind_call_transaction.
      ls_session-pending_navigation = ls_result-navigation.
    ENDIF.
    ls_session-pending_submit = ls_result-submit.
    APPEND ls_result TO ls_session-results.
    APPEND ls_result-page TO ls_session-pages.
    READ TABLE mt_sessions INTO DATA(ls_old_report)
      WITH KEY session_id = ls_session-session_id.
    lv_index = sy-tabix.
    IF sy-subrc = 0.
      MODIFY mt_sessions FROM ls_session INDEX lv_index.
    ENDIF.
    rs_response = response_for( ls_session ).
  ENDMETHOD.

  METHOD close.
    DELETE mt_sessions WHERE session_id = iv_session_id.
  ENDMETHOD.

  METHOD close_current.
    READ TABLE mt_sessions INTO DATA(ls_session)
      WITH KEY session_id = iv_session_id.
    IF sy-subrc <> 0.
      rv_error = 'Unknown host session'.
      RETURN.
    ENDIF.
    IF ls_session-dynpro_program IS BOUND.
      IF iv_page_id <> ls_session-last_dynpro-page_id.
        rv_error = 'Stale host page'.
        RETURN.
      ENDIF.
    ELSEIF iv_page_id <> ls_session-last_result-page_id.
      rv_error = 'Stale host page'.
      RETURN.
    ENDIF.
    DELETE mt_sessions WHERE session_id = iv_session_id.
  ENDMETHOD.

  METHOD report_for_submit.
    DATA lv_class_name TYPE string.

    lv_class_name = iv_program.
    TRANSLATE lv_class_name TO UPPER CASE.
    REPLACE FIRST OCCURRENCE OF 'ZGG_' IN lv_class_name WITH 'ZCL_GG_'.
    TRY.
        CREATE OBJECT ro_report TYPE (lv_class_name).
      CATCH cx_root.
        CLEAR ro_report.
    ENDTRY.
  ENDMETHOD.

  METHOD clear.
    CLEAR mt_sessions.
    CLEAR mv_session_id.
  ENDMETHOD.

  METHOD next_session_id.
    mv_session_id = mv_session_id + 1.
    rv_id = |HOST-{ mv_session_id }|.
  ENDMETHOD.

  METHOD response_for.
    rs_response-valid = abap_true.
    rs_response-session_id = is_session-session_id.
    IF is_session-dynpro_program IS BOUND.
      rs_response-page_id = is_session-last_dynpro-page_id.
      rs_response-page_kind = is_session-last_dynpro-page_kind.
      rs_response-html = is_session-last_dynpro-html.
      rs_response-messages = is_session-last_dynpro-messages.
      rs_response-compatibility-terminal = is_session-last_dynpro-terminal.
      rs_response-current_page = is_session-last_dynpro-page.
    ELSE.
      rs_response-page_id = is_session-last_result-page_id.
      rs_response-page_kind = is_session-last_result-page_kind.
      rs_response-html = is_session-last_result-html.
      rs_response-messages = is_session-last_result-messages.
      rs_response-compatibility-lines = is_session-last_result-lines.
      rs_response-compatibility-line_formats = is_session-last_result-line_formats.
      rs_response-compatibility-messages = is_session-last_result-messages.
      rs_response-compatibility-values = is_session-last_result-values.
      rs_response-compatibility-states = is_session-last_result-states.
      rs_response-compatibility-terminal = is_session-last_result-terminal.
      rs_response-current_page = is_session-last_result-page.
    ENDIF.
    rs_response-pages = is_session-pages.
  ENDMETHOD.

  METHOD invalid_response.
    rs_response-valid = abap_false.
    rs_response-error = iv_error.
  ENDMETHOD.

  METHOD action_error.
    DATA lv_ucomm TYPE zif_gg_session_types_v1=>ty_ucomm.

    IF is_request-action = zif_gg_host_html_v1=>action_command.
      lv_ucomm = CONV #( is_request-ucomm ).
      IF lv_ucomm IS INITIAL
          OR NOT line_exists( is_page-status-active_ucomm[ table_line = lv_ucomm ] )
          OR line_exists( is_page-status-excluded_ucomm[ table_line = lv_ucomm ] ).
        rv_error = 'Command is not active for the current host page'.
      ENDIF.
      RETURN.
    ENDIF.

    IF is_page-kind = zif_gg_host_html_v1=>page_list
        AND is_request-action = zif_gg_host_html_v1=>action_submit
        AND is_request-ucomm IS NOT INITIAL.
      lv_ucomm = CONV #( is_request-ucomm ).
      IF NOT line_exists( is_page-status-active_ucomm[ table_line = lv_ucomm ] )
          OR line_exists( is_page-status-excluded_ucomm[ table_line = lv_ucomm ] ).
        rv_error = 'Command is not active for the current host page'.
      ENDIF.
    ENDIF.

    IF is_request-action = zif_gg_host_html_v1=>action_pf
        AND ( is_page-kind <> zif_gg_host_html_v1=>page_list
          OR is_request-pf_key < 1
          OR NOT line_exists( is_page-status-active_pf_keys[ table_line = is_request-pf_key ] ) ).
      rv_error = 'PF key is not active for the current host page'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
