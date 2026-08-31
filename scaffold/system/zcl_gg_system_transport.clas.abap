CLASS zcl_gg_system_transport DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_transport_service_v1.

ENDCLASS.

CLASS zcl_gg_system_transport IMPLEMENTATION.

  METHOD zif_gg_transport_service_v1~get_capabilities.
    rs_capabilities = VALUE #(
      display_only = abap_true
      can_change   = abap_false
      can_create   = abap_false
      can_save     = abap_false
      can_activate = abap_false
      can_release  = abap_false
      can_export   = abap_false
      can_debug    = abap_false
      explanation  = 'Display-only deployment: CTS persistence, release, and export are unavailable.' ).
  ENDMETHOD.

  METHOD zif_gg_transport_service_v1~get_request.
    DATA lv_request_id TYPE string.

    lv_request_id = iv_request_id.
    SHIFT lv_request_id LEFT DELETING LEADING space.
    TRANSLATE lv_request_id TO UPPER CASE.
    IF lv_request_id = 'DEVK900001'.
      rs_request = VALUE #(
        request_id     = 'DEVK900001'
        request_type   = 'Workbench request'
        owner          = 'DEVELOPER'
        short_text     = 'Flight dictionary display'
        status         = 'Modifiable'
        source_system  = 'DEV'
        target_system  = 'QAS'
        attributes     = 'Standard request; package ZGUI'
        documentation = 'Read-only transport fixture for the system transaction examples.' ).
    ELSE.
      rs_request-error = 'Request is unknown or not authorized for display.'.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_transport_service_v1~get_tasks.
    DATA lv_request_id TYPE string.

    lv_request_id = iv_request_id.
    SHIFT lv_request_id LEFT DELETING LEADING space.
    TRANSLATE lv_request_id TO UPPER CASE.
    IF lv_request_id = 'DEVK900001'.
      rt_tasks = VALUE #(
        ( request_id = 'DEVK900001'
          task_id    = 'DEVK900002'
          owner      = 'DEVELOPER'
          status     = 'Modifiable'
          short_text = 'Dictionary inspection task' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_transport_service_v1~get_objects.
    DATA lv_request_id TYPE string.

    lv_request_id = iv_request_id.
    SHIFT lv_request_id LEFT DELETING LEADING space.
    TRANSLATE lv_request_id TO UPPER CASE.
    IF lv_request_id = 'DEVK900001'.
      rt_objects = VALUE #(
        ( request_id  = 'DEVK900001'
          object_id   = 'DEVK900002-1'
          object_type = 'TABL'
          object_name = 'ZSFLIGHT'
          description = 'Flight schedule fixture' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_transport_service_v1~get_logs.
    DATA lv_request_id TYPE string.

    lv_request_id = iv_request_id.
    SHIFT lv_request_id LEFT DELETING LEADING space.
    TRANSLATE lv_request_id TO UPPER CASE.
    IF lv_request_id = 'DEVK900001'.
      rt_logs = VALUE #(
        ( request_id = 'DEVK900001' sequence = 1 severity = 'INFO'
          text = 'Request metadata loaded from the server transport catalog.' )
        ( request_id = 'DEVK900001' sequence = 2 severity = 'INFO'
          text = 'No release or export operation has been performed.' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_transport_service_v1~get_request_ids.
    rt_request_ids = VALUE string_table( ( `DEVK900001` ) ).
  ENDMETHOD.

ENDCLASS.
