CLASS cl_gui_chart_engine DEFINITION PUBLIC INHERITING FROM cl_gui_control.
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

    METHODS set_data
      IMPORTING
        data  TYPE string OPTIONAL
        xdata TYPE xstring OPTIONAL
        size  TYPE i OPTIONAL.

    METHODS render
      EXCEPTIONS
        cntl_error.

ENDCLASS.

CLASS cl_gui_chart_engine IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_data.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD render.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
