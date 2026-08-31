CLASS zcl_gg_host_dynpro DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_result,
             screen         TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
             terminal       TYPE string,
             terminal_state TYPE abap_bool,
             messages       TYPE zcl_gg_host_session=>ty_messages,
             help_text      TYPE string,
             help_values    TYPE zif_gg_dynpro_types_v1=>ty_values,
             status         TYPE zif_gg_session_types_v1=>ty_gui_status,
             title          TYPE string,
             cursor         TYPE zif_gg_session_types_v1=>ty_dialog_cursor,
             values         TYPE zif_gg_dynpro_types_v1=>ty_values,
             lines          TYPE zcl_gg_host_list=>ty_text_lines,
             states         TYPE zif_gg_dynpro_types_v1=>ty_states,
             screens        TYPE zcl_gg_host_dynpro_builder=>ty_screens,
             controls       TYPE zcl_gg_host_dynpro_builder=>ty_controls,
             flow           TYPE zcl_gg_host_dynpro_flow=>ty_steps,
             navigation     TYPE zif_gg_host_html_v1=>ty_navigation,
             submit         TYPE zif_gg_session_types_v1=>ty_submit,
             session_id     TYPE string,
             page_id        TYPE string,
             page_kind      TYPE string,
             html           TYPE string,
             page           TYPE zif_gg_host_html_v1=>ty_page,
           END OF ty_result.

    CLASS-METHODS run
      IMPORTING
        io_program       TYPE REF TO zif_gg_dynpro_v1
        iv_ucomm         TYPE zif_gg_dynpro_types_v1=>ty_ucomm DEFAULT 'BACK'
        iv_submitted     TYPE abap_bool DEFAULT abap_true
        it_values        TYPE zif_gg_dynpro_types_v1=>ty_values OPTIONAL
        iv_field         TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL
        iv_row           TYPE i OPTIONAL
        iv_cursor_field  TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL
        iv_cursor_row    TYPE i OPTIONAL
        iv_value_request TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL
        iv_help_request  TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL
        iv_screen        TYPE zif_gg_dynpro_types_v1=>ty_screen_number OPTIONAL
        iv_session_id    TYPE string OPTIONAL
        iv_page_id       TYPE string OPTIONAL
      RETURNING
        VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.
    CLASS-DATA mv_run_id TYPE i.

    CLASS-METHODS next_run_id
      RETURNING
        VALUE(rv_id) TYPE string.

    CLASS-METHODS validate_submission
      IMPORTING
        io_session        TYPE REF TO zcl_gg_host_session
        it_controls       TYPE zcl_gg_host_dynpro_builder=>ty_controls
        iv_screen         TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        iv_ucomm          TYPE zif_gg_dynpro_types_v1=>ty_ucomm
        iv_submitted      TYPE abap_bool
      RETURNING
        VALUE(rv_allowed) TYPE abap_bool.

    CLASS-METHODS add_page_actions
      IMPORTING
        iv_terminal TYPE abap_bool
      CHANGING
        ct_actions  TYPE zif_gg_host_html_v1=>ty_actions.

    CLASS-METHODS render_terminal_page
      IMPORTING
        iv_session_id TYPE string
        iv_page_id    TYPE string
      CHANGING
        cs_result     TYPE ty_result.

    CLASS-METHODS capture_navigation
      IMPORTING
        io_session TYPE REF TO zcl_gg_host_session
        ix_flow    TYPE REF TO zcx_gg_control_flow
      CHANGING
        cs_result  TYPE ty_result.

    CLASS-METHODS process_modules IMPORTING io_program TYPE REF TO zif_gg_dynpro_v1 io_flow TYPE REF TO zcl_gg_host_dynpro_flow io_session TYPE REF TO zcl_gg_host_session iv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number iv_submitted TYPE abap_bool iv_ucomm TYPE zif_gg_dynpro_types_v1=>ty_ucomm iv_value_request TYPE zif_gg_dynpro_types_v1=>ty_name iv_help_request TYPE zif_gg_dynpro_types_v1=>ty_name it_controls TYPE zcl_gg_host_dynpro_builder=>ty_controls CHANGING cs_context TYPE zif_gg_dynpro_types_v1=>ty_module_context ct_values TYPE zif_gg_dynpro_types_v1=>ty_values ct_states TYPE zif_gg_dynpro_types_v1=>ty_states cv_help_text TYPE string ct_help_values TYPE zif_gg_dynpro_types_v1=>ty_values.

    CLASS-METHODS destination_pbo IMPORTING io_program TYPE REF TO zif_gg_dynpro_v1 io_flow TYPE REF TO zcl_gg_host_dynpro_flow io_session TYPE REF TO zcl_gg_host_session iv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number CHANGING cs_context TYPE zif_gg_dynpro_types_v1=>ty_module_context ct_values TYPE zif_gg_dynpro_types_v1=>ty_values ct_states TYPE zif_gg_dynpro_types_v1=>ty_states.

ENDCLASS.

CLASS zcl_gg_host_dynpro IMPLEMENTATION.

  METHOD run.
    DATA lo_builder TYPE REF TO zcl_gg_host_dynpro_builder.
    DATA lo_flow TYPE REF TO zcl_gg_host_dynpro_flow.
    DATA lo_list TYPE REF TO zcl_gg_host_list.
    DATA lo_session TYPE REF TO zcl_gg_host_session.
    DATA lt_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    DATA lt_states TYPE zif_gg_dynpro_types_v1=>ty_states.
    DATA lt_screens TYPE zcl_gg_host_dynpro_builder=>ty_screens.
    DATA lt_controls TYPE zcl_gg_host_dynpro_builder=>ty_controls.
    DATA lt_steps TYPE zcl_gg_host_dynpro_flow=>ty_steps.
    DATA lv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    DATA lx_flow TYPE REF TO zcx_gg_control_flow.
    DATA ls_screen TYPE zif_gg_dynpro_types_v1=>ty_screen.
    DATA lv_session_id TYPE string.
    DATA lv_page_id TYPE string.
    DATA ls_context TYPE zif_gg_dynpro_types_v1=>ty_module_context.
    DATA ls_input_value TYPE zif_gg_dynpro_types_v1=>ty_value.
    FIELD-SYMBOLS <ls_value> TYPE zif_gg_dynpro_types_v1=>ty_value.
    DATA lv_loop_lines TYPE i.

    lo_builder = NEW zcl_gg_host_dynpro_builder( ).
    lo_flow = NEW zcl_gg_host_dynpro_flow( ).
    lo_list = NEW zcl_gg_host_list( ).
    lo_session = NEW zcl_gg_host_session(
      io_list      = lo_list
      iv_processor = zif_gg_session_types_v1=>processor_dynpro ).

    io_program->build_screens( lo_builder ).
    io_program->build_flow_logic( lo_flow ).
    lt_screens = lo_builder->get_screens( ).
    lt_controls = lo_builder->get_controls( ).
    lt_steps = lo_flow->get_steps( ).
    LOOP AT lt_controls INTO DATA(ls_control).
      INSERT VALUE #(
        container = COND #( WHEN ls_control-kind = 'TABLE_COLUMN'
                            THEN ls_control-parent ELSE `` )
        name      = ls_control-name
        row       = 0
        text      = ls_control-text
        fixed_values = ls_control-fixed_values
        visible   = ls_control-visible
        enabled   = ls_control-enabled
        required  = ls_control-required
        password  = ls_control-password
        value_help = ls_control-value_help ) INTO TABLE lt_states.
    ENDLOOP.
    io_program->initialization(
      EXPORTING
        io_session = lo_session
      CHANGING
        ct_values  = lt_values ).

    LOOP AT it_values INTO ls_input_value.
      READ TABLE lt_values ASSIGNING <ls_value>
        WITH KEY container = ls_input_value-container
                 name = ls_input_value-name
                 row = ls_input_value-row.
      IF sy-subrc = 0.
        <ls_value>-value = ls_input_value-value.
      ELSE.
        INSERT ls_input_value INTO TABLE lt_values.
      ENDIF.
    ENDLOOP.

    ls_context-field = iv_field.
    ls_context-row = iv_row.
    ls_context-loop_index = iv_row.
    ls_context-cursor_field = iv_cursor_field.
    ls_context-cursor_row = iv_cursor_row.
    LOOP AT lt_values INTO ls_input_value.
      IF ls_input_value-container IS NOT INITIAL.
        ls_context-table_control = ls_input_value-container.
        IF ls_context-field IS INITIAL.
          ls_context-field = ls_input_value-name.
        ENDIF.
        IF ls_context-row IS INITIAL.
          ls_context-row = ls_input_value-row.
          ls_context-loop_index = ls_input_value-row.
        ENDIF.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF ls_context-table_control IS NOT INITIAL.
      LOOP AT lt_values INTO DATA(ls_loop_value).
        IF ls_loop_value-container = ls_context-table_control.
          lv_loop_lines = lv_loop_lines + 1.
        ENDIF.
      ENDLOOP.
      ls_context-loop_lines = lv_loop_lines.
    ENDIF.

    lv_screen = COND #(
      WHEN iv_screen IS INITIAL THEN io_program->get_initial_screen( )
      ELSE iv_screen ).
    lo_session->set_processor(
      iv_processor = zif_gg_session_types_v1=>processor_dynpro
      iv_screen    = lv_screen ).
    TRY.
        process_modules(
          EXPORTING
            io_program       = io_program
            io_flow          = lo_flow
            io_session       = lo_session
            iv_screen        = lv_screen
            iv_submitted     = iv_submitted
            iv_ucomm         = iv_ucomm
            iv_value_request = iv_value_request
            iv_help_request  = iv_help_request
            it_controls      = lt_controls
          CHANGING
            cs_context       = ls_context
            ct_values        = lt_values
            ct_states        = lt_states
            cv_help_text     = rs_result-help_text
            ct_help_values   = rs_result-help_values ).
      CATCH zcx_gg_control_flow INTO lx_flow.
        rs_result-terminal = lx_flow->mv_operation.
        rs_result-terminal_state = xsdbool(
          lx_flow->mv_kind = zcx_gg_control_flow=>kind_leave_program
          OR lx_flow->mv_kind = zcx_gg_control_flow=>kind_leave_to_transaction
          OR ( lx_flow->mv_kind = zcx_gg_control_flow=>kind_leave_to_screen
            AND lo_session->get_next_screen( ) = '0000' ) ).
        CASE lx_flow->mv_kind.
          WHEN zcx_gg_control_flow=>kind_leave_screen.
            lv_screen = lo_session->get_next_screen( ).
            IF lv_screen IS INITIAL.
              lv_screen = io_program->get_initial_screen( ).
            ENDIF.
          WHEN zcx_gg_control_flow=>kind_leave_to_screen.
            lv_screen = lo_session->get_next_screen( ).
        ENDCASE.
        lo_session->set_processor(
          iv_processor = zif_gg_session_types_v1=>processor_dynpro
          iv_screen    = lv_screen ).
    ENDTRY.

    capture_navigation(
      EXPORTING
        io_session = lo_session
        ix_flow    = lx_flow
      CHANGING
        cs_result  = rs_result ).

    IF lx_flow IS BOUND
        AND ( lx_flow->mv_kind = zcx_gg_control_flow=>kind_leave_screen
        OR lx_flow->mv_kind = zcx_gg_control_flow=>kind_leave_to_screen )
        AND lv_screen IS NOT INITIAL.
      destination_pbo(
        EXPORTING
          io_program = io_program
          io_flow    = lo_flow
          io_session = lo_session
          iv_screen  = lv_screen
        CHANGING
          cs_context = ls_context
          ct_values  = lt_values
          ct_states  = lt_states ).
    ENDIF.

    rs_result-screen = lv_screen.
    rs_result-values = lt_values.
    rs_result-states = lt_states.
    rs_result-screens = lt_screens.
    rs_result-controls = lt_controls.
    rs_result-flow = lt_steps.
    rs_result-messages = lo_session->get_messages( ).
    rs_result-status = lo_session->get_status( ).
    rs_result-title = lo_session->get_title( ).
    rs_result-cursor = lo_session->get_cursor( ).
    rs_result-lines = lo_list->finish_output( ).
    READ TABLE lt_screens INTO ls_screen WITH KEY number = lv_screen.
    lv_session_id = COND #( WHEN iv_session_id IS INITIAL
      THEN next_run_id( ) ELSE iv_session_id ).
    lv_page_id = COND #( WHEN iv_page_id IS INITIAL
      THEN |{ lv_session_id }-1| ELSE iv_page_id ).
    rs_result-session_id = lv_session_id.
    rs_result-page_id = lv_page_id.
    rs_result-page_kind = zif_gg_host_html_v1=>page_dynpro.
    rs_result-html = zcl_gg_host_renderer=>render_dynpro(
      iv_session_id = lv_session_id
      iv_page_id    = lv_page_id
      is_screen     = ls_screen
      iv_title      = rs_result-title
      is_status     = rs_result-status
      is_cursor     = rs_result-cursor
      it_controls   = lt_controls
      it_values     = lt_values
      it_states     = lt_states
      iv_help_text   = rs_result-help_text
      it_help_values = rs_result-help_values
      it_messages   = rs_result-messages ).
    render_terminal_page(
      EXPORTING
        iv_session_id = lv_session_id
        iv_page_id    = lv_page_id
      CHANGING
        cs_result     = rs_result ).
    rs_result-page = VALUE #(
      session_id = lv_session_id
      page_id    = lv_page_id
      kind       = rs_result-page_kind
      processor  = zif_gg_session_types_v1=>processor_dynpro
      screen     = rs_result-screen
      status     = rs_result-status
      terminal   = rs_result-terminal_state
      messages   = rs_result-messages
      title      = COND string( WHEN rs_result-title IS INITIAL THEN ls_screen-title ELSE rs_result-title )
      html       = rs_result-html ).
    add_page_actions(
      EXPORTING
        iv_terminal = rs_result-terminal_state
      CHANGING
        ct_actions = rs_result-page-actions ).
  ENDMETHOD.

  METHOD process_modules.
    DATA lv_submit_allowed TYPE abap_bool.

    LOOP AT io_flow->get_modules( ) INTO DATA(ls_module)
        WHERE screen = iv_screen AND phase = 'PBO'.
      io_session->set_event( 'PROCESS BEFORE OUTPUT' ).
      cs_context-screen = iv_screen.
      cs_context-module = ls_module-module-name.
      CLEAR cs_context-ucomm.
      io_program->process_output_module(
        EXPORTING
          is_context = cs_context
          io_session = io_session
        CHANGING
          ct_values  = ct_values
          ct_states  = ct_states ).
    ENDLOOP.

    lv_submit_allowed = validate_submission(
      io_session   = io_session
      it_controls  = it_controls
      iv_screen    = iv_screen
      iv_ucomm     = iv_ucomm
      iv_submitted = iv_submitted ).

    IF iv_submitted = abap_true AND lv_submit_allowed = abap_true.
      LOOP AT io_flow->get_modules( ) INTO ls_module
          WHERE screen = iv_screen AND phase = 'PAI'.
        io_session->set_event( 'PROCESS AFTER INPUT' ).
        cs_context-screen = iv_screen.
        cs_context-module = ls_module-module-name.
        cs_context-ucomm = iv_ucomm.
        io_program->process_input_module(
          EXPORTING
            is_context = cs_context
            io_session = io_session
          CHANGING
            ct_values = ct_values ).
      ENDLOOP.
    ENDIF.

    IF iv_value_request IS NOT INITIAL.
      cs_context-screen = iv_screen.
      cs_context-field = iv_value_request.
      LOOP AT io_flow->get_modules( ) INTO ls_module
          WHERE screen = iv_screen AND phase = 'POV'.
        io_session->set_event( 'PROCESS ON VALUE-REQUEST' ).
        cs_context-module = ls_module-module-name.
        ct_help_values = io_program->process_on_value_request(
          is_context = cs_context
          it_values  = ct_values
          io_session = io_session ).
      ENDLOOP.
    ENDIF.

    IF iv_help_request IS NOT INITIAL.
      cs_context-screen = iv_screen.
      cs_context-field = iv_help_request.
      LOOP AT io_flow->get_modules( ) INTO ls_module
          WHERE screen = iv_screen AND phase = 'POH'.
        io_session->set_event( 'PROCESS ON HELP-REQUEST' ).
        cs_context-module = ls_module-module-name.
        cv_help_text = io_program->process_on_help_request(
          is_context = cs_context
          it_values  = ct_values
          io_session = io_session ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD destination_pbo.
    LOOP AT io_flow->get_modules( ) INTO DATA(ls_module)
        WHERE screen = iv_screen AND phase = 'PBO'.
      io_session->set_event( 'PROCESS BEFORE OUTPUT' ).
      cs_context-screen = iv_screen.
      cs_context-module = ls_module-module-name.
      CLEAR cs_context-ucomm.
      io_program->process_output_module(
        EXPORTING
          is_context = cs_context
          io_session = io_session
        CHANGING
          ct_values  = ct_values
          ct_states  = ct_states ).
    ENDLOOP.
  ENDMETHOD.

  METHOD validate_submission.
    DATA(ls_status) = io_session->get_status( ).
    rv_allowed = abap_true.
    IF iv_submitted = abap_true
        AND iv_ucomm <> 'BACK'
        AND NOT line_exists( it_controls[ screen = iv_screen ucomm = iv_ucomm ] )
        AND NOT line_exists( ls_status-active_ucomm[ table_line = iv_ucomm ] ).
      rv_allowed = abap_false.
      io_session->zif_gg_session_v1~message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = |Command { iv_ucomm } is not available on dynpro screen { iv_screen }| ) ).
    ENDIF.
  ENDMETHOD.

  METHOD add_page_actions.
    IF iv_terminal = abap_false.
      APPEND VALUE #( kind = zif_gg_host_html_v1=>action_submit ) TO ct_actions.
      APPEND VALUE #( kind = zif_gg_host_html_v1=>action_back
                      ucomm = 'BACK' ) TO ct_actions.
    ENDIF.
  ENDMETHOD.

  METHOD render_terminal_page.
    IF cs_result-terminal_state = abap_true
        AND cs_result-terminal IS INITIAL.
      cs_result-page_kind = zif_gg_host_html_v1=>page_terminal.
      cs_result-html = zcl_gg_host_renderer=>render_terminal(
        iv_session_id = iv_session_id
        iv_page_id    = iv_page_id
        iv_title      = 'Terminal'
        iv_text       = cs_result-terminal
        it_messages    = cs_result-messages ).
    ENDIF.
  ENDMETHOD.

  METHOD next_run_id.
    mv_run_id = mv_run_id + 1.
    rv_id = |DYNPRO-{ mv_run_id }|.
  ENDMETHOD.

  METHOD capture_navigation.
    DATA ls_continuation TYPE zif_gg_session_types_v1=>ty_continuation.
    DATA ls_transaction_call TYPE zif_gg_session_types_v1=>ty_transaction_call.
    DATA ls_submit_call TYPE zif_gg_session_types_v1=>ty_submit.

    IF ix_flow IS NOT BOUND.
      RETURN.
    ENDIF.
    ls_continuation = io_session->get_continuation( ).
    CASE ix_flow->mv_kind.
      WHEN zcx_gg_control_flow=>kind_call_transaction
          OR zcx_gg_control_flow=>kind_leave_to_transaction.
        ls_transaction_call = io_session->get_transaction_call( ).
        cs_result-navigation = VALUE #(
          kind = ix_flow->mv_kind
          target = CONV string( ls_transaction_call-tcode )
          continuation = ls_continuation-id ).
      WHEN zcx_gg_control_flow=>kind_submit_return.
        ls_submit_call = io_session->get_submit_call( ).
        cs_result-navigation = VALUE #(
          kind = ix_flow->mv_kind
          target = CONV string( ls_submit_call-program )
          continuation = ls_continuation-id ).
        cs_result-submit = ls_submit_call.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
