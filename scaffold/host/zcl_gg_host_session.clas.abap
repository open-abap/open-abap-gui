CLASS zcl_gg_host_session DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Execution scoped session for one report run. It is also the dialog and the
* navigation facade, because a host has nowhere else to put them and ABAP
* single inheritance would otherwise force a chain of wrappers.
*
* Operations this host cannot honour yet raise zcx_gg_control_flow with
* kind_unsupported and the ABAP statement they model, so an example that runs
* ahead of the host fails loudly instead of silently doing nothing.

  PUBLIC SECTION.
    INTERFACES zif_gg_session_v1.
    INTERFACES zif_gg_dialog_session_v1.
    INTERFACES zif_gg_navigation_v1.

    TYPES ty_messages TYPE STANDARD TABLE OF zif_gg_session_types_v1=>ty_message
      WITH DEFAULT KEY.

    METHODS constructor
      IMPORTING
        io_list    TYPE REF TO zcl_gg_host_list
        iv_program TYPE zif_gg_session_types_v1=>ty_program OPTIONAL
        iv_batch   TYPE abap_bool DEFAULT abap_false.

    METHODS set_event
      IMPORTING
        iv_event TYPE zif_gg_session_types_v1=>ty_event.

    METHODS get_messages
      RETURNING
        VALUE(rt_messages) TYPE ty_messages.

    METHODS is_dialog_suppressed
      RETURNING
        VALUE(rv_suppressed) TYPE abap_bool.

    METHODS get_selection_call
      RETURNING
        VALUE(rs_call) TYPE zif_gg_session_types_v1=>ty_selection_screen_call.

    METHODS get_screen_call
      RETURNING
        VALUE(rs_call) TYPE zif_gg_session_types_v1=>ty_screen_call.

    METHODS get_submit_call
      RETURNING
        VALUE(rs_call) TYPE zif_gg_session_types_v1=>ty_submit.

    METHODS get_transaction_call
      RETURNING
        VALUE(rs_call) TYPE zif_gg_session_types_v1=>ty_transaction_call.

    METHODS get_continuation
      RETURNING
        VALUE(rs_continuation) TYPE zif_gg_session_types_v1=>ty_continuation.

    METHODS get_next_screen
      RETURNING
        VALUE(rv_screen) TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

    METHODS set_list_from_memory
      IMPORTING
        it_lines TYPE zif_gg_session_types_v1=>ty_memory_list.

  PRIVATE SECTION.
    DATA mo_list      TYPE REF TO zcl_gg_host_list.
    DATA mv_program   TYPE zif_gg_session_types_v1=>ty_program.
    DATA mv_event     TYPE zif_gg_session_types_v1=>ty_event.
    DATA mv_batch     TYPE abap_bool.
    DATA mv_suppress  TYPE abap_bool.
    DATA mv_next_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    DATA mv_title     TYPE string.
    DATA ms_status    TYPE zif_gg_session_types_v1=>ty_gui_status.
    DATA ms_cursor    TYPE zif_gg_session_types_v1=>ty_dialog_cursor.
    DATA ms_selection_call TYPE zif_gg_session_types_v1=>ty_selection_screen_call.
    DATA ms_screen_call TYPE zif_gg_session_types_v1=>ty_screen_call.
    DATA ms_transaction_call TYPE zif_gg_session_types_v1=>ty_transaction_call.
    DATA ms_submit_call TYPE zif_gg_session_types_v1=>ty_submit.
    DATA ms_continuation TYPE zif_gg_session_types_v1=>ty_continuation.
    DATA mt_memory_lines TYPE zif_gg_session_types_v1=>ty_memory_list.
    DATA mt_messages  TYPE ty_messages.

    METHODS unsupported
      IMPORTING
        iv_operation TYPE string.

ENDCLASS.

CLASS zcl_gg_host_session IMPLEMENTATION.

  METHOD constructor.
    mo_list    = io_list.
    mv_program = iv_program.
    mv_batch   = iv_batch.
  ENDMETHOD.

  METHOD set_event.
    mv_event = iv_event.
  ENDMETHOD.

  METHOD get_messages.
    rt_messages = mt_messages.
  ENDMETHOD.

  METHOD is_dialog_suppressed.
    rv_suppressed = mv_suppress.
  ENDMETHOD.

  METHOD get_selection_call.
    rs_call = ms_selection_call.
  ENDMETHOD.

  METHOD get_screen_call.
    rs_call = ms_screen_call.
  ENDMETHOD.

  METHOD get_submit_call.
    rs_call = ms_submit_call.
  ENDMETHOD.

  METHOD get_transaction_call.
    rs_call = ms_transaction_call.
  ENDMETHOD.

  METHOD get_continuation.
    rs_continuation = ms_continuation.
  ENDMETHOD.

  METHOD get_next_screen.
    rv_screen = mv_next_screen.
  ENDMETHOD.

  METHOD set_list_from_memory.
    mt_memory_lines = it_lines.
  ENDMETHOD.

  METHOD unsupported.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_unsupported
      iv_operation = iv_operation ).
  ENDMETHOD.

  METHOD zif_gg_session_v1~get_context.
    rs_context-processor       = zif_gg_session_types_v1=>processor_report.
    rs_context-program-program = mv_program.
    rs_context-program-event   = mv_event.
    rs_context-program-batch   = mv_batch.
    rs_context-list            = mo_list->get_context( ).
  ENDMETHOD.

  METHOD zif_gg_session_v1~get_dialog.
    ro_dialog = me.
  ENDMETHOD.

  METHOD zif_gg_session_v1~get_list.
    ro_list = mo_list.
  ENDMETHOD.

  METHOD zif_gg_session_v1~get_navigation.
    ro_navigation = me.
  ENDMETHOD.

  METHOD zif_gg_session_v1~message.
    APPEND is_message TO mt_messages.
    IF is_message-type = zif_gg_session_types_v1=>message_type_info
        OR is_message-type = zif_gg_session_types_v1=>message_type_success.
      RETURN.
    ENDIF.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_message
      iv_operation = is_message-text ).
  ENDMETHOD.

  METHOD zif_gg_session_v1~stop.
    RAISE EXCEPTION NEW zcx_gg_control_flow( iv_kind = zcx_gg_control_flow=>kind_stop ).
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~set_title.
    mv_title = iv_title.
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~set_status.
    ms_status = is_status.
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~set_cursor.
    ms_cursor = is_cursor.
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~suppress_dialog.
    mv_suppress = abap_true.
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~set_next_screen.
    mv_next_screen = iv_screen.
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~leave_screen.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_leave_screen
      iv_operation = 'LEAVE SCREEN' ).
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~leave_to_screen.
    mv_next_screen = iv_screen.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_leave_to_screen
      iv_operation = |LEAVE TO SCREEN { iv_screen }| ).
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~call_screen.
    ms_screen_call = is_call.
    ms_continuation = is_continuation.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_call_screen
      iv_operation = 'CALL SCREEN' ).
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~call_selection_screen.
    ms_selection_call = is_call.
    ms_continuation = is_continuation.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_call_selection_screen
      iv_operation = 'CALL SELECTION-SCREEN' ).
  ENDMETHOD.

  METHOD zif_gg_navigation_v1~leave_program.
    RAISE EXCEPTION NEW zcx_gg_control_flow( iv_kind = zcx_gg_control_flow=>kind_leave_program ).
  ENDMETHOD.

  METHOD zif_gg_navigation_v1~submit.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_submit
      iv_operation = |SUBMIT { is_submit-program }| ).
  ENDMETHOD.

  METHOD zif_gg_navigation_v1~submit_and_return.
    ms_submit_call = is_submit.
    ms_continuation = is_continuation.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_submit_return
      iv_operation = |SUBMIT { is_submit-program } AND RETURN| ).
  ENDMETHOD.

  METHOD zif_gg_navigation_v1~get_list_from_memory.
    rt_lines = mt_memory_lines.
  ENDMETHOD.

  METHOD zif_gg_navigation_v1~call_transaction.
    ms_transaction_call = is_call.
    ms_continuation = is_continuation.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_call_transaction
      iv_operation = |CALL TRANSACTION { is_call-tcode }| ).
  ENDMETHOD.

  METHOD zif_gg_navigation_v1~leave_to_transaction.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_leave_to_transaction
      iv_operation = |LEAVE TO TRANSACTION { is_call-tcode }| ).
  ENDMETHOD.

ENDCLASS.
