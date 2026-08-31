CLASS cl_tree_control_base DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    CONSTANTS eventid_expand_no_children TYPE i VALUE 18.
    CONSTANTS eventid_node_context_menu_req TYPE i VALUE 36.
    CONSTANTS eventid_selection_changed TYPE i VALUE 21.
    CONSTANTS eventid_node_double_click TYPE i VALUE 25.
    CONSTANTS eventid_node_keypress TYPE i VALUE 40.
    CONSTANTS eventid_def_context_menu_req TYPE i VALUE 42.

    CONSTANTS style_inherited TYPE i VALUE 0.
    CONSTANTS style_default TYPE i VALUE 1.
    CONSTANTS style_intensified TYPE i VALUE 2.
    CONSTANTS style_inactive TYPE i VALUE 3.
    CONSTANTS style_intensifd_critical TYPE i VALUE 4.
    CONSTANTS style_emphasized_negative TYPE i VALUE 5.
    CONSTANTS style_emphasized_positive TYPE i VALUE 6.
    CONSTANTS style_emphasized TYPE i VALUE 7.
    CONSTANTS style_emphasized_a TYPE i VALUE 8.
    CONSTANTS style_emphasized_b TYPE i VALUE 9.
    CONSTANTS style_emphasized_c TYPE i VALUE 10.

    CONSTANTS node_sel_mode_single TYPE i VALUE 0.
    CONSTANTS node_sel_mode_multiple TYPE i VALUE 1.

    CONSTANTS relat_first_sibling TYPE i VALUE 1.
    CONSTANTS relat_last_sibling TYPE i VALUE 2.
    CONSTANTS relat_next_sibling TYPE i VALUE 3.
    CONSTANTS relat_first_child TYPE i VALUE 4.
    CONSTANTS relat_prev_sibling TYPE i VALUE 5.
    CONSTANTS relat_last_child TYPE i VALUE 6.

    CONSTANTS key_f1 TYPE i VALUE 1.
    CONSTANTS key_enter TYPE i VALUE 5.

    TYPES: BEGIN OF ty_html_node,
             node_key   TYPE string,
             parent_key TYPE string,
             text       TYPE string,
             expanded   TYPE abap_bool,
             selected   TYPE abap_bool,
             hidden     TYPE abap_bool,
           END OF ty_html_node.
    TYPES ty_html_nodes TYPE STANDARD TABLE OF ty_html_node WITH DEFAULT KEY.

    METHODS add_key_stroke
      IMPORTING
        key TYPE i
      EXCEPTIONS
        illegal_key
        cntl_system_error
        failed.

    METHODS select_nodes
      IMPORTING
        node_key_table TYPE treev_nks
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_node_key_table
        dp_error
        multiple_node_selection_only.

    METHODS unselect_nodes
      IMPORTING
        node_key_table TYPE treev_nks
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_node_key_table
        dp_error
        multiple_node_selection_only.

    METHODS set_ctx_menu_select_event_appl
      IMPORTING
        appl_event TYPE abap_bool.

    EVENTS on_drop
      EXPORTING
      VALUE(node_key)         TYPE tv_nodekey
      VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

    EVENTS selection_changed
      EXPORTING
      VALUE(node_key) TYPE tv_nodekey.

    EVENTS node_context_menu_select
      EXPORTING
      VALUE(node_key) TYPE tv_nodekey
      VALUE(fcode)    TYPE sy-ucomm.

    EVENTS node_keypress
      EXPORTING
      VALUE(node_key) TYPE tv_nodekey
      VALUE(key)      TYPE i.

    METHODS set_top_node
      IMPORTING
        node_key TYPE tv_nodekey
      EXCEPTIONS
        failed
        node_not_found
        cntl_system_error.

    EVENTS on_drop_get_flavor
      EXPORTING
      VALUE(node_key)         TYPE tv_nodekey
      VALUE(flavors)          TYPE cndd_flavors
      VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

    EVENTS expand_no_children
      EXPORTING
        VALUE(node_key) TYPE tv_nodekey.

    METHODS set_selected_node
      IMPORTING
        node_key TYPE tv_nodekey
      EXCEPTIONS
        failed
        single_node_selection_only
        node_not_found
        cntl_system_error.

    METHODS get_selected_nodes
      CHANGING
        node_key_table TYPE treev_nks
      EXCEPTIONS
        cntl_system_error
        dp_error
        failed
        multiple_node_selection_only.

    METHODS ensure_visible
      IMPORTING
        node_key TYPE tv_nodekey
      EXCEPTIONS
        failed
        node_not_found
        cntl_system_error.

    EVENTS node_context_menu_request
      EXPORTING
        VALUE(node_key) TYPE tv_nodekey
        VALUE(menu)     TYPE REF TO cl_ctmenu.

    EVENTS node_double_click
      EXPORTING
        VALUE(node_key) TYPE tv_nodekey.

    METHODS collapse_subtree
      IMPORTING
        node_key TYPE tv_nodekey.

    METHODS expand_nodes
      IMPORTING
        node_key_table TYPE treev_nks.

    METHODS expand_root_nodes
      IMPORTING
        level_count    TYPE i OPTIONAL
        expand_subtree TYPE abap_bool OPTIONAL
      EXCEPTIONS
        failed
        illegal_level_count
        cntl_system_error.

    METHODS collapse_all_nodes
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS get_selected_node
      EXPORTING
        node_key TYPE tv_nodekey
      EXCEPTIONS
        failed
        single_node_selection_only
        cntl_system_error.

    METHODS get_expanded_nodes
      IMPORTING
        no_hidden_nodes TYPE abap_bool OPTIONAL
      CHANGING
        node_key_table  TYPE treev_nks
      EXCEPTIONS
        cntl_system_error
        dp_error
        failed.

    METHODS delete_nodes
      IMPORTING
        node_key_table TYPE treev_nks
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_node_key_table
        dp_error.

    METHODS move_node
      IMPORTING
        node_key  TYPE tv_nodekey
        relatkey  TYPE tv_nodekey
        relatship TYPE i
      EXCEPTIONS
        failed
        cntl_system_error
        node_not_found
        relative_node_not_found
        illegal_relationship
        dp_error.

    METHODS collapse_nodes
      IMPORTING
        node_key_table TYPE treev_nks
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_node_key_table
        dp_error.

    METHODS delete_all_nodes
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS delete_node
      IMPORTING
        node_key TYPE clike
      EXCEPTIONS
        failed
        node_not_found
        cntl_system_error.

    METHODS expand_node
      IMPORTING
        node_key       TYPE clike
        level_count    TYPE i OPTIONAL
        expand_subtree TYPE abap_bool OPTIONAL
      EXCEPTIONS
        failed
        illegal_level_count
        cntl_system_error
        node_not_found
        cannot_expand_leaf.

    METHODS get_top_node
      EXPORTING
        node_key TYPE tv_nodekey
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS node_set_hidden
      IMPORTING
        node_key TYPE clike
        hidden   TYPE abap_bool
      EXCEPTIONS
        failed
        node_not_found
        cntl_system_error.

    METHODS node_set_n_image
      IMPORTING
        node_key TYPE clike
        n_image  TYPE tv_image
      EXCEPTIONS
        failed
        node_not_found
        cntl_system_error.

    METHODS unselect_all
      EXCEPTIONS
        failed
        cntl_system_error.

  PROTECTED SECTION.
    DATA mt_html_nodes TYPE ty_html_nodes.
    DATA mv_html_top_node TYPE string.

    METHODS add_html_node
      IMPORTING
        node_key   TYPE string
        parent_key TYPE string OPTIONAL
        text       TYPE string OPTIONAL.

    METHODS set_html_node_state
      IMPORTING
        node_key TYPE string
        expanded TYPE abap_bool OPTIONAL
        selected TYPE abap_bool OPTIONAL.

    METHODS clear_html_nodes.

    METHODS refresh_tree_html.

    METHODS tree_html
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.

CLASS cl_tree_control_base IMPLEMENTATION.

  METHOD add_key_stroke.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_ctx_menu_select_event_appl.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD unselect_nodes.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      IF line_exists( node_key_table[ table_line = ls_node-node_key ] ).
        ls_node-selected = abap_false.
        MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
      ENDIF.
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD set_top_node.
    mv_html_top_node = CONV string( node_key ).
  ENDMETHOD.

  METHOD set_selected_node.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      ls_node-selected = xsdbool( ls_node-node_key = CONV string( node_key ) ).
      MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD select_nodes.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      ls_node-selected = xsdbool( line_exists( node_key_table[ table_line = ls_node-node_key ] ) ).
      MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD get_selected_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD ensure_visible.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD collapse_nodes.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      IF line_exists( node_key_table[ table_line = ls_node-node_key ] ).
        ls_node-expanded = abap_false.
        MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
      ENDIF.
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD delete_nodes.
    LOOP AT node_key_table INTO DATA(lv_node_key).
      DELETE mt_html_nodes WHERE node_key = CONV string( lv_node_key ).
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD move_node.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_expanded_nodes.
    LOOP AT mt_html_nodes INTO DATA(ls_node) WHERE expanded = abap_true.
      IF no_hidden_nodes = abap_false OR ls_node-hidden = abap_false.
        APPEND CONV tv_nodekey( ls_node-node_key ) TO node_key_table.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_selected_node.
    READ TABLE mt_html_nodes INTO DATA(ls_node) WITH KEY selected = abap_true.
    IF sy-subrc = 0.
      node_key = CONV tv_nodekey( ls_node-node_key ).
    ENDIF.
  ENDMETHOD.

  METHOD collapse_all_nodes.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      ls_node-expanded = abap_false.
      MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD expand_root_nodes.
    LOOP AT mt_html_nodes INTO DATA(ls_node) WHERE parent_key IS INITIAL.
      ls_node-expanded = abap_true.
      MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD expand_nodes.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      IF line_exists( node_key_table[ table_line = ls_node-node_key ] ).
        ls_node-expanded = abap_true.
        MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
      ENDIF.
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD collapse_subtree.
    set_html_node_state( node_key = CONV string( node_key )
                         expanded = abap_false ).
  ENDMETHOD.

  METHOD delete_all_nodes.
    clear_html_nodes( ).
  ENDMETHOD.

  METHOD delete_node.
    DELETE mt_html_nodes WHERE node_key = CONV string( node_key ).
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD expand_node.
    set_html_node_state( node_key = CONV string( node_key )
                         expanded = abap_true ).
  ENDMETHOD.

  METHOD get_top_node.
    node_key = CONV tv_nodekey( mv_html_top_node ).
  ENDMETHOD.

  METHOD node_set_hidden.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = CONV string( node_key ).
    IF sy-subrc = 0.
      ls_node-hidden = hidden.
      MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
      refresh_tree_html( ).
    ENDIF.
  ENDMETHOD.

  METHOD node_set_n_image.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD unselect_all.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      ls_node-selected = abap_false.
      MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD add_html_node.
    READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
      WITH KEY node_key = node_key.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    APPEND VALUE #( node_key   = node_key
                    parent_key = parent_key
                    text       = text
                    expanded   = abap_true ) TO mt_html_nodes.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD set_html_node_state.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = node_key.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF expanded IS SUPPLIED.
      ls_node-expanded = expanded.
    ENDIF.
    IF selected IS SUPPLIED.
      ls_node-selected = selected.
    ENDIF.
    MODIFY mt_html_nodes FROM ls_node INDEX sy-tabix.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD clear_html_nodes.
    CLEAR mt_html_nodes.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD refresh_tree_html.
    cl_gui_control=>set_html(
      control = me
      html    = tree_html( ) ).
  ENDMETHOD.

  METHOD tree_html.
    DATA lv_depth TYPE i.
    DATA lv_parent TYPE string.
    result = |<ul role="tree" aria-label="Tree">|.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      lv_depth = 1.
      lv_parent = ls_node-parent_key.
      DO 32 TIMES.
        IF lv_parent IS INITIAL.
          EXIT.
        ENDIF.
        READ TABLE mt_html_nodes INTO DATA(ls_parent)
          WITH KEY node_key = lv_parent.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.
        lv_depth = lv_depth + 1.
        lv_parent = ls_parent-parent_key.
      ENDDO.
      DATA(lv_selected) = COND string( WHEN ls_node-selected = abap_true THEN ' aria-current="true"' ELSE '' ).
      DATA(lv_expanded) = COND string( WHEN ls_node-expanded = abap_true THEN 'true' ELSE 'false' ).
      DATA(lv_hidden) = COND string( WHEN ls_node-hidden = abap_true THEN ' hidden' ELSE '' ).
      result = result && |<li role="treeitem" aria-level="{ lv_depth }" aria-expanded="{ lv_expanded }" data-node-key="{ escape_html( ls_node-node_key ) }" data-parent-key="{ escape_html( ls_node-parent_key ) }"{ lv_selected }{ lv_hidden }>{ escape_html( ls_node-text ) }</li>|.
    ENDLOOP.
    result = result && |</ul>|.
  ENDMETHOD.

ENDCLASS.
