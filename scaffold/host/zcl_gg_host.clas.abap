CLASS zcl_gg_host DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Drives one run of an executable program written against zif_gg_report_v1 and
* returns what came out of it.
*
* Covered so far: LOAD-OF-PROGRAM, the screen definition and its defaults,
* INITIALIZATION, AT SELECTION-SCREEN OUTPUT, START-OF-SELECTION,
* END-OF-SELECTION, STOP, MESSAGE, the classic list and line selection. A
* selection screen is described but never displayed, and the remaining
* interactive, navigating and logical database paths are not driven yet; see
* examples/PLAN.md for which phase brings each of them.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_result,
             lines             TYPE zcl_gg_host_list=>ty_text_lines,
             line_formats      TYPE zcl_gg_host_list=>ty_line_formats,
             messages          TYPE zcl_gg_host_session=>ty_messages,
             values            TYPE zif_gg_selection_screen_types=>ty_values,
             states            TYPE zif_gg_selection_screen_types=>ty_states,
             blocks            TYPE zcl_gg_host_screen=>ty_blocks,
             elements          TYPE zcl_gg_host_screen=>ty_elements,
             help_text         TYPE string,
             terminal          TYPE string,
             dialog_suppressed TYPE abap_bool,
             settings          TYPE zif_gg_list_processing_types_v1=>ty_settings,
             status            TYPE zif_gg_session_types_v1=>ty_gui_status,
             title             TYPE string,
             submit            TYPE zif_gg_session_types_v1=>ty_submit,
             unsupported       TYPE string,
           END OF ty_result.

    CLASS-METHODS run
      IMPORTING
        io_report        TYPE REF TO zif_gg_report_v1
        io_submit_report TYPE REF TO zif_gg_report_v1 OPTIONAL
        iv_program       TYPE zif_gg_session_types_v1=>ty_program OPTIONAL
        iv_batch         TYPE abap_bool DEFAULT abap_false
        it_input         TYPE zif_gg_selection_screen_types=>ty_values OPTIONAL
        iv_ucomm         TYPE zif_gg_selection_screen_types=>ty_ucomm DEFAULT 'ONLI'
        iv_value_request TYPE zif_gg_selection_screen_types=>ty_name OPTIONAL
        iv_help_name     TYPE zif_gg_selection_screen_types=>ty_name OPTIONAL
        iv_exit_ucomm    TYPE zif_gg_selection_screen_types=>ty_ucomm OPTIONAL
        iv_line_index    TYPE i OPTIONAL
        iv_line_level    TYPE i DEFAULT 1
        iv_user_command  TYPE zif_gg_list_processing_types_v1=>ty_ucomm OPTIONAL
        iv_cursor_field  TYPE zif_gg_session_types_v1=>ty_name OPTIONAL
        iv_cursor_value  TYPE string OPTIONAL
        iv_pf_key        TYPE i OPTIONAL
      RETURNING
        VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.
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
            iv_screen  = '1000'
            iv_name    = iv_help_name
            it_values  = lt_values
            io_session = lo_session ).
        ENDIF.

        IF iv_exit_ucomm IS NOT INITIAL.
          lo_session->set_event( 'AT SELECTION-SCREEN ON EXIT-COMMAND' ).
          io_report->at_selection_screen_on_exit(
            iv_screen  = '1000'
            iv_ucomm   = iv_exit_ucomm
            it_values  = lt_values
            io_session = lo_session ).
        ENDIF.

        lo_session->set_event( 'AT SELECTION-SCREEN OUTPUT' ).
        io_report->at_selection_screen_output(
          EXPORTING
            iv_screen  = '1000'
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
            CHANGING
              ct_values = lt_values ).
        ENDIF.

        LOOP AT lt_values INTO DATA(ls_value).
          lo_session->set_event( 'AT SELECTION-SCREEN ON FIELD' ).
          io_report->at_selection_screen_on_field(
            EXPORTING
              iv_screen  = '1000'
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
                iv_screen  = '1000'
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
              iv_screen  = '1000'
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
                iv_screen  = '1000'
                iv_group   = ls_state-group1
                io_session = lo_session
              CHANGING
                ct_values  = lt_values ).
          ENDIF.
        ENDLOOP.

        lo_session->set_event( 'AT SELECTION-SCREEN' ).
        io_report->at_selection_screen(
          EXPORTING
            iv_screen  = '1000'
            iv_ucomm   = iv_ucomm
            io_session = lo_session
          CHANGING
            ct_values  = lt_values ).

        lo_session->set_event( 'START-OF-SELECTION' ).
        io_report->start_of_selection(
          it_values  = lt_values
          io_session = lo_session ).
      CATCH zcx_gg_control_flow INTO lx_flow.
        DATA(ls_flow_result) = interpret_flow( lx_flow ).
        lv_ended = ls_flow_result-ended.
        lv_call_selection = ls_flow_result-call_selection.
        lv_call_screen = ls_flow_result-call_screen.
        lv_call_transaction = ls_flow_result-call_transaction.
        lv_submit_return = ls_flow_result-submit_return.
        rs_result-unsupported = ls_flow_result-unsupported.
        rs_result-terminal = ls_flow_result-terminal.
    ENDTRY.

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

    IF lv_call_screen = abap_true.
      lv_ended = resume_screen_call(
        io_report  = io_report
        io_session = lo_session ).
    ENDIF.

    IF lv_call_transaction = abap_true.
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
    rs_result-line_formats = lo_list->get_line_formats( ).
    rs_result-messages = lo_session->get_messages( ).
    rs_result-values   = lt_values.
    rs_result-states   = lt_states.
    rs_result-blocks   = lo_screen->get_blocks( ).
    rs_result-elements = lo_screen->get_elements( ).
    rs_result-dialog_suppressed = lo_session->is_dialog_suppressed( ).
    rs_result-settings = lo_list->get_settings( ).
    rs_result-status   = lo_list->get_status( ).
    rs_result-title    = lo_list->get_title( ).
    rs_result-submit   = lo_session->get_submit_call( ).
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
      iv_screen  = '1000'
      iv_name    = iv_name
      it_values  = ct_values
      io_session = io_session ).
    IF line_exists( ct_values[ name = iv_name ] ).
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
    io_session->set_list_from_memory( ls_sub_result-lines ).
    rv_ended = resume_screen_call(
      io_report  = io_report
      io_session = io_session ).
  ENDMETHOD.

ENDCLASS.
