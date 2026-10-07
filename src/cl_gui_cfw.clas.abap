CLASS cl_gui_cfw DEFINITION PUBLIC FRIENDS zcl_gg_host_dynpro zcl_gg_host_runtime zcl_gg_host.
  PUBLIC SECTION.
    CONSTANTS rc_noevent TYPE i VALUE -1.

    CLASS-METHODS compute_pixel_from_metric
      IMPORTING
        x_or_y     TYPE c
        in         TYPE i
      RETURNING
        VALUE(val) TYPE i.

    CLASS-METHODS flush.

    CLASS-METHODS set_new_ok_code
      IMPORTING
        new_code TYPE clike
      EXPORTING
        rc       TYPE i.

    CLASS-METHODS update_view
      IMPORTING
        called_by_system TYPE abap_bool OPTIONAL
      EXCEPTIONS
        cntl_system_error
        cntl_error.

    CLASS-METHODS dispatch
      EXPORTING
        return_code TYPE i.

  PRIVATE SECTION.
    CLASS-METHODS queue_browser_event
      IMPORTING
        event     TYPE string
        node_key  TYPE string OPTIONAL
        fieldname TYPE string OPTIONAL
        value     TYPE string OPTIONAL
        checked   TYPE abap_bool OPTIONAL.

* The host hands over what the browser posted: EVENT is the value of the
* control submit button that was pressed (<control id>|<event>|<params>), VALUES
* the gg-ctl:* fields of every control.
    CLASS-METHODS receive_frontend
      IMPORTING
        event  TYPE string
        values TYPE cl_gui_control=>ty_fields.

* Before PAI: the controls get their frontend values and a system event goes
* to its handlers. KIND is S after a system event, A when an application event
* waits for DISPATCH in PAI, and initial without an event.
    CLASS-METHODS process_frontend
      RETURNING
        VALUE(kind) TYPE string.

* After PAI: an application event the program did not dispatch is dispatched
* now, at the end of PAI.
    CLASS-METHODS dispatch_pending
      RETURNING
        VALUE(dispatched) TYPE abap_bool.

    CLASS-METHODS consume_new_ok_code
      RETURNING
        VALUE(new_code) TYPE string.

    CLASS-METHODS get_new_ok_code
      RETURNING
        VALUE(new_code) TYPE string.

    CLASS-METHODS get_update_count
      RETURNING
        VALUE(count) TYPE i.

    CLASS-METHODS get_flush_count
      RETURNING
        VALUE(count) TYPE i.

    CLASS-METHODS reset.

    CLASS-DATA mv_ok_code TYPE string.
    CLASS-DATA mv_update_count TYPE i.
    CLASS-DATA mv_flush_count TYPE i.
    CLASS-DATA mv_browser_event TYPE string.
    CLASS-DATA mv_browser_node TYPE string.
    CLASS-DATA mv_browser_field TYPE string.
    CLASS-DATA mv_browser_value TYPE string.
    CLASS-DATA mv_browser_checked TYPE abap_bool.
    CLASS-DATA mv_control_event TYPE string.
    CLASS-DATA mt_control_values TYPE cl_gui_control=>ty_fields.
ENDCLASS.

CLASS cl_gui_cfw IMPLEMENTATION.
  METHOD update_view.
    mv_update_count = mv_update_count + 1.
    cl_gui_control=>render_html( iv_document = abap_false ).
  ENDMETHOD.

  METHOD dispatch.
    IF mv_control_event IS NOT INITIAL.
      return_code = COND #( WHEN dispatch_pending( ) = abap_true THEN 0 ELSE rc_noevent ).
    ELSEIF mv_browser_event IS NOT INITIAL.
      DATA(lv_handled) = cl_alv_tree_base=>dispatch_browser_event(
        event     = mv_browser_event
        node_key  = mv_browser_node
        fieldname = mv_browser_field
        value     = mv_browser_value
        checked   = mv_browser_checked ).
      CLEAR: mv_browser_event, mv_browser_node, mv_browser_field,
             mv_browser_value, mv_browser_checked,
           mv_control_event, mt_control_values.
      return_code = COND #( WHEN lv_handled = abap_true THEN 0 ELSE rc_noevent ).
    ELSEIF mv_ok_code IS INITIAL.
      return_code = rc_noevent.
    ELSE.
      return_code = 0.
      CLEAR mv_ok_code.
    ENDIF.
  ENDMETHOD.

  METHOD queue_browser_event.
    mv_browser_event = event.
    mv_browser_node = node_key.
    mv_browser_field = fieldname.
    mv_browser_value = value.
    mv_browser_checked = checked.
  ENDMETHOD.

  METHOD receive_frontend.
    mv_control_event = event.
    mt_control_values = values.
  ENDMETHOD.

  METHOD process_frontend.
    DATA lt_values TYPE cl_gui_control=>ty_fields.
    DATA lt_parts TYPE string_table.
    DATA lv_prefix TYPE string.

    LOOP AT cl_gui_control=>mt_objects INTO DATA(ls_object).
      IF ls_object-control->mv_alive = abap_false.
        CONTINUE.
      ENDIF.
      lv_prefix = |gg-ctl:{ ls_object-control_id }:|.
      CLEAR lt_values.
      LOOP AT mt_control_values INTO DATA(ls_value).
        IF strlen( ls_value-name ) > strlen( lv_prefix )
            AND substring( val = ls_value-name
                           len = strlen( lv_prefix ) ) = lv_prefix.
          APPEND VALUE #( name  = substring( val = ls_value-name
                                             off = strlen( lv_prefix ) )
                          value = ls_value-value ) TO lt_values.
        ENDIF.
      ENDLOOP.
      IF lt_values IS NOT INITIAL.
        ls_object-control->receive_frontend_values( lt_values ).
      ENDIF.
    ENDLOOP.
    CLEAR mt_control_values.

    IF mv_control_event IS INITIAL.
      RETURN.
    ENDIF.
    SPLIT mv_control_event AT '|' INTO TABLE lt_parts.
    DATA(lo_control) = cl_gui_control=>find_control( VALUE #( lt_parts[ 1 ] OPTIONAL ) ).
    IF lo_control IS NOT BOUND OR lines( lt_parts ) < 2.
      CLEAR mv_control_event.
      RETURN.
    ENDIF.
    IF lo_control->is_application_event( lt_parts[ 2 ] ) = abap_true.
      kind = 'A'.
      RETURN.
    ENDIF.
    kind = 'S'.
    dispatch_pending( ).
  ENDMETHOD.

  METHOD dispatch_pending.
    DATA lt_parts TYPE string_table.

    IF mv_control_event IS INITIAL.
      RETURN.
    ENDIF.
    SPLIT mv_control_event AT '|' INTO TABLE lt_parts.
    CLEAR mv_control_event.
    IF lines( lt_parts ) < 2.
      RETURN.
    ENDIF.
    DATA(lo_control) = cl_gui_control=>find_control( lt_parts[ 1 ] ).
    IF lo_control IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(lv_event) = lt_parts[ 2 ].
    DELETE lt_parts FROM 1 TO 2.
    lo_control->dispatch_frontend_event(
      event  = lv_event
      params = lt_parts ).
    dispatched = abap_true.
  ENDMETHOD.

  METHOD consume_new_ok_code.
    new_code = mv_ok_code.
    CLEAR mv_ok_code.
  ENDMETHOD.


  METHOD compute_pixel_from_metric.
    IF in < 0.
      val = 0.
    ELSE.
      val = in.
    ENDIF.
  ENDMETHOD.

  METHOD flush.
    mv_flush_count = mv_flush_count + 1.
    update_view( ).
  ENDMETHOD.

  METHOD set_new_ok_code.
    mv_ok_code = CONV string( new_code ).
    rc = 0.
  ENDMETHOD.

  METHOD get_new_ok_code.
    new_code = mv_ok_code.
  ENDMETHOD.

  METHOD get_update_count.
    count = mv_update_count.
  ENDMETHOD.

  METHOD get_flush_count.
    count = mv_flush_count.
  ENDMETHOD.

  METHOD reset.
    CLEAR: mv_ok_code, mv_update_count, mv_flush_count,
           mv_browser_event, mv_browser_node, mv_browser_field,
           mv_browser_value, mv_browser_checked.
  ENDMETHOD.
ENDCLASS.
