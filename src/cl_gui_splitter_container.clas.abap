CLASS cl_gui_splitter_container DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS free.

    METHODS set_column_width
      IMPORTING
        id    TYPE i
        width TYPE i
      EXPORTING
        result TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_border
      IMPORTING
        border TYPE abap_bool
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS get_container
      IMPORTING
        row TYPE i
        column TYPE i
      RETURNING
        VALUE(container) TYPE REF TO cl_gui_container.
ENDCLASS.

CLASS cl_gui_splitter_container IMPLEMENTATION.

  METHOD free.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_container.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_column_width.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_border.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.