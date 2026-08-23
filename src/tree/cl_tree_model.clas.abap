CLASS cl_tree_model DEFINITION PUBLIC.
  PUBLIC SECTION.

    CONSTANTS node_sel_mode_single TYPE i VALUE 0.
    CONSTANTS node_sel_mode_multiple TYPE i VALUE 1.

    METHODS constructor
      IMPORTING
        node_selection_mode TYPE i OPTIONAL
        hide_selection      TYPE abap_bool OPTIONAL.

    METHODS create_tree_control
      IMPORTING
        parent     TYPE REF TO cl_gui_container OPTIONAL
        shellstyle TYPE i OPTIONAL
        lifetime   TYPE i OPTIONAL
        name       TYPE string OPTIONAL
      EXCEPTIONS
        lifetime_error
        cntl_system_error
        create_error
        failed
        illegal_node_selection_mode.

    METHODS destroy_tree_control.

    METHODS expand_node
      IMPORTING
        node_key       TYPE tv_nodekey
        expand_subtree TYPE abap_bool OPTIONAL
        level_count    TYPE i OPTIONAL
        expand_parents TYPE abap_bool OPTIONAL
      EXCEPTIONS
        node_not_found
        failed
        cntl_system_error.

    METHODS collapse_node
      IMPORTING
        node_key TYPE tv_nodekey
      EXCEPTIONS
        node_not_found
        failed
        cntl_system_error.

ENDCLASS.

CLASS cl_tree_model IMPLEMENTATION.

  METHOD constructor.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD create_tree_control.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD destroy_tree_control.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD expand_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD collapse_node.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
