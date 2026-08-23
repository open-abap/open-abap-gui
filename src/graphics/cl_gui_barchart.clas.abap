CLASS cl_gui_barchart DEFINITION PUBLIC INHERITING FROM cl_gui_control.
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

ENDCLASS.

CLASS cl_gui_barchart IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
