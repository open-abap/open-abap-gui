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

    EVENTS on_drag
      EXPORTING
        VALUE(node_key)         TYPE tv_nodekey
        VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

    EVENTS on_drop_complete
      EXPORTING
        VALUE(node_key)         TYPE tv_nodekey
        VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

    EVENTS on_drag_multiple
      EXPORTING
        VALUE(node_key_table)   TYPE treev_nks
        VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

    EVENTS on_drop_complete_multiple
      EXPORTING
        VALUE(node_key_table)   TYPE treev_nks
        VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

  PROTECTED SECTION.
    METHODS drag REDEFINITION.
    METHODS drop_complete REDEFINITION.
ENDCLASS.

CLASS cl_gui_simple_tree IMPLEMENTATION.

  METHOD constructor.
    zcl_gg_gui_runtime=>initialize(
      control = me
      parent  = parent
      kind    = 'SIMPLE_TREE' ).
  ENDMETHOD.

  METHOD add_nodes.
    FIELD-SYMBOLS <node_row> TYPE any.
    FIELD-SYMBOLS <component> TYPE any.
    DATA lv_node_index TYPE i.

* add_nodes adds to the nodes the tree has; a new node starts collapsed.
    LOOP AT node_table ASSIGNING <node_row>.
      lv_node_index = sy-tabix.
      DATA(lv_node_key) = |NODE-{ lv_node_index }|.
      DATA(lv_parent_key) = ``.
      DATA(lv_text) = ``.

      ASSIGN COMPONENT 'NODE_KEY' OF STRUCTURE <node_row> TO <component>.
      IF sy-subrc = 0 AND <component> IS NOT INITIAL.
        lv_node_key = CONV string( <component> ).
      ENDIF.

      UNASSIGN <component>.
      ASSIGN COMPONENT 'RELATKEY' OF STRUCTURE <node_row> TO <component>.
      IF sy-subrc <> 0.
        UNASSIGN <component>.
        ASSIGN COMPONENT 'PARENT_KEY' OF STRUCTURE <node_row> TO <component>.
      ENDIF.
      IF sy-subrc = 0.
        lv_parent_key = CONV string( <component> ).
      ENDIF.

      UNASSIGN <component>.
      ASSIGN COMPONENT 'TEXT' OF STRUCTURE <node_row> TO <component>.
      IF sy-subrc = 0.
        lv_text = CONV string( <component> ).
      ELSE.
        lv_text = CONV string( <node_row> ).
      ENDIF.
      IF lv_text IS INITIAL.
        lv_text = lv_node_key.
      ENDIF.

      DELETE mt_html_nodes WHERE node_key = lv_node_key.
      APPEND VALUE #( node_key   = lv_node_key
                      parent_key = lv_parent_key
                      text       = lv_text ) TO mt_html_nodes ASSIGNING FIELD-SYMBOL(<ls_html_node>).
      UNASSIGN <component>.
      ASSIGN COMPONENT 'ISFOLDER' OF STRUCTURE <node_row> TO <component>.
      IF sy-subrc = 0.
        <ls_html_node>-folder = xsdbool( <component> IS NOT INITIAL ).
      ENDIF.
      UNASSIGN <component>.
      ASSIGN COMPONENT 'EXPANDER' OF STRUCTURE <node_row> TO <component>.
      IF sy-subrc = 0.
        <ls_html_node>-expander = xsdbool( <component> IS NOT INITIAL ).
      ENDIF.
      UNASSIGN <component>.
      ASSIGN COMPONENT 'DRAGDROPID' OF STRUCTURE <node_row> TO <component>.
      IF sy-subrc = 0.
        <ls_html_node>-dragdropid = <component>.
      ENDIF.
      UNASSIGN <component>.
      ASSIGN COMPONENT 'N_IMAGE' OF STRUCTURE <node_row> TO <component>.
      IF sy-subrc = 0.
        <ls_html_node>-node_image = CONV string( <component> ).
      ENDIF.
      UNASSIGN <component>.
      ASSIGN COMPONENT 'EXP_IMAGE' OF STRUCTURE <node_row> TO <component>.
      IF sy-subrc = 0.
        <ls_html_node>-open_image = CONV string( <component> ).
      ENDIF.
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD drag.
    RAISE EVENT on_drag
      EXPORTING
        node_key         = CONV tv_nodekey( key )
        drag_drop_object = object.
  ENDMETHOD.

  METHOD drop_complete.
    RAISE EVENT on_drop_complete
      EXPORTING
        node_key         = CONV tv_nodekey( key )
        drag_drop_object = object.
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
