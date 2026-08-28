CLASS cl_gui_simple_tree DEFINITION PUBLIC INHERITING FROM cl_tree_control_base.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        parent              TYPE REF TO cl_gui_container
        node_selection_mode TYPE i OPTIONAL
        hide_selection      TYPE abap_bool OPTIONAL
        shellstyle          TYPE any OPTIONAL
        lifetime            TYPE any OPTIONAL
        name                TYPE any OPTIONAL
      EXCEPTIONS
        lifetime_error
        cntl_system_error
        create_error
        failed
        illegal_node_selection_mode.

    METHODS add_nodes
      IMPORTING
        table_structure_name TYPE clike
        node_table           TYPE STANDARD TABLE
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_node_table
        dp_error
        table_structure_name_not_found.

    METHODS node_set_text
      IMPORTING
        node_key TYPE clike
        text     TYPE clike
      EXCEPTIONS
        failed
        node_not_found
        cntl_system_error.

    EVENTS on_drag_multiple
      EXPORTING
        VALUE(node_key_table)   TYPE treev_nks
        VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

    EVENTS on_drop_complete_multiple
      EXPORTING
        VALUE(node_key_table)   TYPE treev_nks
        VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.
ENDCLASS.

CLASS cl_gui_simple_tree IMPLEMENTATION.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'SIMPLE_TREE' ).
    parent->add_child( me ).
  ENDMETHOD.

  METHOD add_nodes.
    clear_html_nodes( ).
    add_html_node(
      node_key = 'TREE-ROOT'
      text = |Tree nodes: { lines( node_table ) }| ).
    cl_gui_control=>set_payload(
      control = me
      payload = |Tree nodes: { lines( node_table ) }| ).
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD node_set_text.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = CONV string( node_key ).
    IF sy-subrc = 0.
      ls_node-text = CONV string( text ).
      MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
      refresh_tree_html( ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
