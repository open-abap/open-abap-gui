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
ENDCLASS.

CLASS cl_gui_cfw IMPLEMENTATION.
  METHOD update_view.
    mv_update_count = mv_update_count + 1.
    cl_gui_control=>render_html( iv_document = abap_false ).
  ENDMETHOD.

  METHOD dispatch.
    IF mv_ok_code IS INITIAL.
      return_code = rc_noevent.
    ELSE.
      return_code = 0.
      CLEAR mv_ok_code.
    ENDIF.
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
    CLEAR: mv_ok_code, mv_update_count, mv_flush_count.
  ENDMETHOD.
ENDCLASS.
