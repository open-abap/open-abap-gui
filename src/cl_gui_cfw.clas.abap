CLASS cl_gui_cfw DEFINITION PUBLIC.
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

    CLASS-METHODS queue_browser_event
      IMPORTING
        event     TYPE string
        node_key  TYPE string OPTIONAL
        fieldname TYPE string OPTIONAL
        value     TYPE string OPTIONAL
        checked   TYPE abap_bool OPTIONAL.

    CLASS-METHODS consume_new_ok_code
      RETURNING
        VALUE(new_code) TYPE string.

  PRIVATE SECTION.
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
ENDCLASS.

CLASS cl_gui_cfw IMPLEMENTATION.
  METHOD update_view.
    mv_update_count = mv_update_count + 1.
    cl_gui_control=>render_html( iv_document = abap_false ).
  ENDMETHOD.

  METHOD dispatch.
    IF mv_browser_event IS NOT INITIAL.
      DATA(lv_handled) = cl_alv_tree_base=>dispatch_browser_event(
        event     = mv_browser_event
        node_key  = mv_browser_node
        fieldname = mv_browser_field
        value     = mv_browser_value
        checked   = mv_browser_checked ).
      CLEAR: mv_browser_event, mv_browser_node, mv_browser_field,
             mv_browser_value, mv_browser_checked.
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
