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

ENDCLASS.

CLASS cl_gui_selector IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    zcl_gg_gui_runtime=>initialize(
      control = me
      parent  = parent
      kind    = 'SELECTOR' ).
  ENDMETHOD.

ENDCLASS.
