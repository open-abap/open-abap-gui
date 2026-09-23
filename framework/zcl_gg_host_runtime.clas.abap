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
* A report a user starts opens on its selection screen and waits for Execute,
* so this is on by default. SUBMIT arrives with its values already supplied and
* passes abap_false; it stops only when it asked for VIA SELECTION-SCREEN.
        iv_interactive           TYPE abap_bool DEFAULT abap_true
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
             session_id          TYPE string,
             program             TYPE zif_gg_session_types_v1=>ty_program,
             batch               TYPE abap_bool,
             report              TYPE REF TO zif_gg_report_v1,
             submit_report       TYPE REF TO zif_gg_report_v1,
             dynpro_program      TYPE REF TO zif_gg_dynpro_v1,
             resumable           TYPE REF TO zif_gg_resumable_v1,
             lifecycle           TYPE REF TO zif_gg_session_lifecycle_v1,
             pending_popup_ucomm TYPE zif_gg_dynpro_types_v1=>ty_ucomm,
             pending_help        TYPE zif_gg_dynpro_types_v1=>ty_name,
             next_page           TYPE i,
             pending_navigation  TYPE zif_gg_host_html_v1=>ty_navigation,
             pending_submit      TYPE zif_gg_session_types_v1=>ty_submit,
             last_result         TYPE zcl_gg_host=>ty_result,
             last_dynpro         TYPE zcl_gg_host_dynpro=>ty_result,
             results             TYPE STANDARD TABLE OF zcl_gg_host=>ty_result WITH DEFAULT KEY,
             pages               TYPE zif_gg_host_html_v1=>ty_pages,
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

    CLASS-METHODS queue_control_event
      IMPORTING
        is_request TYPE zif_gg_host_html_v1=>ty_request.

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
    DATA lo_screen_provider TYPE REF TO zif_gg_screen_provider_v1.
    DATA lo_resumable TYPE REF TO zif_gg_resumable_v1.
    DATA lo_context TYPE REF TO zif_gg_context_menu_v1.
    DATA lo_report_dynpro TYPE REF TO zif_gg_dynpro_v1.
    DATA lo_lifecycle TYPE REF TO zif_gg_session_lifecycle_v1.

    " A new host session starts with a fresh browser control surface. The
    " control classes keep their snapshots statically, so leaving a prior
    " session in place would let old controls overlay the next page.
    cl_gui_control=>clear( ).
    cl_alv_tree_base=>clear_instances( ).
    zcl_gg_host_surface=>clear( ).
    lv_session_id = next_session_id( ).
    IF io_dynpro_program IS BOUND.
      TRY.
          lo_resumable ?= io_dynpro_program.
        CATCH cx_root.
          CLEAR lo_resumable.
      ENDTRY.
      ls_dynpro = zcl_gg_host_dynpro=>run(
        io_program    = io_dynpro_program
        io_resumable  = lo_resumable
        iv_submitted  = abap_false
        iv_session_id = lv_session_id
        iv_page_id    = |{ lv_session_id }-1| ).
    ELSEIF io_report IS BOUND.
      TRY.
          lo_resumable ?= io_report.
        CATCH cx_root.
          CLEAR lo_resumable.
      ENDTRY.
      ls_result = zcl_gg_host=>run(
        io_report              = io_report
        io_submit_report       = io_submit_report
        iv_program             = iv_program
        iv_batch               = iv_batch
        it_input               = it_input
        iv_stop_before_start   = iv_selection_screen_only
        iv_present_selection   = iv_interactive
        iv_session_id          = lv_session_id
        iv_page_id             = |{ lv_session_id }-1|
        iv_pause_at_navigation = abap_true ).
      TRY.
          lo_screen_provider ?= io_report.
        CATCH cx_root.
          CLEAR lo_screen_provider.
      ENDTRY.
      TRY.
          lo_context ?= io_report.
        CATCH cx_root.
          CLEAR lo_context.
      ENDTRY.
      TRY.
          lo_lifecycle ?= io_report.
        CATCH cx_root.
          CLEAR lo_lifecycle.
      ENDTRY.
      IF lo_screen_provider IS BOUND
          AND ls_result-navigation-kind = zcx_gg_control_flow=>kind_call_screen.
        lo_report_dynpro = NEW zcl_gg_host_report_dynpro(
          io_provider  = lo_screen_provider
          io_resumable = lo_resumable
          io_context   = lo_context ).
        ls_dynpro = zcl_gg_host_dynpro=>run(
          io_program    = lo_report_dynpro
          io_resumable  = lo_resumable
          iv_submitted  = abap_false
          iv_session_id = lv_session_id
          iv_page_id    = |{ lv_session_id }-1| ).
      ENDIF.
    ELSE.
      rs_response = invalid_response( 'A report or dynpro program is required' ).
      RETURN.
    ENDIF.
    ls_session-session_id = lv_session_id.
    ls_session-program = iv_program.
    ls_session-batch = iv_batch.
    ls_session-report = io_report.
    ls_session-submit_report = io_submit_report.
    ls_session-resumable = lo_resumable.
    ls_session-lifecycle = lo_lifecycle.
    IF io_dynpro_program IS BOUND.
      ls_session-dynpro_program = io_dynpro_program.
    ELSE.
      ls_session-dynpro_program = lo_report_dynpro.
    ENDIF.
    ls_session-next_page = 2.
    IF ls_session-dynpro_program IS BOUND.
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
         AND is_request-action <> zif_gg_host_html_v1=>action_tree_event
         AND is_request-action <> zif_gg_host_html_v1=>action_pf
        AND is_request-action <> zif_gg_host_html_v1=>action_tab
        AND is_request-action <> zif_gg_host_html_v1=>action_screen
        AND is_request-action <> zif_gg_host_html_v1=>action_back
        AND is_request-action <> zif_gg_host_html_v1=>action_help
        AND is_request-action <> zif_gg_host_html_v1=>action_value_help
        AND is_request-action <> zif_gg_host_html_v1=>action_popup
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
    DATA ls_pf_action TYPE zif_gg_session_types_v1=>ty_pf_action.
    DATA lv_page_id TYPE string.
    DATA ls_transaction TYPE zcl_gg_transaction_registry=>ty_transaction.
    DATA lo_object TYPE REF TO object.
    DATA lo_report TYPE REF TO zif_gg_report_v1.
    DATA lo_dynpro TYPE REF TO zif_gg_dynpro_v1.
    DATA lv_popup_action TYPE string.
    DATA lv_help_request TYPE zif_gg_dynpro_types_v1=>ty_name.
    DATA lv_resume_continuation TYPE string.
    DATA lv_list_back TYPE abap_bool.
    DATA lv_action_receipt TYPE string.

    ls_session = is_session.
    lv_list_back = xsdbool(
      is_request-action = zif_gg_host_html_v1=>action_back
      AND ls_session-last_dynpro-page_kind = zif_gg_host_html_v1=>page_list ).
    lt_dynpro_values = is_request-dynpro_values.
    IF lt_dynpro_values IS INITIAL.
      lt_dynpro_values = ls_session-last_dynpro-values.
    ENDIF.
    lv_ucomm = CONV zif_gg_dynpro_types_v1=>ty_ucomm( is_request-ucomm ).
    IF is_request-action = zif_gg_host_html_v1=>action_pf.
      READ TABLE ls_session-last_dynpro-status-pf_actions INTO ls_pf_action
        WITH KEY number = is_request-pf_key.
      IF sy-subrc = 0.
        lv_ucomm = ls_pf_action-ucomm.
      ENDIF.
    ENDIF.
    IF is_request-action = zif_gg_host_html_v1=>action_popup.
      lv_ucomm = CONV zif_gg_dynpro_types_v1=>ty_ucomm( is_request-target ).
      lv_popup_action = |{ is_request-target }:{ is_request-value }|.
      IF is_request-target = 'INFORM'.
        lv_help_request = ls_session-pending_help.
        IF lv_help_request IS INITIAL
            AND ls_session-pending_popup_ucomm IS NOT INITIAL.
          lv_ucomm = ls_session-pending_popup_ucomm.
        ENDIF.
      ENDIF.
    ELSEIF is_request-action = zif_gg_host_html_v1=>action_help.
      ls_session-pending_help = CONV zif_gg_dynpro_types_v1=>ty_name( is_request-target ).
      CLEAR ls_session-pending_popup_ucomm.
    ELSEIF is_request-action <> zif_gg_host_html_v1=>action_value_help.
      ls_session-pending_popup_ucomm = lv_ucomm.
    ENDIF.
    IF lv_ucomm IS INITIAL AND lv_list_back = abap_false.
      lv_ucomm = 'BACK'.
    ENDIF.
    IF is_request-action <> zif_gg_host_html_v1=>action_exit
        AND is_request-action <> zif_gg_host_html_v1=>action_back
        AND is_request-action <> zif_gg_host_html_v1=>action_help
        AND is_request-action <> zif_gg_host_html_v1=>action_value_help
        AND is_request-action <> zif_gg_host_html_v1=>action_popup.
      lv_action_receipt = |Action { COND string( WHEN is_request-ucomm IS INITIAL THEN is_request-action ELSE is_request-ucomm ) } processed|.
    ENDIF.
    IF lv_list_back = abap_false
        AND ls_session-last_dynpro-navigation-kind = zcx_gg_control_flow=>kind_call_screen.
      lv_resume_continuation = ls_session-last_dynpro-navigation-continuation.
    ENDIF.
    queue_control_event( is_request ).
    lv_page_id = |{ ls_session-session_id }-{ ls_session-next_page }|.
    ls_dynpro = zcl_gg_host_dynpro=>run(
      io_program             = ls_session-dynpro_program
      iv_ucomm               = lv_ucomm
      iv_submitted           = xsdbool( lv_list_back = abap_false
                                  AND is_request-action <> zif_gg_host_html_v1=>action_help
                                  AND is_request-action <> zif_gg_host_html_v1=>action_value_help
                                  AND NOT ( is_request-action = zif_gg_host_html_v1=>action_popup
                                            AND is_request-target = 'INFORM'
                                            AND lv_help_request IS NOT INITIAL ) )
      it_values              = lt_dynpro_values
      iv_field               = CONV zif_gg_dynpro_types_v1=>ty_name( is_request-target )
      iv_row                 = is_request-row
      iv_cursor_field        = COND #( WHEN is_request-cursor_field IS INITIAL
                                      THEN ls_session-last_dynpro-cursor-field
                                      ELSE CONV zif_gg_dynpro_types_v1=>ty_name( is_request-cursor_field ) )
      iv_cursor_row          = COND #( WHEN is_request-cursor_field IS INITIAL
                                      THEN ls_session-last_dynpro-cursor-row
                                      ELSE 0 )
      iv_value_request       = CONV zif_gg_dynpro_types_v1=>ty_name(
                           COND string( WHEN is_request-action = zif_gg_host_html_v1=>action_value_help
                                        THEN is_request-target ELSE `` ) )
      iv_help_request        = COND #( WHEN is_request-action = zif_gg_host_html_v1=>action_help
                                 THEN CONV zif_gg_dynpro_types_v1=>ty_name( is_request-target )
                                 ELSE lv_help_request )
      iv_popup_action        = lv_popup_action
      it_popup_values        = is_request-dynpro_values
      is_modal_position      = ls_session-last_dynpro-modal_position
      io_resumable           = ls_session-resumable
      iv_resume_continuation = lv_resume_continuation
      iv_screen              = COND #( WHEN lv_list_back = abap_true
                                      THEN ls_session-last_dynpro-list_return_screen
                                      ELSE ls_session-last_dynpro-screen )
      iv_session_id          = ls_session-session_id
      iv_page_id             = lv_page_id
      iv_action_receipt      = lv_action_receipt ).
    IF ls_dynpro-popup-kind IS INITIAL.
      CLEAR ls_session-pending_popup_ucomm.
      CLEAR ls_session-pending_help.
    ENDIF.
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
        iv_interactive           = abap_false
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

  METHOD queue_control_event.
    IF is_request-action = zif_gg_host_html_v1=>action_tree_event.
      cl_gui_cfw=>queue_browser_event(
        event     = is_request-tree_event
        node_key  = is_request-tree_node
        fieldname = is_request-tree_field
        value     = is_request-tree_value
        checked   = is_request-tree_checked ).
      IF is_request-tree_event = 'TREE_SELECT'
          OR is_request-tree_event = 'TREE_TOGGLE'.
        cl_alv_tree_base=>dispatch_browser_event(
          event     = is_request-tree_event
          node_key  = is_request-tree_node
          fieldname = is_request-tree_field
          value     = is_request-tree_value
          checked   = is_request-tree_checked ).
      ENDIF.
    ELSEIF is_request-action = zif_gg_host_html_v1=>action_command
        AND ( is_request-ucomm = '&REFRESH'
          OR is_request-ucomm = '&SUMC' ).
      cl_gui_cfw=>queue_browser_event(
        event = 'COMMAND'
        value = is_request-ucomm ).
    ENDIF.
  ENDMETHOD.

  METHOD dispatch_report.
    DATA ls_session TYPE ty_session.
    DATA ls_result TYPE zcl_gg_host=>ty_result.
    DATA lv_index TYPE i.
    DATA lv_page_id TYPE string.
    DATA lv_ucomm TYPE zif_gg_session_types_v1=>ty_ucomm.
    DATA lv_selection_tab TYPE zif_gg_session_types_v1=>ty_ucomm.
    DATA lt_input TYPE zif_gg_selection_screen_types=>ty_values.
    DATA lv_action_receipt TYPE string.

    TRY.
        ls_session = is_session.
        READ TABLE ls_session-last_result-screen_snapshot-tabs INTO DATA(ls_selected_tab) WITH KEY selected = abap_true.
        IF sy-subrc = 0.
          lv_selection_tab = ls_selected_tab-ucomm.
        ENDIF.
        lt_input = ls_session-last_result-values.
        LOOP AT is_request-values INTO DATA(ls_request_value).
          DELETE lt_input WHERE name = ls_request_value-name.
          INSERT ls_request_value INTO TABLE lt_input.
        ENDLOOP.
        lv_ucomm = CONV zif_gg_session_types_v1=>ty_ucomm( is_request-ucomm ).
        IF is_request-dynamic_action IS NOT INITIAL.
          lv_ucomm = COND #( WHEN is_request-dynamic_action = 'RESET' THEN 'RESET' ELSE 'DLGWIN' ).
        ENDIF.
        IF lv_ucomm IS INITIAL.
          lv_ucomm = COND #( WHEN is_request-action = zif_gg_host_html_v1=>action_exit
                         THEN 'ECAN'
                         ELSE 'ONLI' ).
        ENDIF.
        IF is_request-action <> zif_gg_host_html_v1=>action_back
            AND is_request-action <> zif_gg_host_html_v1=>action_help
            AND is_request-action <> zif_gg_host_html_v1=>action_value_help
            AND is_request-action <> zif_gg_host_html_v1=>action_popup.
          lv_action_receipt = COND string(
            WHEN is_request-action = zif_gg_host_html_v1=>action_exit
            THEN 'Selection canceled'
            ELSE |Action { COND string( WHEN is_request-ucomm IS INITIAL THEN is_request-action ELSE is_request-ucomm ) } processed| ).
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
              iv_pause_at_navigation = abap_true
              iv_action_receipt      = lv_action_receipt ).
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
              iv_pause_at_navigation = abap_true
              iv_action_receipt      = lv_action_receipt ).
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
              iv_pause_at_navigation = abap_true
              iv_action_receipt      = lv_action_receipt ).
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
              iv_stop_before_start   = xsdbool( is_request-direct_action = abap_false )
              iv_pause_at_navigation = abap_true
              iv_action_receipt      = lv_action_receipt ).
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
              iv_stop_before_start   = xsdbool( is_request-direct_action = abap_false )
              iv_pause_at_navigation = abap_true
              iv_action_receipt      = lv_action_receipt ).
          WHEN zif_gg_host_html_v1=>action_exit.
            ls_result = zcl_gg_host=>run(
              io_report            = ls_session-report
              iv_program           = ls_session-program
              iv_batch             = ls_session-batch
              it_input             = lt_input
              iv_exit_ucomm        = 'ECAN'
              iv_ucomm             = 'ECAN'
              is_resume_navigation = ls_session-pending_navigation
              is_resume_submit     = ls_session-pending_submit
              iv_resume_subrc      = 4
              iv_stop_before_start = abap_true
              iv_session_id        = ls_session-session_id
              iv_page_id           = lv_page_id
              iv_can_back          = xsdbool( lines( ls_session-results ) > 0 )
              iv_action_receipt    = lv_action_receipt ).
          WHEN zif_gg_host_html_v1=>action_submit
              OR zif_gg_host_html_v1=>action_tab
              OR zif_gg_host_html_v1=>action_back.
            ls_result = zcl_gg_host=>run(
              io_report              = ls_session-report
              io_submit_report       = ls_session-submit_report
              iv_program             = ls_session-program
              iv_batch               = ls_session-batch
              it_input               = lt_input
              it_dynamic_input       = is_request-dynamic_values
              iv_dynamic_action      = is_request-dynamic_action
              iv_ucomm               = lv_ucomm
              iv_user_command        = COND #(
              WHEN is_request-ucomm IS NOT INITIAL
              THEN CONV zif_gg_list_processing_types_v1=>ty_ucomm( is_request-ucomm ) )
              iv_selection_screen    = COND #(
              WHEN ls_session-pending_navigation-kind = zcx_gg_control_flow=>kind_call_selection_screen
              THEN CONV #( ls_session-pending_navigation-target )
              ELSE '1000' )
              iv_selection_tab       = lv_selection_tab
              is_resume_navigation   = ls_session-pending_navigation
              is_resume_submit       = ls_session-pending_submit
              iv_stop_before_start   = xsdbool( lv_ucomm <> 'ONLI' AND lv_ucomm <> 'ECAN' )
              iv_session_id          = ls_session-session_id
              iv_page_id             = lv_page_id
              iv_can_back            = xsdbool( lines( ls_session-results ) > 0 )
              iv_pause_at_navigation = abap_true
              iv_action_receipt      = lv_action_receipt ).
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
              iv_pause_at_navigation = abap_true
              iv_action_receipt      = lv_action_receipt ).
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
      CATCH cx_root INTO DATA(lx_dispatch_report).
        rs_response = invalid_response( |Report dispatch failed: { lx_dispatch_report->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD close.
    READ TABLE mt_sessions INTO DATA(ls_session)
      WITH KEY session_id = iv_session_id.
    IF sy-subrc = 0 AND ls_session-lifecycle IS BOUND.
      ls_session-lifecycle->on_close( ).
    ENDIF.
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
    IF ls_session-lifecycle IS BOUND.
      ls_session-lifecycle->on_close( ).
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
    IF ro_report IS NOT BOUND.
      lv_class_name = iv_program.
      TRANSLATE lv_class_name TO UPPER CASE.
      IF lv_class_name CP 'ZGG_GUI_*'.
        REPLACE FIRST OCCURRENCE OF 'ZGG_GUI_' IN lv_class_name WITH 'ZCL_CV_'.
      ELSE.
        REPLACE FIRST OCCURRENCE OF 'ZGG_' IN lv_class_name WITH 'ZCL_CV_'.
      ENDIF.
      TRY.
          CREATE OBJECT ro_report TYPE (lv_class_name).
        CATCH cx_root.
          CLEAR ro_report.
      ENDTRY.
    ENDIF.
  ENDMETHOD.

  METHOD clear.
    LOOP AT mt_sessions INTO DATA(ls_session).
      IF ls_session-lifecycle IS BOUND.
        ls_session-lifecycle->on_close( ).
      ENDIF.
    ENDLOOP.
    CLEAR mt_sessions.
    CLEAR mv_session_id.
    zcl_gg_host_compatibility=>clear_parameters( ).
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
    DATA lv_control_action TYPE abap_bool.

    IF is_request-action = zif_gg_host_html_v1=>action_tree_event.
      IF is_request-tree_event IS INITIAL OR is_request-tree_node IS INITIAL.
        rv_error = 'Tree event is missing its event or node key'.
      ENDIF.
      RETURN.
    ENDIF.

    IF is_request-action = zif_gg_host_html_v1=>action_command.
      lv_ucomm = CONV #( is_request-ucomm ).
      lv_control_action = xsdbool(
        is_page-html CS |value="COMMAND:{ zcl_gg_host_html=>escape_attribute( CONV string( lv_ucomm ) ) }"| ).
      IF lv_ucomm IS INITIAL
          OR ( NOT line_exists( is_page-status-active_ucomm[ table_line = lv_ucomm ] )
            AND lv_control_action = abap_false )
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
        AND ( is_request-pf_key < 1
          OR NOT line_exists( is_page-status-active_pf_keys[ table_line = is_request-pf_key ] ) ).
      rv_error = 'PF key is not active for the current host page'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
