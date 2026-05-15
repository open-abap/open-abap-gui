CLASS cl_gui_container DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    CLASS-DATA screen0 TYPE REF TO cl_gui_container.
    CLASS-DATA default_screen TYPE REF TO cl_gui_container.
    CONSTANTS visible_true TYPE c LENGTH 1 VALUE '1'.
    CONSTANTS visible_false TYPE c LENGTH 1 VALUE '0'.

    METHODS link
      IMPORTING
        repid     TYPE syrepid OPTIONAL
        dynnr     TYPE sy-dynnr OPTIONAL
        container TYPE c OPTIONAL
        parent    TYPE REF TO cl_gui_container OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error
        lifetime_dynpro_dynpro_link.
ENDCLASS.

CLASS cl_gui_container IMPLEMENTATION.
  METHOD link.
    RETURN. " todo, implement method
  ENDMETHOD.
ENDCLASS.