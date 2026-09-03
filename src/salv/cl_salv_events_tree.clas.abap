CLASS cl_salv_events_tree DEFINITION PUBLIC INHERITING FROM cl_salv_events.
  PUBLIC SECTION.

    INTERFACES if_salv_events_tree.

    EVENTS link_click
      EXPORTING
        VALUE(columnname) TYPE lvc_fname
        VALUE(node_key)   TYPE salv_de_node_key.

    EVENTS double_click
      EXPORTING
        VALUE(columnname) TYPE lvc_fname
        VALUE(node_key)   TYPE salv_de_node_key.

ENDCLASS.

CLASS cl_salv_events_tree IMPLEMENTATION.
ENDCLASS.
