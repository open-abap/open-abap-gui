CLASS cl_gui_toolbar DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS free.

    METHODS add_button
      IMPORTING
        fcode       TYPE string
        icon        TYPE c
        is_disabled TYPE abap_bool OPTIONAL
        butn_type   TYPE i
        text        TYPE string OPTIONAL
        quickinfo   TYPE string OPTIONAL
        is_checked  TYPE c OPTIONAL
      EXCEPTIONS
        cntl_error
        cntb_btype_error
        cntb_error_fcode.
ENDCLASS.

CLASS cl_gui_toolbar IMPLEMENTATION.

  METHOD free.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD add_button.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.