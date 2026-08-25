CLASS cl_gui_simple_tree DEFINITION PUBLIC INHERITING FROM cl_tree_control_base.
  PUBLIC SECTION.
    CONSTANTS node_sel_mode_single TYPE i VALUE 1.

    CONSTANTS eventid_node_double_click TYPE i VALUE 25.

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

    METHODS delete_all_nodes
      EXCEPTIONS
        failed
        cntl_system_error.

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
ENDCLASS.

CLASS cl_gui_simple_tree IMPLEMENTATION.

  METHOD constructor.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD add_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD delete_all_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD node_set_text.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
