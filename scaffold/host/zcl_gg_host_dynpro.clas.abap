CLASS zcl_gg_host_dynpro DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_result,
             screen             TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
             terminal           TYPE string,
             terminal_state     TYPE abap_bool,
             messages           TYPE zcl_gg_host_session=>ty_messages,
             help_text          TYPE string,
             help_name          TYPE zif_gg_dynpro_types_v1=>ty_name,
             help_values        TYPE zif_gg_dynpro_types_v1=>ty_values,
             status             TYPE zif_gg_session_types_v1=>ty_gui_status,
             title              TYPE string,
             cursor             TYPE zif_gg_session_types_v1=>ty_dialog_cursor,
             modal_position     TYPE zif_gg_session_types_v1=>ty_modal_position,
             modal_returned     TYPE abap_bool,
             popup              TYPE zif_gg_compatibility_v1=>ty_popup,
             values             TYPE zif_gg_dynpro_types_v1=>ty_values,
             lines              TYPE zcl_gg_host_list=>ty_text_lines,
             render_lines       TYPE zcl_gg_host_list=>ty_render_lines,
             list_return_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
             states             TYPE zif_gg_dynpro_types_v1=>ty_states,
             screens            TYPE zcl_gg_host_dynpro_builder=>ty_screens,
             controls           TYPE zcl_gg_host_dynpro_builder=>ty_controls,
             context_menu       TYPE REF TO cl_ctmenu,
             context_field      TYPE zif_gg_dynpro_types_v1=>ty_name,
             flow               TYPE zcl_gg_host_dynpro_flow=>ty_steps,
             navigation         TYPE zif_gg_host_html_v1=>ty_navigation,
             submit             TYPE zif_gg_session_types_v1=>ty_submit,
             session_id         TYPE string,
             page_id            TYPE string,
             page_kind          TYPE string,
             html               TYPE string,
             page               TYPE zif_gg_host_html_v1=>ty_page,
           END OF ty_result.

    CLASS-METHODS run
      IMPORTING
        io_program             TYPE REF TO zif_gg_dynpro_v1
        iv_ucomm               TYPE zif_gg_dynpro_types_v1=>ty_ucomm DEFAULT 'BACK'
        iv_submitted           TYPE abap_bool DEFAULT abap_true
        it_values              TYPE zif_gg_dynpro_types_v1=>ty_values OPTIONAL
        iv_field               TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL
        iv_row                 TYPE i OPTIONAL
        iv_cursor_field        TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL
        iv_cursor_row          TYPE i OPTIONAL
        iv_value_request       TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL
        iv_help_request        TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL
        iv_popup_action        TYPE string OPTIONAL
        it_popup_values        TYPE zif_gg_dynpro_types_v1=>ty_values OPTIONAL
        is_modal_position      TYPE zif_gg_session_types_v1=>ty_modal_position OPTIONAL
        io_resumable           TYPE REF TO zif_gg_resumable_v1 OPTIONAL
        iv_resume_continuation TYPE string OPTIONAL
        iv_screen              TYPE zif_gg_dynpro_types_v1=>ty_screen_number OPTIONAL
        iv_session_id          TYPE string OPTIONAL
        iv_page_id             TYPE string OPTIONAL
      RETURNING
        VALUE(rs_result)       TYPE ty_result.

  PRIVATE SECTION.
    CLASS-DATA mv_run_id TYPE i.

    CLASS-METHODS next_run_id
      RETURNING
        VALUE(rv_id) TYPE string.

    CLASS-METHODS validate_submission
      IMPORTING
        io_session        TYPE REF TO zcl_gg_host_session
        it_controls       TYPE zcl_gg_host_dynpro_builder=>ty_controls
        it_active_screens TYPE zcl_gg_host_dynpro_builder=>ty_screens OPTIONAL
        iv_screen         TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        iv_ucomm          TYPE zif_gg_dynpro_types_v1=>ty_ucomm
        iv_submitted      TYPE abap_bool
        io_menu           TYPE REF TO cl_ctmenu OPTIONAL
      RETURNING
        VALUE(rv_allowed) TYPE abap_bool.

    CLASS-METHODS context_command_present
      IMPORTING
        io_menu           TYPE REF TO cl_ctmenu
        iv_ucomm          TYPE zif_gg_dynpro_types_v1=>ty_ucomm
      RETURNING
        VALUE(rv_present) TYPE abap_bool.

    CLASS-METHODS context_command_enabled
      IMPORTING
        io_menu           TYPE REF TO cl_ctmenu
        iv_ucomm          TYPE zif_gg_dynpro_types_v1=>ty_ucomm
      RETURNING
        VALUE(rv_enabled) TYPE abap_bool.

    CLASS-METHODS prepare_context_menu
      IMPORTING
        io_program    TYPE REF TO zif_gg_dynpro_v1
        io_session    TYPE REF TO zcl_gg_host_session
        iv_screen     TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        it_controls   TYPE zcl_gg_host_dynpro_builder=>ty_controls
      CHANGING
        co_menu       TYPE REF TO cl_ctmenu
        cv_menu_field TYPE zif_gg_dynpro_types_v1=>ty_name.

    CLASS-METHODS restore_cursor
      IMPORTING
        io_session      TYPE REF TO zcl_gg_host_session
        iv_cursor_field TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_cursor_row   TYPE i.

    CLASS-METHODS refresh_after_input
      IMPORTING
        io_program    TYPE REF TO zif_gg_dynpro_v1
        io_flow       TYPE REF TO zcl_gg_host_dynpro_flow
        io_session    TYPE REF TO zcl_gg_host_session
        iv_screen     TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        iv_submitted  TYPE abap_bool
        iv_allowed    TYPE abap_bool
        it_controls   TYPE zcl_gg_host_dynpro_builder=>ty_controls
      CHANGING
        cs_context    TYPE zif_gg_dynpro_types_v1=>ty_module_context
        ct_values     TYPE zif_gg_dynpro_types_v1=>ty_values
        ct_states     TYPE zif_gg_dynpro_types_v1=>ty_states
        co_menu       TYPE REF TO cl_ctmenu
        cv_menu_field TYPE zif_gg_dynpro_types_v1=>ty_name.

    CLASS-METHODS add_page_actions
      IMPORTING
        iv_terminal TYPE abap_bool
      CHANGING
        ct_actions  TYPE zif_gg_host_html_v1=>ty_actions.

    "! A radio group holds one selection. A submitted radio therefore clears
    "! the other members of its group, including a default set in
    "! INITIALIZATION, so the program never sees two selected buttons.
    CLASS-METHODS clear_radio_siblings
      IMPORTING
        it_input    TYPE zif_gg_dynpro_types_v1=>ty_values
        it_controls TYPE zcl_gg_host_dynpro_builder=>ty_controls
      CHANGING
        ct_values   TYPE zif_gg_dynpro_types_v1=>ty_values.

    CLASS-METHODS command_on_active_subscreen
      IMPORTING
        it_controls       TYPE zcl_gg_host_dynpro_builder=>ty_controls
        it_active_screens TYPE zcl_gg_host_dynpro_builder=>ty_screens
        iv_ucomm          TYPE zif_gg_dynpro_types_v1=>ty_ucomm
      RETURNING
        VALUE(rv_allowed) TYPE abap_bool.

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

    CLASS-METHODS process_modules
      IMPORTING
        io_program       TYPE REF TO zif_gg_dynpro_v1
        io_flow          TYPE REF TO zcl_gg_host_dynpro_flow
        io_session       TYPE REF TO zcl_gg_host_session
        iv_screen        TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        iv_submitted     TYPE abap_bool
        iv_ucomm         TYPE zif_gg_dynpro_types_v1=>ty_ucomm
        iv_value_request TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_help_request  TYPE zif_gg_dynpro_types_v1=>ty_name
        it_controls      TYPE zcl_gg_host_dynpro_builder=>ty_controls
      CHANGING
        cs_context       TYPE zif_gg_dynpro_types_v1=>ty_module_context
        ct_values        TYPE zif_gg_dynpro_types_v1=>ty_values
        ct_states        TYPE zif_gg_dynpro_types_v1=>ty_states
        cv_help_text     TYPE string
        ct_help_values   TYPE zif_gg_dynpro_types_v1=>ty_values
        co_menu          TYPE REF TO cl_ctmenu
        cv_menu_field    TYPE zif_gg_dynpro_types_v1=>ty_name.

    CLASS-METHODS seed_table_states
      IMPORTING
        it_controls TYPE zcl_gg_host_dynpro_builder=>ty_controls
        it_values   TYPE zif_gg_dynpro_types_v1=>ty_values
      CHANGING
        ct_states   TYPE zif_gg_dynpro_types_v1=>ty_states.

    CLASS-METHODS table_line_count
      IMPORTING
        it_values       TYPE zif_gg_dynpro_types_v1=>ty_values
        iv_container    TYPE zif_gg_dynpro_types_v1=>ty_name
      RETURNING
        VALUE(rv_lines) TYPE i.

    CLASS-METHODS table_value_count
      IMPORTING
        it_values       TYPE zif_gg_dynpro_types_v1=>ty_values
        iv_container    TYPE zif_gg_dynpro_types_v1=>ty_name
      RETURNING
        VALUE(rv_lines) TYPE i.

    CLASS-METHODS table_loop_bounds
      IMPORTING
        iv_screen        TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        iv_table_control TYPE zif_gg_dynpro_types_v1=>ty_name
        it_controls      TYPE zcl_gg_host_dynpro_builder=>ty_controls
        it_values        TYPE zif_gg_dynpro_types_v1=>ty_values
      EXPORTING
        ev_lines         TYPE i
        ev_start         TYPE i
        ev_end           TYPE i.

    CLASS-METHODS execute_output_step
      IMPORTING
        io_program       TYPE REF TO zif_gg_dynpro_v1
        io_session       TYPE REF TO zcl_gg_host_session
        iv_screen        TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        is_step          TYPE zcl_gg_host_dynpro_flow=>ty_step
        iv_table_control TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_table_start   TYPE i
        iv_table_end     TYPE i
        iv_table_lines   TYPE i
      CHANGING
        cs_context       TYPE zif_gg_dynpro_types_v1=>ty_module_context
        ct_values        TYPE zif_gg_dynpro_types_v1=>ty_values
        ct_states        TYPE zif_gg_dynpro_types_v1=>ty_states.

    CLASS-METHODS execute_input_step
      IMPORTING
        io_program       TYPE REF TO zif_gg_dynpro_v1
        io_session       TYPE REF TO zcl_gg_host_session
        iv_screen        TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        is_step          TYPE zcl_gg_host_dynpro_flow=>ty_step
        iv_ucomm         TYPE zif_gg_dynpro_types_v1=>ty_ucomm
        iv_table_control TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_table_start   TYPE i
        iv_table_end     TYPE i
        iv_table_lines   TYPE i
      CHANGING
        cs_context       TYPE zif_gg_dynpro_types_v1=>ty_module_context
        ct_values        TYPE zif_gg_dynpro_types_v1=>ty_values.

    CLASS-METHODS execute_subscreen_output
      IMPORTING
        io_program TYPE REF TO zif_gg_dynpro_v1
        io_flow    TYPE REF TO zcl_gg_host_dynpro_flow
        io_session TYPE REF TO zcl_gg_host_session
        iv_screen  TYPE zif_gg_dynpro_types_v1=>ty_screen_number
      CHANGING
        cs_context TYPE zif_gg_dynpro_types_v1=>ty_module_context
        ct_values  TYPE zif_gg_dynpro_types_v1=>ty_values
        ct_states  TYPE zif_gg_dynpro_types_v1=>ty_states.

    CLASS-METHODS execute_subscreen_input
      IMPORTING
        io_program TYPE REF TO zif_gg_dynpro_v1
        io_flow    TYPE REF TO zcl_gg_host_dynpro_flow
        io_session TYPE REF TO zcl_gg_host_session
        iv_screen  TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        iv_ucomm   TYPE zif_gg_dynpro_types_v1=>ty_ucomm
      CHANGING
        cs_context TYPE zif_gg_dynpro_types_v1=>ty_module_context
        ct_values  TYPE zif_gg_dynpro_types_v1=>ty_values.

    CLASS-METHODS resolve_subscreen
      IMPORTING
        is_call          TYPE zif_gg_dynpro_types_v1=>ty_subscreen_call
        it_values        TYPE zif_gg_dynpro_types_v1=>ty_values
      RETURNING
        VALUE(rv_screen) TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

    CLASS-METHODS modal_return_screen
      IMPORTING
        iv_screen        TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        it_screens       TYPE zcl_gg_host_dynpro_builder=>ty_screens
      RETURNING
        VALUE(rv_screen) TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

    CLASS-METHODS destination_pbo
      IMPORTING
        io_program        TYPE REF TO zif_gg_dynpro_v1
        io_flow           TYPE REF TO zcl_gg_host_dynpro_flow
        io_session        TYPE REF TO zcl_gg_host_session
        io_resumable      TYPE REF TO zif_gg_resumable_v1 OPTIONAL
        iv_screen         TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        iv_resume_enabled TYPE abap_bool
        iv_continuation   TYPE string
        iv_execute_pbo    TYPE abap_bool
      CHANGING
        cs_context        TYPE zif_gg_dynpro_types_v1=>ty_module_context
        ct_values         TYPE zif_gg_dynpro_types_v1=>ty_values
        ct_states         TYPE zif_gg_dynpro_types_v1=>ty_states.

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
    DATA ls_screen_call TYPE zif_gg_session_types_v1=>ty_screen_call.
    DATA lv_returned_from_modal TYPE abap_bool.
    DATA ls_input_value TYPE zif_gg_dynpro_types_v1=>ty_value.
    DATA lt_dynamic_lists TYPE zcl_gg_host_compatibility=>ty_selection_lists.
    FIELD-SYMBOLS <ls_value> TYPE zif_gg_dynpro_types_v1=>ty_value.
    FIELD-SYMBOLS <ls_control> TYPE zcl_gg_host_dynpro_builder=>ty_control_record.
    DATA ls_state TYPE zif_gg_dynpro_types_v1=>ty_state.
    DATA lo_context_menu_provider TYPE REF TO zif_gg_context_menu_v1.
    DATA lo_context_menu TYPE REF TO cl_ctmenu.
    DATA lv_context_menu_field TYPE zif_gg_dynpro_types_v1=>ty_name.
    DATA lv_list_page TYPE abap_bool.

    lo_builder = NEW zcl_gg_host_dynpro_builder( ).
    lo_flow = NEW zcl_gg_host_dynpro_flow( ).
    lo_list = NEW zcl_gg_host_list( ).
    lo_session = NEW zcl_gg_host_session(
      io_list      = lo_list
      iv_processor = zif_gg_session_types_v1=>processor_dynpro ).
    lo_session->zif_gg_session_v1~get_compatibility( )->set_popup_request(
      iv_action = iv_popup_action
      it_values = it_popup_values ).

    zcl_gg_host_compatibility=>clear_selection_list_values( ).
    io_program->build_screens( lo_builder ).
    io_program->build_flow_logic( lo_flow ).
    lt_screens = lo_builder->get_screens( ).
    lt_controls = lo_builder->get_controls( ).
    lt_steps = lo_flow->get_steps( ).
    LOOP AT lt_controls INTO DATA(ls_control).
      INSERT VALUE #(
        container    = COND #( WHEN ls_control-kind = 'TABLE_COLUMN'
                            THEN ls_control-parent ELSE `` )
        name         = COND #( WHEN ls_control-state_name IS INITIAL
                               THEN ls_control-name ELSE ls_control-state_name )
        row          = 0
        text         = ls_control-text
        fixed_values = ls_control-fixed_values
        modif_id     = ls_control-modif_id
        group1       = ls_control-group
        visible      = ls_control-visible
        enabled      = ls_control-enabled
        input        = ls_control-input
        output       = xsdbool( ls_control-kind = 'OUTPUT'
                             OR ls_control-kind = 'INPUT' )
        required     = ls_control-required
        intensified  = abap_false
        no_display   = abap_false
        password     = ls_control-password
        value_help   = ls_control-value_help ) INTO TABLE lt_states.
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
    IF iv_submitted = abap_true AND iv_ucomm IS NOT INITIAL.
      READ TABLE lt_values ASSIGNING <ls_value>
        WITH KEY container = `` name = 'GV_OK_CODE' row = 0.
      IF sy-subrc = 0.
        <ls_value>-value = iv_ucomm.
      ELSE.
        INSERT VALUE #( name = 'GV_OK_CODE' value = iv_ucomm ) INTO TABLE lt_values.
      ENDIF.
    ENDIF.

    seed_table_states(
      EXPORTING
        it_controls = lt_controls
        it_values   = lt_values
      CHANGING
        ct_states   = lt_states ).

    clear_radio_siblings(
      EXPORTING
        it_input    = it_values
        it_controls = lt_controls
      CHANGING
        ct_values   = lt_values ).

    restore_cursor(
      io_session      = lo_session
      iv_cursor_field = iv_cursor_field
      iv_cursor_row   = iv_cursor_row ).

    ls_context-field = iv_field.
    ls_context-row = iv_row.
    ls_context-loop_index = COND #( WHEN iv_row IS INITIAL THEN 0 ELSE 1 ).
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
          ls_context-loop_index = 1.
        ENDIF.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF ls_context-table_control IS NOT INITIAL.
      ls_context-loop_lines = table_value_count(
        it_values    = lt_values
        iv_container = ls_context-table_control ).
    ENDIF.

    lv_screen = COND #(
      WHEN iv_screen IS INITIAL THEN io_program->get_initial_screen( )
      ELSE iv_screen ).
    rs_result-modal_position = is_modal_position.
    rs_result-help_name = COND #( WHEN iv_value_request IS INITIAL
                                  THEN iv_help_request
                                  ELSE CONV zif_gg_dynpro_types_v1=>ty_name( iv_value_request ) ).
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
            ct_help_values   = rs_result-help_values
            co_menu          = lo_context_menu
            cv_menu_field    = lv_context_menu_field ).
      CATCH zcx_gg_control_flow INTO lx_flow.
        rs_result-terminal = lx_flow->mv_operation.
        rs_result-terminal_state = xsdbool(
          lx_flow->mv_kind = zcx_gg_control_flow=>kind_leave_program
          OR lx_flow->mv_kind = zcx_gg_control_flow=>kind_leave_to_transaction ).
        CASE lx_flow->mv_kind.
          WHEN zcx_gg_control_flow=>kind_call_screen.
            ls_screen_call = lo_session->get_screen_call( ).
            lv_screen = ls_screen_call-screen.
            rs_result-modal_position = ls_screen_call-modal.
          WHEN zcx_gg_control_flow=>kind_leave_screen.
            lv_screen = lo_session->get_next_screen( ).
            IF lv_screen IS INITIAL.
              lv_screen = io_program->get_initial_screen( ).
            ENDIF.
          WHEN zcx_gg_control_flow=>kind_leave_to_screen.
            lv_screen = lo_session->get_next_screen( ).
            IF lv_screen = '0000'.
              DATA(lv_modal_parent) = modal_return_screen(
                iv_screen  = COND #( WHEN iv_screen IS INITIAL
                                     THEN io_program->get_initial_screen( )
                                     ELSE iv_screen )
                it_screens = lt_screens ).
              IF lv_modal_parent IS NOT INITIAL.
                lv_screen = lv_modal_parent.
                lv_returned_from_modal = abap_true.
              ENDIF.
            ENDIF.
        ENDCASE.
        IF lv_returned_from_modal = abap_true.
          rs_result-terminal_state = abap_false.
          CLEAR rs_result-terminal.
          CLEAR rs_result-modal_position.
        ENDIF.
        lo_session->set_processor(
          iv_processor = zif_gg_session_types_v1=>processor_dynpro
          iv_screen    = lv_screen ).
    ENDTRY.

    lt_dynamic_lists = zcl_gg_host_compatibility=>get_selection_list_values( ).
    LOOP AT lt_dynamic_lists INTO DATA(ls_dynamic_list).
      READ TABLE lt_controls ASSIGNING <ls_control>
        WITH KEY name = CONV zif_gg_dynpro_types_v1=>ty_name( ls_dynamic_list-id ).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      CLEAR <ls_control>-fixed_values.
      LOOP AT ls_dynamic_list-values INTO DATA(ls_dynamic_value).
        APPEND VALUE #(
          key  = CONV string( ls_dynamic_value-key )
          text = CONV string( ls_dynamic_value-text ) )
          TO <ls_control>-fixed_values.
      ENDLOOP.
    ENDLOOP.

    capture_navigation(
      EXPORTING
        io_session = lo_session
        ix_flow    = lx_flow
      CHANGING
        cs_result  = rs_result ).

    destination_pbo(
      EXPORTING
        io_program        = io_program
        io_flow           = lo_flow
        io_session        = lo_session
        io_resumable      = io_resumable
        iv_screen         = lv_screen
        iv_resume_enabled = xsdbool( iv_submitted = abap_false )
        iv_continuation   = iv_resume_continuation
        iv_execute_pbo    = abap_false
      CHANGING
        cs_context        = ls_context
        ct_values         = lt_values
        ct_states         = lt_states ).

    rs_result-modal_returned = lv_returned_from_modal.

    IF lx_flow IS BOUND
        AND ( lx_flow->mv_kind = zcx_gg_control_flow=>kind_call_screen
        OR lx_flow->mv_kind = zcx_gg_control_flow=>kind_leave_screen
        OR lx_flow->mv_kind = zcx_gg_control_flow=>kind_leave_to_screen )
        AND lv_screen IS NOT INITIAL.
      destination_pbo(
        EXPORTING
          io_program        = io_program
          io_flow           = lo_flow
          io_session        = lo_session
          io_resumable      = io_resumable
          iv_screen         = lv_screen
          iv_resume_enabled = lv_returned_from_modal
          iv_continuation   = iv_resume_continuation
          iv_execute_pbo    = abap_true
        CHANGING
          cs_context        = ls_context
          ct_values         = lt_values
          ct_states         = lt_states ).
    ENDIF.

    rs_result-screen = lv_screen.
    rs_result-values = lt_values.
    rs_result-states = lt_states.
    rs_result-screens = lt_screens.
    rs_result-controls = lt_controls.
    rs_result-context_menu = lo_context_menu.
    rs_result-context_field = lv_context_menu_field.
    rs_result-flow = lt_steps.
    rs_result-messages = lo_session->get_messages( ).
    rs_result-popup = lo_session->zif_gg_session_v1~get_compatibility( )->get_popup( ).
    rs_result-status = lo_session->get_status( ).
    rs_result-title = lo_session->get_title( ).
    rs_result-cursor = lo_session->get_cursor( ).
    rs_result-lines = lo_list->finish_output( ).
    rs_result-render_lines = lo_list->get_render_lines( ).
    READ TABLE lt_screens INTO ls_screen WITH KEY number = lv_screen.
    lv_session_id = COND #( WHEN iv_session_id IS INITIAL
      THEN next_run_id( ) ELSE iv_session_id ).
    lv_page_id = COND #( WHEN iv_page_id IS INITIAL
      THEN |{ lv_session_id }-1| ELSE iv_page_id ).
    rs_result-session_id = lv_session_id.
    rs_result-page_id = lv_page_id.
    lv_list_page = xsdbool(
      lo_session->is_dialog_suppressed( ) = abap_true
      OR lo_list->get_context( )-level > 0 ).
    rs_result-page_kind = COND #( WHEN lv_list_page = abap_true
                                  THEN zif_gg_host_html_v1=>page_list
                                  ELSE zif_gg_host_html_v1=>page_dynpro ).
    rs_result-list_return_screen = COND #(
      WHEN lv_list_page = abap_true
      THEN COND #( WHEN lo_session->get_next_screen( ) IS INITIAL
                         OR lo_session->get_next_screen( ) = '0000'
                   THEN iv_screen
                   ELSE lo_session->get_next_screen( ) ) ).
    rs_result-title = COND string(
      WHEN lv_list_page = abap_true AND lo_list->get_title( ) IS NOT INITIAL
      THEN lo_list->get_title( )
      ELSE rs_result-title ).
    rs_result-html = COND string(
      WHEN lv_list_page = abap_true
      THEN zcl_gg_host_renderer=>render_list(
        iv_session_id = lv_session_id
        iv_page_id    = lv_page_id
        iv_title      = COND string( WHEN rs_result-title IS INITIAL THEN 'ABAP list' ELSE rs_result-title )
        it_lines      = rs_result-render_lines
        is_context    = VALUE #( processor = zif_gg_session_types_v1=>processor_list )
        is_status     = rs_result-status
        it_actions    = VALUE #( ( kind = zif_gg_host_html_v1=>action_back ) )
        it_messages   = rs_result-messages )
      ELSE zcl_gg_host_renderer=>render_dynpro(
        iv_session_id     = lv_session_id
        iv_page_id        = lv_page_id
        is_screen         = ls_screen
        iv_title          = rs_result-title
        is_modal_position = rs_result-modal_position
        is_status         = rs_result-status
        is_cursor         = rs_result-cursor
        it_controls       = lt_controls
        it_values         = lt_values
        it_states         = lt_states
        iv_help_text      = rs_result-help_text
        iv_help_name      = CONV string( rs_result-help_name )
        it_help_values    = rs_result-help_values
        is_popup          = rs_result-popup
        it_messages       = rs_result-messages
        io_menu           = lo_context_menu
        iv_menu_field     = CONV string( lv_context_menu_field ) ) ).
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
      processor  = COND #( WHEN rs_result-page_kind = zif_gg_host_html_v1=>page_list
                           THEN zif_gg_session_types_v1=>processor_list
                           ELSE zif_gg_session_types_v1=>processor_dynpro )
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
        ct_actions  = rs_result-page-actions ).
  ENDMETHOD.

  METHOD process_modules.
    TYPES: BEGIN OF ty_active_subscreen,
             area   TYPE zif_gg_dynpro_types_v1=>ty_name,
             screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
           END OF ty_active_subscreen.
    TYPES ty_active_subscreens TYPE STANDARD TABLE OF ty_active_subscreen
      WITH DEFAULT KEY.
    DATA lv_submit_allowed TYPE abap_bool.
    DATA lt_steps TYPE zcl_gg_host_dynpro_flow=>ty_steps.
    DATA ls_step TYPE zcl_gg_host_dynpro_flow=>ty_step.
    DATA ls_module TYPE zcl_gg_host_dynpro_flow=>ty_module.
    DATA lv_table_control TYPE zif_gg_dynpro_types_v1=>ty_name.
    DATA lv_table_lines TYPE i.
    DATA lv_table_start TYPE i.
    DATA lv_table_end TYPE i.
    DATA lv_has_steps TYPE abap_bool.
    DATA lv_subscreen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    DATA lt_active_screens TYPE zcl_gg_host_dynpro_builder=>ty_screens.
    DATA lt_active_subscreens TYPE ty_active_subscreens.

    lt_steps = io_flow->get_steps( ).
    lv_has_steps = xsdbool(
      line_exists( lt_steps[ screen = iv_screen phase = 'PBO' ] )
      OR line_exists( lt_steps[ screen = iv_screen phase = 'PAI' ] ) ).

    IF lv_has_steps = abap_true.
      LOOP AT lt_steps INTO ls_step
          WHERE screen = iv_screen AND phase = 'PBO'.
        CASE ls_step-kind.
          WHEN 'BEGIN_TABLE_LOOP'.
            lv_table_control = ls_step-table_loop-table_control.
            table_loop_bounds(
              EXPORTING
                iv_screen        = iv_screen
                iv_table_control = lv_table_control
                it_controls      = it_controls
                it_values        = ct_values
              IMPORTING
                ev_lines         = lv_table_lines
                ev_start         = lv_table_start
                ev_end           = lv_table_end ).
          WHEN 'END_TABLE_LOOP'.
            CLEAR: lv_table_control, lv_table_lines, lv_table_start, lv_table_end.
          WHEN 'SUBSCREEN'.
            lv_subscreen = resolve_subscreen(
              is_call   = ls_step-subscreen
              it_values = ct_values ).
            IF lv_subscreen IS NOT INITIAL AND lv_subscreen <> '0000'.
              DELETE lt_active_subscreens
                WHERE area = ls_step-subscreen-area.
              APPEND VALUE #( area   = ls_step-subscreen-area
                              screen = lv_subscreen ) TO lt_active_subscreens.
              IF NOT line_exists( lt_active_screens[ number = lv_subscreen ] ).
                APPEND VALUE #( number = lv_subscreen ) TO lt_active_screens.
              ENDIF.
              execute_subscreen_output(
                EXPORTING
                  io_program = io_program
                  io_flow    = io_flow
                  io_session = io_session
                  iv_screen  = lv_subscreen
                CHANGING
                  cs_context = cs_context
                  ct_values  = ct_values
                  ct_states  = ct_states ).
            ENDIF.
          WHEN 'MODULE'.
            execute_output_step(
              EXPORTING
                io_program       = io_program
                io_session       = io_session
                iv_screen        = iv_screen
                is_step          = ls_step
                iv_table_control = lv_table_control
                iv_table_start   = lv_table_start
                iv_table_end     = lv_table_end
                iv_table_lines   = lv_table_lines
              CHANGING
                cs_context       = cs_context
                ct_values        = ct_values
                ct_states        = ct_states ).
        ENDCASE.
      ENDLOOP.
    ELSE.
      LOOP AT io_flow->get_modules( ) INTO ls_module
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
    ENDIF.

    prepare_context_menu(
      EXPORTING
        io_program    = io_program
        io_session    = io_session
        iv_screen     = iv_screen
        it_controls   = it_controls
      CHANGING
        co_menu       = co_menu
        cv_menu_field = cv_menu_field ).

    lv_submit_allowed = validate_submission(
      io_session        = io_session
      it_controls       = it_controls
      it_active_screens = lt_active_screens
      iv_screen         = iv_screen
      iv_ucomm          = iv_ucomm
      iv_submitted      = iv_submitted
      io_menu           = co_menu ).

    IF iv_submitted = abap_true AND lv_submit_allowed = abap_true.
      IF lv_has_steps = abap_true.
        CLEAR lv_table_control.
        LOOP AT lt_steps INTO ls_step
            WHERE screen = iv_screen AND phase = 'PAI'.
          CASE ls_step-kind.
            WHEN 'BEGIN_TABLE_LOOP'.
              lv_table_control = ls_step-table_loop-table_control.
              table_loop_bounds(
                EXPORTING
                  iv_screen        = iv_screen
                  iv_table_control = lv_table_control
                  it_controls      = it_controls
                  it_values        = ct_values
                IMPORTING
                  ev_lines         = lv_table_lines
                  ev_start         = lv_table_start
                  ev_end           = lv_table_end ).
            WHEN 'END_TABLE_LOOP'.
              CLEAR: lv_table_control, lv_table_lines, lv_table_start, lv_table_end.
            WHEN 'SUBSCREEN'.
              lv_subscreen = resolve_subscreen(
                is_call   = ls_step-subscreen
                it_values = ct_values ).
              IF lv_subscreen IS INITIAL OR lv_subscreen = '0000'.
                READ TABLE lt_active_subscreens INTO DATA(ls_active_subscreen)
                  WITH KEY area = ls_step-subscreen-area.
                lv_subscreen = COND #( WHEN sy-subrc = 0
                                       THEN ls_active_subscreen-screen
                                       ELSE lv_subscreen ).
              ENDIF.
              IF lv_subscreen IS NOT INITIAL AND lv_subscreen <> '0000'.
                execute_subscreen_input(
                  EXPORTING
                    io_program = io_program
                    io_flow    = io_flow
                    io_session = io_session
                    iv_screen  = lv_subscreen
                    iv_ucomm   = iv_ucomm
                  CHANGING
                    cs_context = cs_context
                    ct_values  = ct_values ).
              ENDIF.
            WHEN 'MODULE'.
              IF ls_step-module-at_exit_command = abap_true
                  AND iv_ucomm <> 'BACK'
                  AND iv_ucomm <> 'ECAN'
                  AND NOT line_exists( it_controls[ screen = iv_screen
                                                    ucomm = iv_ucomm
                                                    exit_command = abap_true ] ).
                CONTINUE.
              ENDIF.
              execute_input_step(
                EXPORTING
                  io_program       = io_program
                  io_session       = io_session
                  iv_screen        = iv_screen
                  is_step          = ls_step
                  iv_ucomm         = iv_ucomm
                  iv_table_control = lv_table_control
                  iv_table_start   = lv_table_start
                  iv_table_end     = lv_table_end
                  iv_table_lines   = lv_table_lines
                CHANGING
                  cs_context       = cs_context
                  ct_values        = ct_values ).
          ENDCASE.
        ENDLOOP.
      ELSE.
        LOOP AT io_flow->get_modules( ) INTO ls_module
            WHERE screen = iv_screen AND phase = 'PAI'.
          IF ls_module-module-at_exit_command = abap_true
              AND iv_ucomm <> 'BACK'
              AND iv_ucomm <> 'ECAN'
              AND NOT line_exists( it_controls[ screen = iv_screen
                                                ucomm = iv_ucomm
                                                exit_command = abap_true ] ).
            CONTINUE.
          ENDIF.
          io_session->set_event( 'PROCESS AFTER INPUT' ).
          cs_context-screen = iv_screen.
          cs_context-module = ls_module-module-name.
          cs_context-ucomm = iv_ucomm.
          io_program->process_input_module(
            EXPORTING
              is_context = cs_context
              io_session = io_session
            CHANGING
              ct_values  = ct_values ).
        ENDLOOP.
      ENDIF.
    ENDIF.

    refresh_after_input(
      EXPORTING
        io_program    = io_program
        io_flow       = io_flow
        io_session    = io_session
        iv_screen     = iv_screen
        iv_submitted  = iv_submitted
        iv_allowed    = lv_submit_allowed
        it_controls   = it_controls
      CHANGING
        cs_context    = cs_context
        ct_values     = ct_values
        ct_states     = ct_states
        co_menu       = co_menu
        cv_menu_field = cv_menu_field ).

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

  METHOD seed_table_states.
    DATA ls_state TYPE zif_gg_dynpro_types_v1=>ty_state.

    LOOP AT it_controls INTO DATA(ls_table_column)
        WHERE kind = 'TABLE_COLUMN'.
      LOOP AT it_values INTO DATA(ls_value)
          WHERE container = ls_table_column-parent
            AND name = ls_table_column-name
            AND row > 0.
        READ TABLE ct_states INTO ls_state
          WITH KEY container = ls_table_column-parent
                   name = COND #( WHEN ls_table_column-state_name IS INITIAL
                                  THEN ls_table_column-name
                                  ELSE ls_table_column-state_name )
                   row = 0.
        IF sy-subrc = 0.
          ls_state-row = ls_value-row.
          INSERT ls_state INTO TABLE ct_states.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD table_line_count.
    LOOP AT it_values INTO DATA(ls_value)
        WHERE container = iv_container.
      IF ls_value-row > rv_lines.
        rv_lines = ls_value-row.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD table_value_count.
    LOOP AT it_values TRANSPORTING NO FIELDS
        WHERE container = iv_container.
      rv_lines = rv_lines + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD table_loop_bounds.
    DATA lv_visible_rows TYPE i.

    ev_lines = table_line_count(
      it_values    = it_values
      iv_container = iv_table_control ).
    ev_start = 1.
    READ TABLE it_values INTO DATA(ls_top_line)
      WITH KEY container = `` name = 'GV_TOP_LINE' row = 0.
    IF sy-subrc = 0 AND ls_top_line-value IS NOT INITIAL.
      ev_start = CONV i( ls_top_line-value ).
    ENDIF.
    IF ev_start <= 0.
      ev_start = 1.
    ENDIF.
    READ TABLE it_controls INTO DATA(ls_control)
      WITH KEY screen = iv_screen kind = 'TABLE_CONTROL'
               name = iv_table_control.
    IF sy-subrc = 0.
      lv_visible_rows = ls_control-visible_rows.
    ENDIF.
    IF lv_visible_rows <= 0.
      lv_visible_rows = 1.
    ENDIF.
    ev_end = ev_start + lv_visible_rows - 1.
    IF ev_end > ev_lines.
      ev_end = ev_lines.
    ENDIF.
  ENDMETHOD.

  METHOD execute_output_step.
    DATA lv_table_row TYPE i.
    DATA ls_context TYPE zif_gg_dynpro_types_v1=>ty_module_context.

    io_session->set_event( 'PROCESS BEFORE OUTPUT' ).
    ls_context = cs_context.
    ls_context-screen = iv_screen.
    ls_context-module = is_step-module-name.
    CLEAR ls_context-ucomm.
    IF iv_table_control IS INITIAL.
      CLEAR: ls_context-table_control, ls_context-row,
             ls_context-loop_index, ls_context-loop_lines.
      io_program->process_output_module(
        EXPORTING
          is_context = ls_context
          io_session = io_session
        CHANGING
          ct_values  = ct_values
          ct_states  = ct_states ).
    ELSEIF iv_table_end >= iv_table_start.
      lv_table_row = iv_table_start.
      WHILE lv_table_row <= iv_table_end.
        ls_context-table_control = iv_table_control.
        ls_context-row = lv_table_row.
        ls_context-loop_index = lv_table_row - iv_table_start + 1.
        ls_context-loop_lines = iv_table_lines.
        io_program->process_output_module(
          EXPORTING
            is_context = ls_context
            io_session = io_session
          CHANGING
            ct_values  = ct_values
            ct_states  = ct_states ).
        lv_table_row = lv_table_row + 1.
      ENDWHILE.
    ENDIF.
  ENDMETHOD.

  METHOD execute_input_step.
    DATA lv_table_row TYPE i.

    IF is_step-module-on_request = abap_true
        AND ( iv_ucomm = 'RESET' OR iv_ucomm = 'BACK' OR iv_ucomm = 'CANCEL' ).
      RETURN.
    ENDIF.
    io_session->set_event( 'PROCESS AFTER INPUT' ).
    cs_context-screen = iv_screen.
    cs_context-module = is_step-module-name.
    cs_context-ucomm = iv_ucomm.
    IF iv_table_control IS INITIAL.
      io_program->process_input_module(
        EXPORTING
          is_context = cs_context
          io_session = io_session
        CHANGING
          ct_values  = ct_values ).
    ELSEIF iv_table_end >= iv_table_start.
      lv_table_row = iv_table_start.
      WHILE lv_table_row <= iv_table_end.
        cs_context-table_control = iv_table_control.
        cs_context-row = lv_table_row.
        cs_context-loop_index = lv_table_row - iv_table_start + 1.
        cs_context-loop_lines = iv_table_lines.
        io_program->process_input_module(
          EXPORTING
            is_context = cs_context
            io_session = io_session
          CHANGING
            ct_values  = ct_values ).
        lv_table_row = lv_table_row + 1.
      ENDWHILE.
    ENDIF.
  ENDMETHOD.

  METHOD execute_subscreen_output.
    LOOP AT io_flow->get_steps( ) INTO DATA(ls_step)
        WHERE screen = iv_screen AND phase = 'PBO' AND kind = 'MODULE'.
      execute_output_step(
        EXPORTING
          io_program       = io_program
          io_session       = io_session
          iv_screen        = iv_screen
          is_step          = ls_step
          iv_table_control = ``
          iv_table_start   = 1
          iv_table_end     = 0
          iv_table_lines   = 0
        CHANGING
          cs_context       = cs_context
          ct_values        = ct_values
          ct_states        = ct_states ).
    ENDLOOP.
  ENDMETHOD.

  METHOD execute_subscreen_input.
    LOOP AT io_flow->get_steps( ) INTO DATA(ls_step)
        WHERE screen = iv_screen AND phase = 'PAI' AND kind = 'MODULE'.
      execute_input_step(
        EXPORTING
          io_program       = io_program
          io_session       = io_session
          iv_screen        = iv_screen
          is_step          = ls_step
          iv_ucomm         = iv_ucomm
          iv_table_control = ``
          iv_table_start   = 1
          iv_table_end     = 0
          iv_table_lines   = 0
        CHANGING
          cs_context       = cs_context
          ct_values        = ct_values ).
    ENDLOOP.
  ENDMETHOD.

  METHOD resolve_subscreen.
    DATA ls_subscreen_value TYPE zif_gg_dynpro_types_v1=>ty_value.

    rv_screen = is_call-screen.
    IF rv_screen IS INITIAL AND is_call-screen_field IS NOT INITIAL.
      READ TABLE it_values INTO ls_subscreen_value
        WITH KEY container = ``
                 name = is_call-screen_field
                 row = 0.
      IF sy-subrc = 0.
        rv_screen = CONV #( ls_subscreen_value-value ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD modal_return_screen.
    READ TABLE it_screens INTO DATA(ls_screen) WITH KEY number = iv_screen.
    IF sy-subrc <> 0 OR ls_screen-modal = abap_false.
      RETURN.
    ENDIF.
    LOOP AT it_screens INTO DATA(ls_parent) WHERE modal = abap_false.
      rv_screen = ls_parent-number.
      EXIT.
    ENDLOOP.
  ENDMETHOD.

  METHOD destination_pbo.
    DATA lo_resumable TYPE REF TO zif_gg_resumable_v1.
    DATA lt_steps TYPE zcl_gg_host_dynpro_flow=>ty_steps.
    DATA lv_subscreen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

    IF iv_resume_enabled = abap_true AND iv_continuation IS NOT INITIAL.
      TRY.
          lo_resumable = io_resumable.
        CATCH cx_root.
          CLEAR lo_resumable.
      ENDTRY.
      IF lo_resumable IS NOT BOUND.
        TRY.
            lo_resumable ?= io_program.
          CATCH cx_root.
            CLEAR lo_resumable.
        ENDTRY.
      ENDIF.
      IF lo_resumable IS BOUND.
        TRY.
            lo_resumable->resume(
              is_resume  = VALUE #(
                continuation = VALUE #( id = iv_continuation )
                subrc        = 0 )
              io_session = io_session ).
            io_program->initialization(
              EXPORTING
                io_session = io_session
              CHANGING
                ct_values  = ct_values ).
          CATCH zcx_gg_control_flow.
        ENDTRY.
      ENDIF.
    ENDIF.
    IF iv_execute_pbo = abap_false.
      RETURN.
    ENDIF.

    lt_steps = io_flow->get_steps( ).
    IF line_exists( lt_steps[ screen = iv_screen phase = 'PBO' ] ).
      LOOP AT lt_steps INTO DATA(ls_step)
          WHERE screen = iv_screen AND phase = 'PBO'.
        CASE ls_step-kind.
          WHEN 'MODULE'.
            execute_output_step(
              EXPORTING
                io_program       = io_program
                io_session       = io_session
                iv_screen        = iv_screen
                is_step          = ls_step
                iv_table_control = ``
                iv_table_start   = 1
                iv_table_end     = 0
                iv_table_lines   = 0
              CHANGING
                cs_context       = cs_context
                ct_values        = ct_values
                ct_states        = ct_states ).
          WHEN 'SUBSCREEN'.
            lv_subscreen = resolve_subscreen(
              is_call   = ls_step-subscreen
              it_values = ct_values ).
            IF lv_subscreen IS NOT INITIAL AND lv_subscreen <> '0000'.
              execute_subscreen_output(
                EXPORTING
                  io_program = io_program
                  io_flow    = io_flow
                  io_session = io_session
                  iv_screen  = lv_subscreen
                CHANGING
                  cs_context = cs_context
                  ct_values  = ct_values
                  ct_states  = ct_states ).
            ENDIF.
        ENDCASE.
      ENDLOOP.
    ELSE.
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
    ENDIF.
  ENDMETHOD.

  METHOD refresh_after_input.
    DATA ls_status TYPE zif_gg_session_types_v1=>ty_gui_status.
    DATA lt_values TYPE zif_gg_dynpro_types_v1=>ty_values.

    IF iv_submitted <> abap_true OR iv_allowed <> abap_true.
      RETURN.
    ENDIF.
    ls_status = io_session->get_status( ).
    IF co_menu IS NOT BOUND
        AND ls_status-status IS INITIAL
        AND ls_status-active_ucomm IS INITIAL
        AND ls_status-active_pf_keys IS INITIAL
        AND ls_status-pf_actions IS INITIAL
        AND ls_status-icon_bar IS INITIAL
        AND ls_status-menus IS INITIAL.
      RETURN.
    ENDIF.

    lt_values = ct_values.
    destination_pbo(
      EXPORTING
        io_program        = io_program
        io_flow           = io_flow
        io_session        = io_session
        iv_screen         = iv_screen
        iv_resume_enabled = abap_false
        iv_continuation   = ``
        iv_execute_pbo    = abap_true
      CHANGING
        cs_context        = cs_context
        ct_values         = lt_values
        ct_states         = ct_states ).
    prepare_context_menu(
      EXPORTING
        io_program    = io_program
        io_session    = io_session
        iv_screen     = iv_screen
        it_controls   = it_controls
      CHANGING
        co_menu       = co_menu
        cv_menu_field = cv_menu_field ).
  ENDMETHOD.

  METHOD restore_cursor.
    IF iv_cursor_field IS INITIAL.
      RETURN.
    ENDIF.
    io_session->zif_gg_session_v1~get_dialog( )->set_cursor( VALUE #(
      field = iv_cursor_field
      row   = iv_cursor_row ) ).
  ENDMETHOD.

  METHOD prepare_context_menu.
    DATA lo_context_menu_provider TYPE REF TO zif_gg_context_menu_v1.
    DATA ls_context_control TYPE zcl_gg_host_dynpro_builder=>ty_control_record.

    CLEAR: co_menu, cv_menu_field.
    READ TABLE it_controls INTO ls_context_control
      WITH KEY screen = iv_screen kind = 'INPUT' context_menu = abap_true.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    TRY.
        lo_context_menu_provider ?= io_program.
      CATCH cx_root.
        RETURN.
    ENDTRY.
    IF lo_context_menu_provider IS BOUND.
      co_menu = lo_context_menu_provider->get_context_menu(
        iv_field   = ls_context_control-name
        io_session = io_session ).
      cv_menu_field = ls_context_control-name.
    ENDIF.
  ENDMETHOD.

  METHOD validate_submission.
    DATA(ls_status) = io_session->get_status( ).
    rv_allowed = abap_true.
    IF iv_submitted = abap_true
        AND io_menu IS BOUND
        AND context_command_present(
          io_menu  = io_menu
          iv_ucomm = iv_ucomm ) = abap_true
        AND context_command_enabled(
          io_menu  = io_menu
          iv_ucomm = iv_ucomm ) = abap_false.
      rv_allowed = abap_false.
      io_session->zif_gg_session_v1~message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = |Context command { iv_ucomm } is disabled| ) ).
      RETURN.
    ENDIF.
    IF iv_submitted = abap_true
        AND iv_ucomm <> 'BACK'
        AND line_exists( ls_status-excluded_ucomm[ table_line = iv_ucomm ] ).
      rv_allowed = abap_false.
      io_session->zif_gg_session_v1~message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = |Command { iv_ucomm } is excluded on dynpro screen { iv_screen }| ) ).
      RETURN.
    ENDIF.
    IF iv_submitted = abap_true
        AND iv_ucomm <> 'BACK'
        AND NOT line_exists( it_controls[ screen = iv_screen ucomm = iv_ucomm ] )
        AND NOT line_exists( ls_status-active_ucomm[ table_line = iv_ucomm ] )
        AND command_on_active_subscreen(
          it_controls       = it_controls
          it_active_screens = it_active_screens
          iv_ucomm          = iv_ucomm ) = abap_false.
      rv_allowed = abap_false.
      io_session->zif_gg_session_v1~message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = |Command { iv_ucomm } is not available on dynpro screen { iv_screen }| ) ).
    ENDIF.
  ENDMETHOD.

  METHOD context_command_present.
    IF io_menu IS NOT BOUND.
      RETURN.
    ENDIF.
    LOOP AT io_menu->get_items( ) INTO DATA(ls_item).
      IF ls_item-fcode = iv_ucomm.
        rv_present = abap_true.
        RETURN.
      ENDIF.
      IF ls_item-submenu IS BOUND
          AND context_command_present(
            io_menu  = ls_item-submenu
            iv_ucomm = iv_ucomm ) = abap_true.
        rv_present = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD context_command_enabled.
    IF io_menu IS NOT BOUND.
      RETURN.
    ENDIF.
    LOOP AT io_menu->get_items( ) INTO DATA(ls_item).
      IF ls_item-fcode = iv_ucomm.
        rv_enabled = xsdbool( ls_item-disabled = abap_false
                              AND ls_item-hidden = abap_false ).
        RETURN.
      ENDIF.
      IF ls_item-submenu IS BOUND
          AND context_command_present(
            io_menu  = ls_item-submenu
            iv_ucomm = iv_ucomm ) = abap_true.
        rv_enabled = context_command_enabled(
          io_menu  = ls_item-submenu
          iv_ucomm = iv_ucomm ).
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD command_on_active_subscreen.
    rv_allowed = abap_false.
    LOOP AT it_active_screens INTO DATA(ls_screen).
      IF line_exists( it_controls[ screen = ls_screen-number ucomm = iv_ucomm ] ).
        rv_allowed = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD clear_radio_siblings.
    FIELD-SYMBOLS <ls_value> TYPE zif_gg_dynpro_types_v1=>ty_value.

    LOOP AT it_input INTO DATA(ls_input)
        WHERE container IS INITIAL AND value = 'X'.
      READ TABLE it_controls INTO DATA(ls_selected)
        WITH KEY kind = 'RADIOBUTTON' name = ls_input-name.
      IF sy-subrc <> 0 OR ls_selected-group IS INITIAL.
        CONTINUE.
      ENDIF.
      LOOP AT it_controls INTO DATA(ls_sibling)
          WHERE kind = 'RADIOBUTTON'
            AND screen = ls_selected-screen
            AND group = ls_selected-group
            AND name <> ls_selected-name.
        READ TABLE ct_values ASSIGNING <ls_value>
          WITH KEY container = `` name = ls_sibling-name row = 0.
        IF sy-subrc = 0.
          CLEAR <ls_value>-value.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD add_page_actions.
    IF iv_terminal = abap_false.
      APPEND VALUE #( kind = zif_gg_host_html_v1=>action_submit ) TO ct_actions.
      APPEND VALUE #( kind  = zif_gg_host_html_v1=>action_back
                      ucomm = 'BACK' ) TO ct_actions.
    ENDIF.
  ENDMETHOD.

  METHOD render_terminal_page.
    IF cs_result-terminal_state = abap_true.
      cs_result-page_kind = zif_gg_host_html_v1=>page_terminal.
      cs_result-html = zcl_gg_host_renderer=>render_terminal(
        iv_session_id = iv_session_id
        iv_page_id    = iv_page_id
        iv_title      = 'Terminal'
        iv_text       = cs_result-terminal
        it_messages   = cs_result-messages ).
    ENDIF.
  ENDMETHOD.

  METHOD next_run_id.
    mv_run_id = mv_run_id + 1.
    rv_id = |DYNPRO-{ mv_run_id }|.
  ENDMETHOD.

  METHOD capture_navigation.
    DATA ls_continuation TYPE zif_gg_session_types_v1=>ty_continuation.
    DATA ls_screen_call TYPE zif_gg_session_types_v1=>ty_screen_call.
    DATA ls_transaction_call TYPE zif_gg_session_types_v1=>ty_transaction_call.
    DATA ls_submit_call TYPE zif_gg_session_types_v1=>ty_submit.

    IF ix_flow IS NOT BOUND.
      RETURN.
    ENDIF.
    ls_continuation = io_session->get_continuation( ).
    CASE ix_flow->mv_kind.
      WHEN zcx_gg_control_flow=>kind_call_screen.
        ls_screen_call = io_session->get_screen_call( ).
        cs_result-navigation = VALUE #(
          kind         = ix_flow->mv_kind
          target       = CONV string( ls_screen_call-screen )
          continuation = ls_continuation-id
          modal        = abap_true ).
      WHEN zcx_gg_control_flow=>kind_call_transaction
          OR zcx_gg_control_flow=>kind_leave_to_transaction.
        ls_transaction_call = io_session->get_transaction_call( ).
        cs_result-navigation = VALUE #(
          kind         = ix_flow->mv_kind
          target       = CONV string( ls_transaction_call-tcode )
          continuation = ls_continuation-id ).
      WHEN zcx_gg_control_flow=>kind_submit_return.
        ls_submit_call = io_session->get_submit_call( ).
        cs_result-navigation = VALUE #(
          kind         = ix_flow->mv_kind
          target       = CONV string( ls_submit_call-program )
          continuation = ls_continuation-id ).
        cs_result-submit = ls_submit_call.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
