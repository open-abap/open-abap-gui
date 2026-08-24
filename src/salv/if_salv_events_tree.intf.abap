INTERFACE if_salv_events_tree PUBLIC.

  EVENTS link_click
    EXPORTING
      VALUE(columnname) TYPE lvc_fname
      VALUE(node_key)   TYPE salv_de_node_key.

  EVENTS double_click
    EXPORTING
      VALUE(columnname) TYPE lvc_fname
      VALUE(node_key)   TYPE salv_de_node_key.

  EVENTS checkbox_change
    EXPORTING
      VALUE(columnname) TYPE lvc_fname
      VALUE(node_key)   TYPE salv_de_node_key
      VALUE(checked)    TYPE abap_bool.

  EVENTS keypress
    EXPORTING
      VALUE(columnname) TYPE lvc_fname
      VALUE(node_key)   TYPE salv_de_node_key
      VALUE(key)        TYPE salv_de_constant.

  EVENTS expand_empty_folder
    EXPORTING
      VALUE(node_key) TYPE salv_de_node_key.

ENDINTERFACE.
