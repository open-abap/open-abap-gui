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
        new_code TYPE clike.

    CLASS-METHODS dispatch
      EXPORTING
        return_code TYPE i.
ENDCLASS.

CLASS cl_gui_cfw IMPLEMENTATION.
  METHOD dispatch.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD compute_pixel_from_metric.
    val = 1.
  ENDMETHOD.

  METHOD flush.
    RETURN.
  ENDMETHOD.

  METHOD set_new_ok_code.
    ASSERT 1 = 'not implemented'.
  ENDMETHOD.
ENDCLASS.