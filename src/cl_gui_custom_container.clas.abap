CLASS cl_gui_custom_container DEFINITION PUBLIC INHERITING FROM cl_gui_container.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        container_name          TYPE c
        parent                  TYPE REF TO cl_gui_container OPTIONAL
        repid                   TYPE sy-repid OPTIONAL
        no_autodef_progid_dynnr TYPE abap_bool OPTIONAL
        lifetime                TYPE i OPTIONAL
        dynnr                   TYPE sy-dynnr OPTIONAL.
ENDCLASS.

CLASS cl_gui_custom_container IMPLEMENTATION.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'CUSTOM_CONTAINER' ).
    IF parent IS BOUND.
      parent->add_child( me ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
