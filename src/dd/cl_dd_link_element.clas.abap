CLASS cl_dd_link_element DEFINITION PUBLIC INHERITING FROM cl_dd_element
  FRIENDS cl_dd_area.
  PUBLIC SECTION.
    METHODS constructor.
    METHODS frontend_event RETURNING VALUE(result) TYPE string.
    METHODS raise_clicked.

    EVENTS clicked
      EXPORTING
        VALUE(sender) TYPE REF TO cl_dd_link_element.

  PRIVATE SECTION.
    DATA mo_bridge TYPE REF TO lcl_link_bridge.
    DATA url TYPE sdydo_text_element.
    DATA text TYPE sdydo_text_element.
    DATA tooltip TYPE string.

ENDCLASS.

CLASS cl_dd_link_element IMPLEMENTATION.
  METHOD constructor.
    mo_bridge = NEW lcl_link_bridge( me ).
  ENDMETHOD.

  METHOD frontend_event.
    result = mo_bridge->get_event( ).
  ENDMETHOD.

  METHOD raise_clicked.
    RAISE EVENT clicked EXPORTING sender = me.
  ENDMETHOD.
ENDCLASS.
