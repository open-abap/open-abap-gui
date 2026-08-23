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

    METHODS set_title
      IMPORTING
        title TYPE clike
      EXCEPTIONS
        cntl_error.

    METHODS set_data
      IMPORTING
        data TYPE STANDARD TABLE
      EXCEPTIONS
        cntl_error.

    METHODS display
      EXCEPTIONS
        cntl_error.

ENDCLASS.

CLASS cl_gui_barchart IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_title.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_data.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD display.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
