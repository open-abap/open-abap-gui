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

    METHODS fire_link_click
      IMPORTING
        columnname TYPE lvc_fname
        node_key   TYPE salv_de_node_key.

    METHODS fire_double_click
      IMPORTING
        columnname TYPE lvc_fname
        node_key   TYPE salv_de_node_key.

    METHODS fire_checkbox_change
      IMPORTING
        columnname TYPE lvc_fname
        node_key   TYPE salv_de_node_key
        checked    TYPE abap_bool.

    METHODS fire_keypress
      IMPORTING
        columnname TYPE lvc_fname
        node_key   TYPE salv_de_node_key
        key        TYPE salv_de_constant.

    METHODS fire_expand_empty_folder
      IMPORTING
        node_key TYPE salv_de_node_key.

ENDCLASS.

CLASS cl_salv_events_tree IMPLEMENTATION.

  METHOD fire_link_click.
    RAISE EVENT link_click
      EXPORTING
        columnname = columnname
        node_key   = node_key.
  ENDMETHOD.

  METHOD fire_double_click.
    RAISE EVENT double_click
      EXPORTING
        columnname = columnname
        node_key   = node_key.
  ENDMETHOD.

  METHOD fire_checkbox_change.
    RAISE EVENT checkbox_change
      EXPORTING
        columnname = columnname
        node_key   = node_key
        checked    = checked.
  ENDMETHOD.

  METHOD fire_keypress.
    RAISE EVENT keypress
      EXPORTING
        columnname = columnname
        node_key   = node_key
        key        = key.
  ENDMETHOD.

  METHOD fire_expand_empty_folder.
    RAISE EVENT expand_empty_folder
      EXPORTING
        node_key = node_key.
  ENDMETHOD.

ENDCLASS.
