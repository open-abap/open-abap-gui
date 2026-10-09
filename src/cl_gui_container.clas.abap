CLASS cl_gui_container DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    CLASS-DATA screen0 TYPE REF TO cl_gui_container.
    CLASS-DATA default_screen TYPE REF TO cl_gui_container.
    CONSTANTS visible_true TYPE c LENGTH 1 VALUE '1'.
    CONSTANTS visible_false TYPE c LENGTH 1 VALUE '0'.

    CLASS-METHODS class_constructor.

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
  METHOD class_constructor.
* DEFAULT_SCREEN and SCREEN0 stand for the dynpro itself, so they are bound
* before any program runs. They are never registered as controls: a
* control created on them gets no parent id and renders at the top level of
* the screen, the same place as a control created without a parent.
    default_screen = NEW #( ).
    default_screen->mv_alive = abap_true.
    default_screen->mv_visible = abap_true.
    screen0 = NEW #( ).
    screen0->mv_alive = abap_true.
    screen0->mv_visible = abap_true.
  ENDMETHOD.

  METHOD link.
    cl_gui_control=>set_payload(
      control = me
      payload = |link-repid={ repid }; dynnr={ dynnr }; container={ container }| ).
  ENDMETHOD.
ENDCLASS.
