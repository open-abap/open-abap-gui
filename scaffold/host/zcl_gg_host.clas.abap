CLASS zcl_gg_host DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Drives one run of an executable program written against zif_gg_report_v1 and
* returns what came out of it.
*
* Drives the report lifecycle and projects each result into the typed HTML
* page contract. Stateful request sequencing belongs to zcl_gg_host_runtime;
* unsupported control-flow operations remain explicit in ty_result.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_result,
             lines               TYPE zcl_gg_host_list=>ty_text_lines,
             render_lines        TYPE zcl_gg_host_list=>ty_render_lines,
             model_events        TYPE zcl_gg_host_list=>ty_model_events,
             line_formats        TYPE zcl_gg_host_list=>ty_line_formats,
             messages            TYPE zcl_gg_host_session=>ty_messages,
             values              TYPE zif_gg_selection_screen_types=>ty_values,
             states              TYPE zif_gg_selection_screen_types=>ty_states,
             blocks              TYPE zcl_gg_host_screen=>ty_blocks,
             elements            TYPE zcl_gg_host_screen=>ty_elements,
             screen_snapshot     TYPE zcl_gg_host_screen=>ty_snapshot,
             memory_render_lines TYPE zcl_gg_host_list=>ty_render_lines,
             help_text           TYPE string,
             terminal            TYPE string,
             dialog_suppressed   TYPE abap_bool,
             settings            TYPE zif_gg_list_processing_types_v1=>ty_settings,
             status              TYPE zif_gg_session_types_v1=>ty_gui_status,
             title               TYPE string,
             submit              TYPE zif_gg_session_types_v1=>ty_submit,
             transaction_call    TYPE zif_gg_session_types_v1=>ty_transaction_call,
             navigation          TYPE zif_gg_host_html_v1=>ty_navigation,
             selection_active    TYPE abap_bool,
             unsupported         TYPE string,
             session_id          TYPE string,
             page_id             TYPE string,
             page_kind           TYPE string,
             html                TYPE string,
             page                TYPE zif_gg_host_html_v1=>ty_page,
             pages               TYPE zif_gg_host_html_v1=>ty_pages,
           END OF ty_result.

    CLASS-METHODS run
      IMPORTING
        io_report              TYPE REF TO zif_gg_report_v1
        io_submit_report       TYPE REF TO zif_gg_report_v1 OPTIONAL
        iv_program             TYPE zif_gg_session_types_v1=>ty_program OPTIONAL
        iv_selection_screen    TYPE zif_gg_selection_screen_types=>ty_screen_number DEFAULT '1000'
        iv_batch               TYPE abap_bool DEFAULT abap_false
        it_input               TYPE zif_gg_selection_screen_types=>ty_values OPTIONAL
        it_retry_input         TYPE zif_gg_selection_screen_types=>ty_values OPTIONAL
        iv_ucomm               TYPE zif_gg_session_types_v1=>ty_ucomm DEFAULT 'ONLI'
        iv_value_request       TYPE zif_gg_selection_screen_types=>ty_name OPTIONAL
        iv_help_name           TYPE zif_gg_selection_screen_types=>ty_name OPTIONAL
        iv_exit_ucomm          TYPE zif_gg_selection_screen_types=>ty_ucomm OPTIONAL
        iv_line_index          TYPE i OPTIONAL
        iv_line_level          TYPE i DEFAULT 1
        iv_user_command        TYPE zif_gg_list_processing_types_v1=>ty_ucomm OPTIONAL
        iv_cursor_field        TYPE zif_gg_session_types_v1=>ty_name OPTIONAL
        iv_cursor_value        TYPE string OPTIONAL
        iv_pf_key              TYPE i OPTIONAL
        iv_session_id          TYPE string OPTIONAL
        iv_page_id             TYPE string OPTIONAL
        iv_can_back            TYPE abap_bool DEFAULT abap_false
        iv_pause_at_navigation TYPE abap_bool DEFAULT abap_false
        is_resume_navigation   TYPE zif_gg_host_html_v1=>ty_navigation OPTIONAL
        is_resume_submit       TYPE zif_gg_session_types_v1=>ty_submit OPTIONAL
      RETURNING
        VALUE(rs_result)       TYPE ty_result.

  PRIVATE SECTION.
    CLASS-DATA mv_run_id TYPE i.

    TYPES: BEGIN OF ty_flow_result,
             ended            TYPE abap_bool,
             call_selection   TYPE abap_bool,
             call_screen      TYPE abap_bool,
             call_transaction TYPE abap_bool,
             submit_return    TYPE abap_bool,
             unsupported      TYPE string,
             terminal         TYPE string,
           END OF ty_flow_result.

    CLASS-METHODS interpret_flow
      IMPORTING
        ix_flow          TYPE REF TO zcx_gg_control_flow
      RETURNING
        VALUE(rs_result) TYPE ty_flow_result.

    CLASS-METHODS retry_selection
      IMPORTING
        iv_active        TYPE abap_bool
        iv_screen        TYPE zif_gg_selection_screen_types=>ty_screen_number
        io_report        TYPE REF TO zif_gg_report_v1
        io_session       TYPE REF TO zcl_gg_host_session
        it_input         TYPE zif_gg_selection_screen_types=>ty_values
        it_states        TYPE zif_gg_selection_screen_types=>ty_states
      CHANGING
        ct_values        TYPE zif_gg_selection_screen_types=>ty_values
        cv_ended         TYPE abap_bool
      RETURNING
        VALUE(rv_active) TYPE abap_bool.

    CLASS-METHODS resume_selection_call
      IMPORTING
        io_report  TYPE REF TO zif_gg_report_v1
        io_session TYPE REF TO zcl_gg_host_session
        it_input   TYPE zif_gg_selection_screen_types=>ty_values
      CHANGING
        ct_values  TYPE zif_gg_selection_screen_types=>ty_values
        cv_ended   TYPE abap_bool.

    CLASS-METHODS run_value_request
      IMPORTING
        io_report  TYPE REF TO zif_gg_report_v1
        io_session TYPE REF TO zcl_gg_host_session
        iv_name    TYPE zif_gg_selection_screen_types=>ty_name
        iv_screen  TYPE zif_gg_selection_screen_types=>ty_screen_number
      CHANGING
        ct_values  TYPE zif_gg_selection_screen_types=>ty_values.

    CLASS-METHODS run_interactive_events
      IMPORTING
        io_handler      TYPE REF TO zif_gg_list_processing_v1
        io_list         TYPE REF TO zcl_gg_host_list
        io_list_session TYPE REF TO zif_gg_list_session_v1
        io_session      TYPE REF TO zcl_gg_host_session
        iv_line_index   TYPE i
        iv_line_level   TYPE i
        iv_user_command TYPE zif_gg_list_processing_types_v1=>ty_ucomm
        iv_cursor_field TYPE zif_gg_session_types_v1=>ty_name
        iv_cursor_value TYPE string
        iv_pf_key       TYPE i
      CHANGING
        cv_ended        TYPE abap_bool.

    CLASS-METHODS resume_screen_call
      IMPORTING
        io_report       TYPE REF TO zif_gg_report_v1
        io_session      TYPE REF TO zcl_gg_host_session
      RETURNING
        VALUE(rv_ended) TYPE abap_bool.

    CLASS-METHODS resume_submit_return
      IMPORTING
        io_report        TYPE REF TO zif_gg_report_v1
        io_submit_report TYPE REF TO zif_gg_report_v1
        io_session       TYPE REF TO zcl_gg_host_session
      RETURNING
        VALUE(rv_ended)  TYPE abap_bool.

    CLASS-METHODS resume_navigation
      IMPORTING
        io_report        TYPE REF TO zif_gg_report_v1
        io_submit_report TYPE REF TO zif_gg_report_v1 OPTIONAL
        io_session       TYPE REF TO zcl_gg_host_session
        is_navigation    TYPE zif_gg_host_html_v1=>ty_navigation
        is_submit        TYPE zif_gg_session_types_v1=>ty_submit OPTIONAL
        it_input         TYPE zif_gg_selection_screen_types=>ty_values
      CHANGING
        ct_values        TYPE zif_gg_selection_screen_types=>ty_values
        ct_states        TYPE zif_gg_selection_screen_types=>ty_states
        cv_ended         TYPE abap_bool.

    CLASS-METHODS start_or_resume
      IMPORTING
        io_report            TYPE REF TO zif_gg_report_v1
        io_submit_report     TYPE REF TO zif_gg_report_v1 OPTIONAL
        io_session           TYPE REF TO zcl_gg_host_session
        is_resume_navigation TYPE zif_gg_host_html_v1=>ty_navigation
        is_resume_submit     TYPE zif_gg_session_types_v1=>ty_submit OPTIONAL
        it_input             TYPE zif_gg_selection_screen_types=>ty_values
      CHANGING
        ct_values            TYPE zif_gg_selection_screen_types=>ty_values
        ct_states            TYPE zif_gg_selection_screen_types=>ty_states
        cv_ended             TYPE abap_bool.

    CLASS-METHODS validate_required
      IMPORTING
        it_states  TYPE zif_gg_selection_screen_types=>ty_states
        it_values  TYPE zif_gg_selection_screen_types=>ty_values
        io_session TYPE REF TO zcl_gg_host_session.

    CLASS-METHODS next_run_id
      RETURNING
        VALUE(rv_id) TYPE string.

    CLASS-METHODS navigation_for
      IMPORTING
        ix_flow              TYPE REF TO zcx_gg_control_flow
        io_session           TYPE REF TO zcl_gg_host_session
      RETURNING
        VALUE(rs_navigation) TYPE zif_gg_host_html_v1=>ty_navigation.

    CLASS-METHODS render_result
      IMPORTING
        iv_session_id          TYPE string
        iv_page_id             TYPE string
        iv_program             TYPE zif_gg_session_types_v1=>ty_program
        iv_selection_screen    TYPE zif_gg_selection_screen_types=>ty_screen_number
        iv_selection_active    TYPE abap_bool
        iv_can_back            TYPE abap_bool
        iv_pause_at_navigation TYPE abap_bool
        iv_navigation          TYPE zif_gg_host_html_v1=>ty_navigation
        io_list                TYPE REF TO zcl_gg_host_list
      CHANGING
        cs_result              TYPE ty_result.

ENDCLASS.

CLASS zcl_gg_host IMPLEMENTATION.

  METHOD run.
    DATA lt_values  TYPE zif_gg_selection_screen_types=>ty_values.
    DATA lt_states  TYPE zif_gg_selection_screen_types=>ty_states.
    DATA lt_radio_groups TYPE STANDARD TABLE OF zif_gg_selection_screen_types=>ty_group
      WITH DEFAULT KEY.
    DATA lv_ended   TYPE abap_bool.
    DATA lo_handler TYPE REF TO zif_gg_list_processing_v1.
    DATA lo_list    TYPE REF TO zcl_gg_host_list.
    DATA lo_list_session TYPE REF TO zif_gg_list_session_v1.
    DATA lo_screen  TYPE REF TO zcl_gg_host_screen.
    DATA lo_session TYPE REF TO zcl_gg_host_session.
    DATA lx_flow    TYPE REF TO zcx_gg_control_flow.
    DATA lv_call_selection TYPE abap_bool.
    DATA lv_call_screen TYPE abap_bool.
    DATA lv_call_transaction TYPE abap_bool.
    DATA lv_submit_return TYPE abap_bool.
    DATA lv_selection_screen_active TYPE abap_bool.
    DATA lv_session_id TYPE string.
    DATA lv_page_id TYPE string.
    DATA lv_display_screen TYPE zif_gg_selection_screen_types=>ty_screen_number.

    lv_session_id = COND #( WHEN iv_session_id IS INITIAL
      THEN next_run_id( ) ELSE iv_session_id ).
    lv_page_id = COND #( WHEN iv_page_id IS INITIAL
      THEN |{ lv_session_id }-1| ELSE iv_page_id ).
    lv_display_screen = iv_selection_screen.
    cl_gui_control=>clear( ).

    lo_list   = NEW zcl_gg_host_list( ).
    lo_screen = NEW zcl_gg_host_screen( ).
    lo_session = NEW zcl_gg_host_session(
      io_list    = lo_list
      iv_program = iv_program
      iv_batch   = iv_batch ).
    lo_list_session = lo_session->zif_gg_session_v1~get_list( ).

    TRY.
        lo_session->set_event( 'LOAD-OF-PROGRAM' ).
        io_report->load_of_program( lo_session ).

        io_report->build_screen( lo_screen ).
        lt_values = lo_screen->get_values( ).
        lt_states = lo_screen->get_states( ).

        lo_handler = io_report->get_list_processing( lo_session ).
        lo_list->set_handler(
          io_session = lo_session
          io_handler = lo_handler ).
        IF lo_handler IS BOUND.
          lo_list->apply_settings( lo_handler->get_settings( lo_session ) ).
        ENDIF.

        lo_session->set_event( 'INITIALIZATION' ).
        io_report->initialization(
          EXPORTING
            io_session = lo_session
          CHANGING
            ct_values  = lt_values ).

        IF iv_help_name IS NOT INITIAL.
          lo_session->set_event( 'AT SELECTION-SCREEN ON HELP-REQUEST' ).
          rs_result-help_text = io_report->at_selection_screen_help_req(
             iv_screen  = iv_selection_screen
            iv_name    = iv_help_name
            it_values  = lt_values
            io_session = lo_session ).
        ENDIF.

        IF iv_exit_ucomm IS NOT INITIAL.
          lo_session->set_event( 'AT SELECTION-SCREEN ON EXIT-COMMAND' ).
          io_report->at_selection_screen_on_exit(
             iv_screen  = iv_selection_screen
            iv_ucomm   = iv_exit_ucomm
            it_values  = lt_values
            io_session = lo_session ).
        ENDIF.

        lo_session->set_processor(
          iv_processor = zif_gg_session_types_v1=>processor_selection
          iv_screen    = iv_selection_screen ).
        lo_session->set_event( 'AT SELECTION-SCREEN OUTPUT' ).
        io_report->at_selection_screen_output(
          EXPORTING
             iv_screen  = iv_selection_screen
            io_session = lo_session
          CHANGING
            ct_values  = lt_values
            ct_states  = lt_states ).

        LOOP AT it_input INTO DATA(ls_input).
          IF line_exists( lt_values[ name = ls_input-name ] ).
            lt_values[ name = ls_input-name ] = ls_input.
          ENDIF.
        ENDLOOP.

        IF iv_value_request IS NOT INITIAL.
          run_value_request(
            EXPORTING
            io_report  = io_report
            io_session = lo_session
            iv_name    = iv_value_request
            iv_screen  = iv_selection_screen
            CHANGING
              ct_values = lt_values ).
        ENDIF.

        LOOP AT lt_values INTO DATA(ls_value).
          lo_session->set_event( 'AT SELECTION-SCREEN ON FIELD' ).
          io_report->at_selection_screen_on_field(
            EXPORTING
              iv_screen  = iv_selection_screen
              iv_name    = ls_value-name
              io_session = lo_session
            CHANGING
              ct_values  = lt_values ).
        ENDLOOP.

        LOOP AT lt_values INTO ls_value.
          IF lines( ls_value-ranges ) > 0.
            lo_session->set_event( 'AT SELECTION-SCREEN ON END OF' ).
            io_report->at_selection_screen_on_end_of(
              EXPORTING
                iv_screen  = iv_selection_screen
                iv_name    = ls_value-name
                io_session = lo_session
              CHANGING
                ct_values  = lt_values ).
          ENDIF.
        ENDLOOP.

        LOOP AT lo_screen->get_blocks( ) INTO DATA(ls_block).
          lo_session->set_event( 'AT SELECTION-SCREEN ON BLOCK' ).
          io_report->at_selection_screen_on_block(
            EXPORTING
              iv_screen  = iv_selection_screen
              iv_block   = ls_block-block-name
              io_session = lo_session
            CHANGING
              ct_values  = lt_values ).
        ENDLOOP.

        LOOP AT lt_states INTO DATA(ls_state).
          IF ls_state-group1 IS NOT INITIAL
              AND NOT line_exists( lt_radio_groups[ table_line = ls_state-group1 ] ).
            APPEND ls_state-group1 TO lt_radio_groups.
            lo_session->set_event( 'AT SELECTION-SCREEN ON RADIOBUTTON GROUP' ).
            io_report->at_selection_screen_on_radio(
              EXPORTING
                iv_screen  = iv_selection_screen
                iv_group   = ls_state-group1
                io_session = lo_session
              CHANGING
                ct_values  = lt_values ).
          ENDIF.
        ENDLOOP.

        lo_session->set_event( 'AT SELECTION-SCREEN' ).
        io_report->at_selection_screen(
          EXPORTING
            iv_screen  = iv_selection_screen
            iv_ucomm   = iv_ucomm
            io_session = lo_session
          CHANGING
            ct_values  = lt_values ).

        validate_required(
          it_states  = lt_states
          it_values  = lt_values
          io_session = lo_session ).

        start_or_resume(
          EXPORTING
            io_report            = io_report
            io_submit_report     = io_submit_report
            io_session           = lo_session
            is_resume_navigation = is_resume_navigation
            is_resume_submit     = is_resume_submit
            it_input             = it_input
          CHANGING
            ct_values            = lt_values
            ct_states            = lt_states
            cv_ended             = lv_ended ).
      CATCH zcx_gg_control_flow INTO lx_flow.
        DATA(ls_flow_result) = interpret_flow( lx_flow ).
        lv_ended = ls_flow_result-ended.
        lv_call_selection = ls_flow_result-call_selection.
        lv_call_screen = ls_flow_result-call_screen.
        lv_call_transaction = ls_flow_result-call_transaction.
        lv_submit_return = ls_flow_result-submit_return.
        rs_result-unsupported = ls_flow_result-unsupported.
        rs_result-terminal = ls_flow_result-terminal.
        rs_result-transaction_call = lo_session->get_transaction_call( ).
        rs_result-navigation = navigation_for(
          ix_flow = lx_flow
          io_session = lo_session ).
        lv_selection_screen_active = xsdbool(
          lx_flow->mv_kind = zcx_gg_control_flow=>kind_message ).
    ENDTRY.

    DATA(lv_paused) = xsdbool(
      iv_pause_at_navigation = abap_true
      AND rs_result-navigation-kind IS NOT INITIAL ).
    lv_ended = xsdbool(
      lv_ended = abap_true OR lv_paused = abap_true ).
    lv_selection_screen_active = xsdbool(
      lv_selection_screen_active = abap_true
      OR ( lv_paused = abap_true
        AND rs_result-navigation-kind = zcx_gg_control_flow=>kind_call_selection_screen ) ).
    lv_display_screen = COND #(
      WHEN lv_paused = abap_true
        AND rs_result-navigation-kind = zcx_gg_control_flow=>kind_call_selection_screen
      THEN CONV #( rs_result-navigation-target )
      ELSE lv_display_screen ).
    IF lv_paused = abap_false.
      lv_selection_screen_active = retry_selection(
        EXPORTING
          iv_active  = lv_selection_screen_active
          iv_screen  = iv_selection_screen
          io_report  = io_report
          io_session = lo_session
          it_input   = it_retry_input
          it_states  = lt_states
        CHANGING
          ct_values = lt_values
          cv_ended  = lv_ended ).

      IF lv_call_selection = abap_true.
        resume_selection_call(
          EXPORTING
          io_report  = io_report
          io_session = lo_session
          it_input   = it_input
          CHANGING
            ct_values = lt_values
            cv_ended  = lv_ended ).
      ENDIF.

      IF lv_call_screen = abap_true OR lv_call_transaction = abap_true.
        lv_ended = resume_screen_call(
          io_report  = io_report
          io_session = lo_session ).
      ENDIF.

      IF lv_submit_return = abap_true AND io_submit_report IS BOUND.
        lv_ended = resume_submit_return(
          io_report         = io_report
          io_submit_report  = io_submit_report
          io_session        = lo_session ).
      ENDIF.
    ENDIF.

    IF lv_ended = abap_false.
      TRY.
          lo_session->set_event( 'END-OF-SELECTION' ).
          io_report->end_of_selection(
            it_values  = lt_values
            io_session = lo_session ).
        CATCH zcx_gg_control_flow INTO lx_flow.
          IF lx_flow->mv_kind = zcx_gg_control_flow=>kind_unsupported.
            rs_result-unsupported = lx_flow->mv_operation.
          ENDIF.
      ENDTRY.
    ENDIF.

    run_interactive_events(
      EXPORTING
      io_handler      = lo_handler
      io_list         = lo_list
      io_list_session = lo_list_session
      io_session      = lo_session
      iv_line_index   = iv_line_index
      iv_line_level   = iv_line_level
      iv_user_command = iv_user_command
      iv_cursor_field = iv_cursor_field
      iv_cursor_value = iv_cursor_value
      iv_pf_key       = iv_pf_key
      CHANGING
        cv_ended       = lv_ended ).

    rs_result-lines    = lo_list->finish_output( ).
    rs_result-render_lines = lo_list->get_render_lines( ).
    rs_result-model_events = lo_list->get_model_events( ).
    rs_result-line_formats = lo_list->get_line_formats( ).
    rs_result-messages = lo_session->get_messages( ).
    rs_result-values   = lt_values.
    rs_result-states   = lt_states.
    rs_result-blocks   = lo_screen->get_blocks( ).
    rs_result-elements = lo_screen->get_elements( ).
    rs_result-screen_snapshot = lo_screen->get_snapshot(
      iv_screen = lv_display_screen
      it_values = lt_values
      it_states = lt_states ).
    rs_result-memory_render_lines = lo_session->get_list_render_from_memory( ).
    rs_result-dialog_suppressed = lo_session->is_dialog_suppressed( ).
    rs_result-settings = lo_list->get_settings( ).
    rs_result-status   = lo_list->get_status( ).
    rs_result-title    = lo_list->get_title( ).
    rs_result-submit   = lo_session->get_submit_call( ).
    rs_result-selection_active = lv_selection_screen_active.
    rs_result-session_id = lv_session_id.
    rs_result-page_id = lv_page_id.
    render_result(
      EXPORTING
        iv_session_id       = lv_session_id
        iv_page_id          = lv_page_id
        iv_program          = iv_program
        iv_selection_screen = lv_display_screen
        iv_selection_active = lv_selection_screen_active
        iv_can_back         = iv_can_back
        iv_pause_at_navigation = iv_pause_at_navigation
        iv_navigation       = rs_result-navigation
        io_list             = lo_list
      CHANGING
        cs_result           = rs_result ).
  ENDMETHOD.

  METHOD next_run_id.
    mv_run_id = mv_run_id + 1.
    rv_id = |RUN-{ mv_run_id }|.
  ENDMETHOD.

  METHOD navigation_for.
    DATA ls_continuation TYPE zif_gg_session_types_v1=>ty_continuation.

    ls_continuation = io_session->get_continuation( ).
    rs_navigation-kind = ix_flow->mv_kind.
    rs_navigation-continuation = ls_continuation-id.
    CASE ix_flow->mv_kind.
      WHEN zcx_gg_control_flow=>kind_call_selection_screen.
        DATA(ls_selection_call) = io_session->get_selection_call( ).
        rs_navigation-target = ls_selection_call-screen.
        rs_navigation-modal = abap_true.
      WHEN zcx_gg_control_flow=>kind_call_screen.
        DATA(ls_screen_call) = io_session->get_screen_call( ).
        rs_navigation-target = ls_screen_call-screen.
        rs_navigation-modal = abap_true.
      WHEN zcx_gg_control_flow=>kind_submit_return.
        DATA(ls_submit_call) = io_session->get_submit_call( ).
        rs_navigation-target = ls_submit_call-program.
      WHEN zcx_gg_control_flow=>kind_call_transaction.
        DATA(ls_transaction_call) = io_session->get_transaction_call( ).
        rs_navigation-target = ls_transaction_call-tcode.
    ENDCASE.
  ENDMETHOD.

  METHOD render_result.
    DATA lv_page_kind TYPE string.
    DATA lv_title TYPE string.
    DATA ls_page TYPE zif_gg_host_html_v1=>ty_page.
    DATA ls_context TYPE zif_gg_host_html_v1=>ty_renderer_context.
    DATA lt_actions TYPE zif_gg_host_html_v1=>ty_actions.
    DATA lv_controls_html TYPE string.

    ls_context-program = iv_program.
    ls_context-locale = 'en'.
    ls_context-date_format = 'ISO'.
    ls_context-decimal_separator = '.'.
    ls_context-thousands_separator = ','.

    IF cs_result-terminal IS NOT INITIAL.
      lv_page_kind = zif_gg_host_html_v1=>page_terminal.
      ls_context-processor = zif_gg_session_types_v1=>processor_report.
      lv_title = 'Terminal'.
      cs_result-html = zcl_gg_host_renderer=>render_terminal(
        iv_session_id = iv_session_id
        iv_page_id    = iv_page_id
        iv_title      = lv_title
        iv_text       = cs_result-terminal
        is_context   = ls_context
        it_messages   = cs_result-messages ).
    ELSEIF iv_selection_active = abap_true.
      lv_page_kind = zif_gg_host_html_v1=>page_selection.
      ls_context-processor = zif_gg_session_types_v1=>processor_selection.
      ls_context-screen = iv_selection_screen.
      lv_title = 'Selection'.
      cs_result-html = zcl_gg_host_renderer=>render_selection(
        iv_session_id = iv_session_id
        iv_page_id    = iv_page_id
        iv_title      = lv_title
        it_values     = cs_result-values
        it_states     = cs_result-states
        it_blocks     = cs_result-blocks
        it_elements   = cs_result-elements
        it_tabs       = cs_result-screen_snapshot-tabs
        is_context    = ls_context
        it_messages   = cs_result-messages
        iv_help_text  = cs_result-help_text ).
    ELSEIF iv_pause_at_navigation = abap_true AND iv_navigation-kind IS NOT INITIAL.
      lv_page_kind = zif_gg_host_html_v1=>page_navigation.
      ls_context-processor = zif_gg_session_types_v1=>processor_report.
      lv_title = 'Navigation'.
      cs_result-html = zcl_gg_host_renderer=>render_navigation(
        iv_session_id = iv_session_id
        iv_page_id    = iv_page_id
        iv_title      = lv_title
        is_navigation = iv_navigation
        is_context    = ls_context ).
    ELSEIF cs_result-messages IS NOT INITIAL AND cs_result-lines IS INITIAL.
      lv_page_kind = zif_gg_host_html_v1=>page_message.
      ls_context-processor = zif_gg_session_types_v1=>processor_report.
      lv_title = 'Message'.
      cs_result-html = zcl_gg_host_renderer=>render_message(
        iv_session_id = iv_session_id
        iv_page_id    = iv_page_id
        iv_title      = lv_title
        iv_text       = cs_result-messages[ 1 ]-text
        is_context   = ls_context
        it_messages   = cs_result-messages ).
    ELSE.
      lv_page_kind = zif_gg_host_html_v1=>page_list.
      ls_context-processor = zif_gg_session_types_v1=>processor_list.
      lv_title = cs_result-title.
      IF lv_title IS INITIAL.
        lv_title = 'ABAP list'.
      ENDIF.
      IF iv_can_back = abap_true.
        APPEND VALUE #( kind = zif_gg_host_html_v1=>action_back ) TO lt_actions.
      ENDIF.
      IF cl_gui_control=>has_content( ) = abap_true.
        lv_controls_html = cl_gui_control=>render_html( iv_document = abap_false ).
      ENDIF.
      cs_result-html = zcl_gg_host_renderer=>render_list(
        iv_session_id = iv_session_id
        iv_page_id    = iv_page_id
        iv_title      = lv_title
        it_lines      = io_list->get_render_lines( )
        is_status     = cs_result-status
        it_actions    = lt_actions
        is_context    = ls_context
        it_messages   = cs_result-messages
        iv_controls_html = lv_controls_html ).
    ENDIF.
    IF lv_page_kind <> zif_gg_host_html_v1=>page_navigation.
      cs_result-html = zcl_gg_host_renderer=>with_navigation(
        iv_html = cs_result-html
        is_navigation = cs_result-navigation ).
    ENDIF.
    cs_result-page_kind = lv_page_kind.
    ls_page = VALUE #(
      session_id = iv_session_id
      page_id    = iv_page_id
      kind       = lv_page_kind
      processor  = ls_context-processor
      status     = cs_result-status
      terminal   = xsdbool( cs_result-terminal IS NOT INITIAL )
      navigation = cs_result-navigation
      messages   = cs_result-messages
      title      = lv_title
      html       = cs_result-html ).
    CASE lv_page_kind.
      WHEN zif_gg_host_html_v1=>page_selection.
        APPEND VALUE #( kind = zif_gg_host_html_v1=>action_submit
                        ucomm = 'ONLI' ) TO ls_page-actions.
        APPEND VALUE #( kind = zif_gg_host_html_v1=>action_exit
                        ucomm = 'CANC' ) TO ls_page-actions.
      WHEN zif_gg_host_html_v1=>page_list.
        APPEND VALUE #( kind = zif_gg_host_html_v1=>action_line ) TO ls_page-actions.
        IF iv_can_back = abap_true.
          APPEND VALUE #( kind = zif_gg_host_html_v1=>action_back ) TO ls_page-actions.
        ENDIF.
      WHEN zif_gg_host_html_v1=>page_dynpro.
        APPEND VALUE #( kind = zif_gg_host_html_v1=>action_back
                        ucomm = 'BACK' ) TO ls_page-actions.
      WHEN zif_gg_host_html_v1=>page_navigation.
        APPEND VALUE #( kind = zif_gg_host_html_v1=>action_submit
                        ucomm = 'CONTINUE' ) TO ls_page-actions.
      WHEN OTHERS.
        CLEAR ls_page-actions.
    ENDCASE.
    cs_result-page = ls_page.
    APPEND ls_page TO cs_result-pages.
  ENDMETHOD.

  METHOD retry_selection.
    rv_active = iv_active.
    IF iv_active = abap_false OR it_input IS INITIAL.
      RETURN.
    ENDIF.

    cv_ended = abap_true.
    TRY.
        LOOP AT it_input INTO DATA(ls_input).
          IF line_exists( ct_values[ name = ls_input-name ] ).
            ct_values[ name = ls_input-name ] = ls_input.
          ENDIF.
        ENDLOOP.

        io_session->set_event( 'AT SELECTION-SCREEN' ).
        io_report->at_selection_screen(
          EXPORTING
            iv_screen  = iv_screen
            iv_ucomm   = 'ONLI'
            io_session = io_session
          CHANGING
            ct_values  = ct_values ).
        validate_required(
          it_states  = it_states
          it_values  = ct_values
          io_session = io_session ).
        io_session->set_event( 'START-OF-SELECTION' ).
        io_report->start_of_selection(
          it_values  = ct_values
          io_session = io_session ).
        cv_ended = abap_false.
        rv_active = abap_false.
      CATCH zcx_gg_control_flow.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD resume_selection_call.
    DATA lo_resumable TYPE REF TO zif_gg_resumable_v1.
    DATA ls_call TYPE zif_gg_session_types_v1=>ty_selection_screen_call.
    DATA ls_continuation TYPE zif_gg_session_types_v1=>ty_continuation.

    cv_ended = abap_false.
    ls_call = io_session->get_selection_call( ).
    ls_continuation = io_session->get_continuation( ).

    TRY.
        LOOP AT it_input INTO DATA(ls_input).
          IF line_exists( ct_values[ name = ls_input-name ] ).
            ct_values[ name = ls_input-name ] = ls_input.
          ENDIF.
        ENDLOOP.

        io_session->set_event( 'AT SELECTION-SCREEN' ).
        io_report->at_selection_screen(
          EXPORTING
            iv_screen  = ls_call-screen
            iv_ucomm   = 'ONLI'
            io_session = io_session
          CHANGING
            ct_values  = ct_values ).

        lo_resumable ?= io_report.
        IF lo_resumable IS BOUND.
          lo_resumable->resume(
            is_resume = VALUE #( continuation = ls_continuation subrc = 0 )
            io_session = io_session ).
        ENDIF.
      CATCH zcx_gg_control_flow.
        cv_ended = abap_true.
    ENDTRY.
  ENDMETHOD.

  METHOD run_value_request.
    DATA lt_requested_ranges TYPE zif_gg_selection_screen_types=>ty_ranges.

    io_session->set_event( 'AT SELECTION-SCREEN ON VALUE-REQUEST' ).
    lt_requested_ranges = io_report->at_selection_screen_value_req(
      iv_screen  = iv_screen
      iv_name    = iv_name
      it_values  = ct_values
      io_session = io_session ).
    IF line_exists( ct_values[ name = iv_name ] ) AND lt_requested_ranges IS NOT INITIAL.
      ct_values[ name = iv_name ]-ranges = lt_requested_ranges.
    ENDIF.
  ENDMETHOD.

  METHOD interpret_flow.
    rs_result-ended = xsdbool( ix_flow->mv_kind <> zcx_gg_control_flow=>kind_stop ).
    IF ix_flow->mv_kind = zcx_gg_control_flow=>kind_call_selection_screen.
      rs_result-call_selection = abap_true.
      rs_result-ended = abap_false.
    ENDIF.
    IF ix_flow->mv_kind = zcx_gg_control_flow=>kind_call_screen.
      rs_result-call_screen = abap_true.
      rs_result-ended = abap_false.
    ENDIF.
    IF ix_flow->mv_kind = zcx_gg_control_flow=>kind_call_transaction.
      rs_result-call_transaction = abap_true.
      rs_result-ended = abap_false.
    ENDIF.
    IF ix_flow->mv_kind = zcx_gg_control_flow=>kind_unsupported.
      rs_result-unsupported = ix_flow->mv_operation.
    ENDIF.
    IF ix_flow->mv_kind = zcx_gg_control_flow=>kind_leave_program.
      rs_result-terminal = 'LEAVE PROGRAM'.
    ENDIF.
    IF ix_flow->mv_kind = zcx_gg_control_flow=>kind_leave_to_transaction.
      rs_result-terminal = ix_flow->mv_operation.
    ENDIF.
    IF ix_flow->mv_kind = zcx_gg_control_flow=>kind_submit.
      rs_result-terminal = ix_flow->mv_operation.
    ENDIF.
    IF ix_flow->mv_kind = zcx_gg_control_flow=>kind_submit_return.
      rs_result-submit_return = abap_true.
      rs_result-ended = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD run_interactive_events.
    io_session->set_processor( zif_gg_session_types_v1=>processor_list ).
    IF cv_ended = abap_false AND iv_line_index > 0 AND io_handler IS BOUND.
      io_list->finish_output( ).
      io_list->begin_line_selection( iv_level = iv_line_level ).
      io_list->select_line(
        iv_index = iv_line_index
        iv_field = iv_cursor_field
        iv_value = iv_cursor_value ).
      io_session->set_event( 'AT LINE-SELECTION' ).
      io_handler->at_line_selection(
        is_line    = io_list_session->read_line( iv_index = iv_line_index )
        io_session = io_session ).
    ENDIF.

    IF cv_ended = abap_false AND iv_user_command IS NOT INITIAL AND io_handler IS BOUND.
      io_list->finish_output( ).
      io_session->set_event( 'AT USER-COMMAND' ).
      io_handler->at_user_command(
        iv_ucomm   = iv_user_command
        is_line    = io_list_session->read_line( iv_index = iv_line_index )
        io_session = io_session ).
    ENDIF.

    IF cv_ended = abap_false AND iv_pf_key > 0 AND io_handler IS BOUND.
      io_list->finish_output( ).
      io_session->set_event( 'AT PF' ).
      io_handler->at_pf(
        iv_key     = iv_pf_key
        is_line    = io_list_session->read_line( iv_index = iv_line_index )
        io_session = io_session ).
    ENDIF.
  ENDMETHOD.

  METHOD resume_screen_call.
    DATA lo_resumable TYPE REF TO zif_gg_resumable_v1.
    DATA ls_continuation TYPE zif_gg_session_types_v1=>ty_continuation.

    rv_ended = abap_false.
    ls_continuation = io_session->get_continuation( ).
    TRY.
        lo_resumable ?= io_report.
        IF lo_resumable IS BOUND.
          lo_resumable->resume(
            is_resume = VALUE #( continuation = ls_continuation subrc = 0 )
            io_session = io_session ).
        ENDIF.
      CATCH zcx_gg_control_flow.
        rv_ended = abap_true.
    ENDTRY.
  ENDMETHOD.

  METHOD resume_submit_return.
    DATA ls_sub_result TYPE ty_result.
    DATA ls_submit TYPE zif_gg_session_types_v1=>ty_submit.

    rv_ended = abap_false.
    ls_submit = io_session->get_submit_call( ).
    ls_sub_result = run(
      io_report = io_submit_report
      it_input  = ls_submit-values ).
    io_session->set_list_from_memory(
      it_lines        = ls_sub_result-lines
      it_render_lines = ls_sub_result-render_lines ).
    rv_ended = resume_screen_call(
      io_report  = io_report
      io_session = io_session ).
  ENDMETHOD.

  METHOD resume_navigation.
    DATA lo_resumable TYPE REF TO zif_gg_resumable_v1.
    DATA ls_submit_result TYPE ty_result.

    cv_ended = abap_false.
    IF is_navigation-kind = zcx_gg_control_flow=>kind_call_selection_screen.
      io_session->set_processor(
        iv_processor = zif_gg_session_types_v1=>processor_selection
        iv_screen    = CONV #( is_navigation-target ) ).
      io_session->set_event( 'AT SELECTION-SCREEN OUTPUT' ).
      io_report->at_selection_screen_output(
        EXPORTING
          iv_screen  = CONV #( is_navigation-target )
          io_session = io_session
        CHANGING
          ct_values  = ct_values
          ct_states  = ct_states ).
      LOOP AT it_input INTO DATA(ls_input).
        IF line_exists( ct_values[ name = ls_input-name ] ).
          ct_values[ name = ls_input-name ] = ls_input.
        ENDIF.
      ENDLOOP.
      io_session->set_event( 'AT SELECTION-SCREEN' ).
      io_report->at_selection_screen(
        EXPORTING
          iv_screen  = CONV #( is_navigation-target )
          iv_ucomm   = 'ONLI'
          io_session = io_session
        CHANGING
          ct_values  = ct_values ).
      validate_required(
        it_states  = ct_states
        it_values  = ct_values
        io_session = io_session ).
    ENDIF.

    IF is_navigation-kind = zcx_gg_control_flow=>kind_submit_return
        AND io_submit_report IS BOUND.
      ls_submit_result = run(
        io_report = io_submit_report
          it_input  = is_submit-values ).
      io_session->set_list_from_memory(
        it_lines        = ls_submit_result-lines
        it_render_lines = ls_submit_result-render_lines ).
    ENDIF.

    io_session->set_processor( zif_gg_session_types_v1=>processor_list ).
    lo_resumable ?= io_report.
    IF lo_resumable IS BOUND.
      lo_resumable->resume(
        is_resume = VALUE #(
          continuation = VALUE #( id = is_navigation-continuation )
          subrc        = 0 )
        io_session = io_session ).
    ENDIF.
  ENDMETHOD.

  METHOD start_or_resume.
    IF is_resume_navigation-kind IS INITIAL.
      io_session->set_processor( zif_gg_session_types_v1=>processor_list ).
      io_session->set_event( 'START-OF-SELECTION' ).
      io_report->start_of_selection(
        it_values  = ct_values
        io_session = io_session ).
    ELSE.
      resume_navigation(
        EXPORTING
          io_report            = io_report
          io_submit_report     = io_submit_report
          io_session           = io_session
          is_navigation        = is_resume_navigation
          is_submit            = is_resume_submit
          it_input             = it_input
        CHANGING
          ct_values            = ct_values
          ct_states            = ct_states
          cv_ended             = cv_ended ).
    ENDIF.
  ENDMETHOD.

  METHOD validate_required.
    LOOP AT it_states INTO DATA(ls_required_state)
        WHERE obligatory = abap_true.
      READ TABLE it_values INTO DATA(ls_required_value)
        WITH TABLE KEY name = ls_required_state-name.
      IF sy-subrc <> 0.
        io_session->zif_gg_session_v1~message( VALUE #(
          type  = zif_gg_session_types_v1=>message_type_error
          text  = |Field { ls_required_state-name } is required|
          field = ls_required_state-name ) ).
      ENDIF.
      IF ls_required_value-value IS INITIAL
          AND ls_required_value-ranges IS INITIAL.
        io_session->zif_gg_session_v1~message( VALUE #(
          type  = zif_gg_session_types_v1=>message_type_error
          text  = |Field { ls_required_state-name } is required|
          field = ls_required_state-name ) ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
