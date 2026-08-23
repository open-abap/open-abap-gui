CLASS cl_gui_docking_container DEFINITION PUBLIC INHERITING FROM cl_gui_container.
  PUBLIC SECTION.

    CONSTANTS dock_at_left TYPE i VALUE 1.
    CONSTANTS dock_at_top TYPE i VALUE 2.
    CONSTANTS dock_at_bottom TYPE i VALUE 4.
    CONSTANTS dock_at_right TYPE i VALUE 8.

    METHODS constructor
      IMPORTING
        parent                  TYPE REF TO cl_gui_container OPTIONAL
        repid                   TYPE sy-repid OPTIONAL
        dynnr                   TYPE sy-dynnr OPTIONAL
        side                    TYPE i DEFAULT dock_at_left
        extension               TYPE i DEFAULT 50
        style                   TYPE i OPTIONAL
        lifetime                TYPE i OPTIONAL
        caption                 TYPE clike OPTIONAL
        metric                  TYPE i DEFAULT 0
        ratio                   TYPE i OPTIONAL
        name                    TYPE string OPTIONAL
        no_autodef_progid_dynnr TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error
        create_error
        lifetime_error
        lifetime_dynpro_dynpro_link.

    METHODS dock_at
      IMPORTING
        side TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_extension
      IMPORTING
        extension TYPE i
      EXCEPTIONS
        cntl_error.

    METHODS float
      IMPORTING
        do_float TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

ENDCLASS.

CLASS cl_gui_docking_container IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD dock_at.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_extension.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD float.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
