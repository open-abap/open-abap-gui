CLASS cl_gui_container DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    CLASS-DATA screen0 TYPE REF TO cl_gui_container.
    CLASS-DATA default_screen TYPE REF TO cl_gui_container.
    CONSTANTS visible_true TYPE c LENGTH 1 VALUE '1'.
    CONSTANTS visible_false TYPE c LENGTH 1 VALUE '0'.

    TYPES ty_child_ids TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    METHODS add_child
      IMPORTING
        child TYPE REF TO cl_gui_control.

    METHODS get_children
      RETURNING
        VALUE(children) TYPE ty_child_ids.

  PRIVATE SECTION.
    DATA mt_child_ids TYPE ty_child_ids.

    METHODS link
      IMPORTING
        repid     TYPE syrepid OPTIONAL
        dynnr     TYPE sy-dynnr OPTIONAL
        container TYPE c OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error
        lifetime_dynpro_dynpro_link.
ENDCLASS.

CLASS cl_gui_container IMPLEMENTATION.
  METHOD add_child.
    IF child IS BOUND.
      APPEND child->control_id TO mt_child_ids.
    ENDIF.
  ENDMETHOD.

  METHOD get_children.
    children = mt_child_ids.
  ENDMETHOD.

  METHOD link.
    RETURN. " todo, implement method
  ENDMETHOD.
ENDCLASS.
