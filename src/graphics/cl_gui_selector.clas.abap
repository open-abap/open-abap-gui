CLASS cl_gui_selector DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        parent TYPE REF TO cl_gui_container OPTIONAL
        name   TYPE string OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error
        create_error
        lifetime_error.

    METHODS set_color
      IMPORTING
        color TYPE i
      EXCEPTIONS
        cntl_error.

    METHODS get_color
      EXPORTING
        color TYPE i
      EXCEPTIONS
        cntl_error.

    METHODS display
      EXCEPTIONS
        cntl_error.

ENDCLASS.

CLASS cl_gui_selector IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_color.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_color.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD display.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
