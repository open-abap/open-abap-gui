CLASS cl_salv_events_tree DEFINITION PUBLIC.
  PUBLIC SECTION.

    EVENTS link_click
      EXPORTING
        VALUE(columnname) TYPE lvc_fname
        VALUE(node_key)   TYPE salv_de_node_key.

    EVENTS double_click
      EXPORTING
        VALUE(columnname) TYPE lvc_fname
        VALUE(node_key)   TYPE salv_de_node_key.

    EVENTS added_function
      EXPORTING
        VALUE(e_salv_function) TYPE salv_de_function.

ENDCLASS.

CLASS cl_salv_events_tree IMPLEMENTATION.
ENDCLASS.
