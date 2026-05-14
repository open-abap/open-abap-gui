CLASS cl_gui_splitter_container DEFINITION PUBLIC INHERITING FROM cl_gui_container.
  PUBLIC SECTION.

    CONSTANTS mode_absolute TYPE i VALUE 0.
    CONSTANTS mode_relative TYPE i VALUE 1.

    CONSTANTS type_movable TYPE i VALUE 0.
    CONSTANTS type_sashvisible TYPE i VALUE 1.

    CONSTANTS true TYPE i VALUE 1.
    CONSTANTS false TYPE i VALUE 0.

    METHODS constructor
      IMPORTING
        parent     TYPE REF TO cl_gui_container OPTIONAL
        rows       TYPE i OPTIONAL
        align      TYPE i OPTIONAL
        link_dynnr TYPE sy-dynnr OPTIONAL
        link_repid TYPE sy-repid OPTIONAL
        columns    TYPE i OPTIONAL.

    METHODS get_row_height
      IMPORTING
        id     TYPE i
      EXPORTING
        result TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_column_mode
      IMPORTING
        mode   TYPE i
      EXPORTING
        result TYPE i.

    METHODS set_row_sash
      IMPORTING
        id     TYPE i
        type   TYPE i
        value  TYPE i
      EXPORTING
        result TYPE i.

    METHODS set_row_height
      IMPORTING
        id     TYPE i
        height TYPE i
      EXPORTING
        result TYPE i.

    METHODS set_column_sash
      IMPORTING
        id     TYPE i
        type   TYPE i
        value  TYPE i
      EXPORTING
        result TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_row_mode
      IMPORTING
        mode   TYPE   i
      EXPORTING
        result TYPE i.

    METHODS set_column_width
      IMPORTING
        id     TYPE i
        width  TYPE i
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
        row              TYPE i
        column           TYPE i
      RETURNING
        VALUE(container) TYPE REF TO cl_gui_container.
ENDCLASS.

CLASS cl_gui_splitter_container IMPLEMENTATION.
  METHOD get_row_height.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_row_sash.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_column_sash.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_row_mode.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_row_height.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD constructor.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_column_mode.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

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