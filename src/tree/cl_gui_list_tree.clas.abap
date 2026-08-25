CLASS cl_gui_list_tree DEFINITION PUBLIC INHERITING FROM cl_item_tree_control.
  PUBLIC SECTION.
    CONSTANTS align_auto TYPE i VALUE 3.

    METHODS constructor
      IMPORTING
        parent              TYPE REF TO cl_gui_container
        node_selection_mode TYPE i OPTIONAL
        hide_selection      TYPE abap_bool OPTIONAL
        item_selection      TYPE abap_bool OPTIONAL
        with_headers        TYPE abap_bool OPTIONAL
        hierarchy_header    TYPE treev_hhdr OPTIONAL
        list_header         TYPE any OPTIONAL
        shellstyle          TYPE any OPTIONAL
        lifetime            TYPE any OPTIONAL
        name                TYPE any OPTIONAL
      EXCEPTIONS
        lifetime_error
        cntl_system_error
        create_error
        failed
        illegal_node_selection_mode.

    METHODS hierarchy_header_set_text
      IMPORTING
        text TYPE tv_heading
      EXCEPTIONS
        failed
        cntl_system_error.
ENDCLASS.

CLASS cl_gui_list_tree IMPLEMENTATION.

  METHOD constructor.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD hierarchy_header_set_text.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
