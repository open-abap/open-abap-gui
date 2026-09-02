CLASS zcl_gg_system_transport DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Read-only transport catalog. Request numbers follow this deployment's
* transport-number policy: three system-id letters, a two-character category
* per transport type, and five digits. The catalog record, not the number,
* decides which selection tab may display a request.

  PUBLIC SECTION.
    INTERFACES zif_gg_transport_service_v1.

  PRIVATE SECTION.
    METHODS catalog
      RETURNING
        VALUE(rt_requests) TYPE zif_gg_system_types_v1=>ty_transport_requests.
    METHODS type_label
      IMPORTING
        iv_transport_type TYPE string
      RETURNING
        VALUE(rv_label)   TYPE string.
    METHODS check_number
      IMPORTING
        iv_transport_type TYPE string
        iv_request_id     TYPE string
      RETURNING
        VALUE(rv_error)   TYPE string.
    METHODS normalized
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

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

  METHOD catalog.
    rt_requests = VALUE #(
      ( request_id     = 'DEVK900001'
        transport_type = zif_gg_system_types_v1=>transport_standard
        request_type   = 'Workbench request'
        owner          = 'DEVELOPER'
        short_text     = 'Flight dictionary display'
        status         = 'Modifiable'
        source_system  = 'DEV'
        target_system  = 'QAS'
        attributes     = 'Standard request; package ZGUI'
        documentation  = 'Read-only transport fixture for the system transaction examples.' )
      ( request_id     = 'DEVK900010'
        transport_type = zif_gg_system_types_v1=>transport_piece
        request_type   = 'Piece list'
        owner          = 'DEVELOPER'
        short_text     = 'Flight dictionary piece list'
        status         = 'Modifiable'
        source_system  = 'DEV'
        target_system  = ''
        attributes     = 'Piece list; package ZGUI'
        documentation  = 'Piece lists collect objects without a transport route.' )
      ( request_id     = 'DEVKO00001'
        transport_type = zif_gg_system_types_v1=>transport_client
        request_type   = 'Client transport'
        owner          = 'ADMIN'
        short_text     = 'Client copy of the flight fixtures'
        status         = 'Modifiable'
        source_system  = 'DEV'
        target_system  = 'QAS'
        attributes     = 'Client transport; source client 100'
        documentation  = 'Client transports copy client-dependent data between clients.' )
      ( request_id     = 'DEVKD00001'
        transport_type = zif_gg_system_types_v1=>transport_delivery
        request_type   = 'Delivery transport'
        owner          = 'ADMIN'
        short_text     = 'Delivery of the flight fixtures'
        status         = 'Modifiable'
        source_system  = 'DEV'
        target_system  = 'PRD'
        attributes     = 'Delivery transport; delivery route DEV-PRD'
        documentation  = 'Delivery transports ship objects to a customer system.' ) ).
  ENDMETHOD.

  METHOD zif_gg_transport_service_v1~get_number_category.
    CASE iv_transport_type.
      WHEN zif_gg_system_types_v1=>transport_client.
        rv_category = 'KO'.
      WHEN zif_gg_system_types_v1=>transport_delivery.
        rv_category = 'KD'.
      WHEN zif_gg_system_types_v1=>transport_standard
          OR zif_gg_system_types_v1=>transport_piece.
        rv_category = 'K9'.
      WHEN OTHERS.
        CLEAR rv_category.
    ENDCASE.
  ENDMETHOD.

  METHOD type_label.
    CASE iv_transport_type.
      WHEN zif_gg_system_types_v1=>transport_standard.
        rv_label = 'standard requests'.
      WHEN zif_gg_system_types_v1=>transport_piece.
        rv_label = 'piece lists'.
      WHEN zif_gg_system_types_v1=>transport_client.
        rv_label = 'client transports'.
      WHEN zif_gg_system_types_v1=>transport_delivery.
        rv_label = 'delivery transports'.
      WHEN OTHERS.
        rv_label = 'individual display'.
    ENDCASE.
  ENDMETHOD.

  METHOD check_number.
    DATA lv_text TYPE c LENGTH 10.
    DATA lv_category TYPE string.

    IF iv_request_id IS INITIAL.
      rv_error = 'Enter a transport request number.'.
      RETURN.
    ENDIF.
    IF strlen( iv_request_id ) <> 10.
      rv_error = |Request { iv_request_id } is not a ten-character transport request number.|.
      RETURN.
    ENDIF.
    lv_text = iv_request_id.
    IF lv_text(3) CN 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' OR lv_text+5(5) CN '0123456789'.
      rv_error = |Request { iv_request_id } does not follow the <SID><category><number> convention.|.
      RETURN.
    ENDIF.
    lv_category = zif_gg_transport_service_v1~get_number_category( iv_transport_type ).
    IF lv_category IS INITIAL.
      IF lv_text+3(2) <> 'K9' AND lv_text+3(2) <> 'KO' AND lv_text+3(2) <> 'KD'.
        rv_error = |Request { iv_request_id } does not follow any known transport-number convention.|.
      ENDIF.
      RETURN.
    ENDIF.
    IF lv_text+3(2) <> lv_category.
      rv_error = |Request { iv_request_id } does not follow the <SID>{ lv_category }nnnnn convention for { type_label( iv_transport_type ) }.|.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_transport_service_v1~resolve.
    DATA lv_request_id TYPE string.

    lv_request_id = normalized( iv_request_id ).
    rs_request-error = check_number( iv_transport_type = iv_transport_type
                                     iv_request_id     = lv_request_id ).
    IF rs_request-error IS NOT INITIAL.
      RETURN.
    ENDIF.
    rs_request = zif_gg_transport_service_v1~get_request( lv_request_id ).
    IF rs_request-error IS NOT INITIAL.
      RETURN.
    ENDIF.
    IF iv_transport_type IS NOT INITIAL
        AND iv_transport_type <> zif_gg_system_types_v1=>transport_individual
        AND iv_transport_type <> rs_request-transport_type.
      rs_request-error = |Request { lv_request_id } is a { rs_request-request_type } and cannot be displayed on the { type_label( iv_transport_type ) } tab.|.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_transport_service_v1~get_request.
    DATA lv_request_id TYPE string.
    DATA lt_catalog TYPE zif_gg_system_types_v1=>ty_transport_requests.

    lv_request_id = normalized( iv_request_id ).
    lt_catalog = catalog( ).
    READ TABLE lt_catalog INTO rs_request WITH KEY request_id = lv_request_id.
    IF sy-subrc <> 0.
      CLEAR rs_request.
      rs_request-error = 'Request is unknown or not authorized for display.'.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_transport_service_v1~get_tasks.
    DATA lv_request_id TYPE string.

    lv_request_id = normalized( iv_request_id ).
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

    lv_request_id = normalized( iv_request_id ).
    CASE lv_request_id.
      WHEN 'DEVK900001'.
        rt_objects = VALUE #(
          ( request_id  = 'DEVK900001'
            object_id   = 'DEVK900002-1'
            object_type = 'TABL'
            object_name = 'ZSFLIGHT'
            description = 'Flight schedule fixture' ) ).
      WHEN 'DEVK900010'.
        rt_objects = VALUE #(
          ( request_id  = 'DEVK900010'
            object_id   = 'DEVK900010-1'
            object_type = 'VIEW'
            object_name = 'ZSFLIGHT_V'
            description = 'Flight schedule view' ) ).
      WHEN OTHERS.
        CLEAR rt_objects.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_transport_service_v1~get_logs.
    DATA lv_request_id TYPE string.

    lv_request_id = normalized( iv_request_id ).
    IF lv_request_id = 'DEVK900001'.
      rt_logs = VALUE #(
        ( request_id = 'DEVK900001' sequence = 1 severity = 'INFO'
          text = 'Request metadata loaded from the server transport catalog.' )
        ( request_id = 'DEVK900001' sequence = 2 severity = 'INFO'
          text = 'No release or export operation has been performed.' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_transport_service_v1~get_request_ids.
    LOOP AT catalog( ) INTO DATA(ls_request).
      IF iv_transport_type IS NOT INITIAL
          AND iv_transport_type <> zif_gg_system_types_v1=>transport_individual
          AND iv_transport_type <> ls_request-transport_type.
        CONTINUE.
      ENDIF.
      APPEND ls_request-request_id TO rt_request_ids.
    ENDLOOP.
  ENDMETHOD.

  METHOD normalized.
    rv_text = iv_text.
    SHIFT rv_text LEFT DELETING LEADING space.
    TRANSLATE rv_text TO UPPER CASE.
  ENDMETHOD.

ENDCLASS.
