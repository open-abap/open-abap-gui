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

  PRIVATE SECTION.
    DATA mo_list      TYPE REF TO zcl_gg_host_list.
    DATA mv_program   TYPE zif_gg_session_types_v1=>ty_program.
    DATA mv_event     TYPE zif_gg_session_types_v1=>ty_event.
    DATA mv_batch     TYPE abap_bool.
    DATA mv_suppress  TYPE abap_bool.
    DATA mv_title     TYPE string.
    DATA ms_status    TYPE zif_gg_session_types_v1=>ty_gui_status.
    DATA ms_cursor    TYPE zif_gg_session_types_v1=>ty_dialog_cursor.
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
    unsupported( 'SET SCREEN' ).
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~leave_screen.
    unsupported( 'LEAVE SCREEN' ).
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~leave_to_screen.
    unsupported( 'LEAVE TO SCREEN' ).
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~call_screen.
    unsupported( 'CALL SCREEN' ).
  ENDMETHOD.

  METHOD zif_gg_dialog_session_v1~call_selection_screen.
    unsupported( 'CALL SELECTION-SCREEN' ).
  ENDMETHOD.

  METHOD zif_gg_navigation_v1~leave_program.
    RAISE EXCEPTION NEW zcx_gg_control_flow( iv_kind = zcx_gg_control_flow=>kind_leave_program ).
  ENDMETHOD.

  METHOD zif_gg_navigation_v1~submit.
    unsupported( 'SUBMIT' ).
  ENDMETHOD.

  METHOD zif_gg_navigation_v1~submit_and_return.
    unsupported( 'SUBMIT AND RETURN' ).
  ENDMETHOD.

  METHOD zif_gg_navigation_v1~get_list_from_memory.
    unsupported( 'LIST_FROM_MEMORY' ).
  ENDMETHOD.

  METHOD zif_gg_navigation_v1~call_transaction.
    unsupported( 'CALL TRANSACTION' ).
  ENDMETHOD.

  METHOD zif_gg_navigation_v1~leave_to_transaction.
    unsupported( 'LEAVE TO TRANSACTION' ).
  ENDMETHOD.

ENDCLASS.
