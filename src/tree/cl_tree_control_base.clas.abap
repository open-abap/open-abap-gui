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
    TYPES: BEGIN OF ty_html_node_state,
             node_key   TYPE string,
             parent_key TYPE string,
             text       TYPE string,
             expanded   TYPE abap_bool,
             selected   TYPE abap_bool,
             hidden     TYPE abap_bool,
             folder     TYPE abap_bool,
             expander   TYPE abap_bool,
             node_image TYPE string,
             open_image TYPE string,
             dragdropid TYPE i,
           END OF ty_html_node_state.
    TYPES ty_html_node_states TYPE STANDARD TABLE OF ty_html_node_state WITH DEFAULT KEY.

    DATA mt_html_nodes TYPE ty_html_node_states.
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

    "! Nesting level of a node: 1 for a root node, one more per ancestor that
    "! is still present in the node table.
    METHODS node_level
      IMPORTING
        node_key      TYPE string
      RETURNING
        VALUE(result) TYPE i.

    METHODS node_has_children
      IMPORTING
        node_key      TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS tree_html
      RETURNING
        VALUE(result) TYPE string.

    DATA mv_html_header TYPE string.

* The items of a node besides its text; an item tree shows them after the node.
    METHODS node_items_html
      IMPORTING
        node_key      TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS dispatch_frontend_event REDEFINITION.
    METHODS is_application_event REDEFINITION.

  PRIVATE SECTION.
    METHODS node_visible
      IMPORTING
        node_key      TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS event_id
      IMPORTING
        event         TYPE string
      RETURNING
        VALUE(result) TYPE i.
ENDCLASS.

CLASS cl_tree_control_base IMPLEMENTATION.

  METHOD add_key_stroke.
    IF key <> key_f1 AND key <> key_enter.
      RETURN.
    ENDIF.
    READ TABLE mt_html_nodes INTO DATA(ls_node) WITH KEY selected = abap_true.
    IF sy-subrc = 0.
      RAISE EVENT node_keypress
        EXPORTING
          node_key = CONV tv_nodekey( ls_node-node_key )
          key      = key.
    ENDIF.
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
    CLEAR node_key_table.
    LOOP AT mt_html_nodes INTO DATA(ls_node) WHERE selected = abap_true.
      APPEND CONV tv_nodekey( ls_node-node_key ) TO node_key_table.
    ENDLOOP.
  ENDMETHOD.

  METHOD ensure_visible.
    READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
      WITH KEY node_key = CONV string( node_key ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = CONV string( node_key ).
    WHILE ls_node-parent_key IS NOT INITIAL.
      READ TABLE mt_html_nodes INTO DATA(ls_parent)
        WITH KEY node_key = ls_node-parent_key.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      ls_parent-expanded = abap_true.
      MODIFY mt_html_nodes FROM ls_parent INDEX sy-tabix.
      ls_node = ls_parent.
    ENDWHILE.
    refresh_tree_html( ).
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
    DATA lv_node_index TYPE sy-tabix.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = CONV string( node_key ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lv_node_index = sy-tabix.
    IF relatship = relat_first_child OR relatship = relat_last_child.
      ls_node-parent_key = CONV string( relatkey ).
    ELSE.
      READ TABLE mt_html_nodes INTO DATA(ls_relative)
        WITH KEY node_key = CONV string( relatkey ).
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      ls_node-parent_key = ls_relative-parent_key.
    ENDIF.
    MODIFY mt_html_nodes FROM ls_node INDEX lv_node_index.
    refresh_tree_html( ).
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
    DATA(lv_level_count) = COND i( WHEN level_count > 0 THEN level_count ELSE 1 ).
    DATA lv_node_index TYPE sy-tabix.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      lv_node_index = sy-tabix.
      IF node_level( ls_node-node_key ) <= lv_level_count
          AND line_exists( mt_html_nodes[ parent_key = ls_node-node_key ] ).
        ls_node-expanded = abap_true.
      ENDIF.
      MODIFY mt_html_nodes FROM ls_node INDEX lv_node_index.
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
    DATA lt_delete TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    APPEND CONV string( node_key ) TO lt_delete.
    DO 32 TIMES.
      LOOP AT mt_html_nodes INTO DATA(ls_child).
        IF line_exists( lt_delete[ table_line = ls_child-parent_key ] )
            AND NOT line_exists( lt_delete[ table_line = ls_child-node_key ] ).
          APPEND ls_child-node_key TO lt_delete.
        ENDIF.
      ENDLOOP.
    ENDDO.
    LOOP AT lt_delete INTO DATA(lv_delete_key).
      DELETE mt_html_nodes WHERE node_key = lv_delete_key.
    ENDLOOP.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD expand_node.
    READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
      WITH KEY node_key = CONV string( node_key ).
    IF sy-subrc = 0.
      set_html_node_state( node_key = CONV string( node_key )
                           expanded = abap_true ).
    ENDIF.
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
    READ TABLE mt_html_nodes ASSIGNING FIELD-SYMBOL(<node>) WITH KEY node_key = CONV string( node_key ).
    IF sy-subrc = 0.
      <node>-node_image = CONV string( n_image ).
      refresh_tree_html( ).
    ENDIF.
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

  METHOD node_level.
    DATA lv_parent TYPE string.

    result = 1.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = node_key.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lv_parent = ls_node-parent_key.
* A node cannot be its own ancestor, but nothing stops a caller from building a
* cyclic parent chain, so the walk is bounded by the nesting the control shows.
    DO 32 TIMES.
      IF lv_parent IS INITIAL.
        RETURN.
      ENDIF.
      READ TABLE mt_html_nodes INTO DATA(ls_parent)
        WITH KEY node_key = lv_parent.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      result = result + 1.
      lv_parent = ls_parent-parent_key.
    ENDDO.
  ENDMETHOD.

  METHOD node_has_children.
    READ TABLE mt_html_nodes INTO DATA(ls_node)
      WITH KEY node_key = node_key.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    result = xsdbool(
      line_exists( mt_html_nodes[ parent_key = node_key ] )
      OR ls_node-expander = abap_true ).
  ENDMETHOD.

  METHOD node_items_html.
    RETURN.
  ENDMETHOD.

  METHOD node_visible.
    DATA lv_parent TYPE string.

    result = abap_true.
    READ TABLE mt_html_nodes INTO DATA(ls_node) WITH KEY node_key = node_key.
    lv_parent = ls_node-parent_key.
    DO 32 TIMES.
      IF lv_parent IS INITIAL.
        RETURN.
      ENDIF.
      READ TABLE mt_html_nodes INTO DATA(ls_parent) WITH KEY node_key = lv_parent.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      IF ls_parent-expanded = abap_false.
        result = abap_false.
        RETURN.
      ENDIF.
      lv_parent = ls_parent-parent_key.
    ENDDO.
  ENDMETHOD.

  METHOD event_id.
    CASE event.
      WHEN 'DROP'.
        result = -1.
      WHEN 'TOGGLE'.
        result = eventid_expand_no_children.
      WHEN 'SELECT'.
        result = eventid_selection_changed.
      WHEN 'NODE_DOUBLE_CLICK'.
        result = eventid_node_double_click.
    ENDCASE.
  ENDMETHOD.

  METHOD is_application_event.
    IF event = 'DROP'.
      result = abap_true.
      RETURN.
    ENDIF.
    READ TABLE mt_frontend_events INTO DATA(ls_event) WITH KEY eventid = event_id( event ).
    result = xsdbool( sy-subrc = 0 AND ls_event-appl_event = abap_true ).
  ENDMETHOD.

  METHOD dispatch_frontend_event.
    DATA lv_node_key TYPE tv_nodekey.

* Expanding and selecting happen in the frontend on SAP; the program hears of
* them only through the events it registered.
    lv_node_key = VALUE string( params[ 1 ] OPTIONAL ).
    READ TABLE mt_html_nodes INTO DATA(ls_node) WITH KEY node_key = CONV string( lv_node_key ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    DATA(lv_registered) = xsdbool( line_exists( mt_frontend_events[ eventid = event_id( event ) ] ) ).
    CASE event.
      WHEN 'DROP'.
        DATA(lv_source) = VALUE string( params[ 2 ] OPTIONAL ).
        DATA(lv_source_key) = VALUE string( params[ 3 ] OPTIONAL ).
        DATA(lo_drop) = cl_gui_control=>start_drag( source_id = lv_source
                                                    key       = lv_source_key
          flavor                                              = VALUE #( params[ 4 ] OPTIONAL ) ).
        IF lo_drop IS BOUND.
          RAISE EVENT on_drop_get_flavor EXPORTING node_key         = lv_node_key
                                                   drag_drop_object = lo_drop
            flavors                                                 = VALUE cndd_flavors( ( lo_drop->flavor ) ).
          IF lo_drop->state <> -1.
            RAISE EVENT on_drop EXPORTING node_key         = lv_node_key
                                          drag_drop_object = lo_drop.
            cl_gui_control=>end_drag( source_id = lv_source
                                      key       = lv_source_key
                                      object    = lo_drop ).
          ENDIF.
        ENDIF.
      WHEN 'TOGGLE'.
        IF ls_node-expanded = abap_false
            AND NOT line_exists( mt_html_nodes[ parent_key = ls_node-node_key ] )
            AND lv_registered = abap_true.
          RAISE EVENT expand_no_children EXPORTING node_key = lv_node_key.
        ENDIF.
        set_html_node_state( node_key = ls_node-node_key
                             expanded = xsdbool( ls_node-expanded = abap_false ) ).
      WHEN 'SELECT'.
        set_selected_node( lv_node_key ).
        IF lv_registered = abap_true.
          RAISE EVENT selection_changed EXPORTING node_key = lv_node_key.
        ENDIF.
      WHEN 'NODE_DOUBLE_CLICK'.
        set_selected_node( lv_node_key ).
        IF lv_registered = abap_true.
          RAISE EVENT node_double_click EXPORTING node_key = lv_node_key.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD tree_html.
    DATA lv_toggle TYPE string.
    IF mv_html_header IS NOT INITIAL.
      result = |<div class="gg-tree-header">{ escape_html( mv_html_header ) }</div>|.
    ENDIF.


    result = result && |<ul class="gg-tree" role="tree" aria-label="Tree">|.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      IF ls_node-hidden = abap_true OR node_visible( ls_node-node_key ) = abap_false.
        CONTINUE.
      ENDIF.
      DATA(lv_depth) = node_level( ls_node-node_key ).
      DATA(lv_key_params) = VALUE string_table( ( ls_node-node_key ) ).
      IF node_has_children( ls_node-node_key ) = abap_true.
        DATA(lv_toggle_event) = frontend_event_value( event  = 'TOGGLE'
                                                      params = lv_key_params ).
        lv_toggle = |<button type="submit" class="gg-tree-toggle" name="gg_control_event" value="{ lv_toggle_event }" formnovalidate aria-label="{ COND string( WHEN ls_node-expanded = abap_true THEN 'Collapse' ELSE 'Expand' ) } { escape_html( ls_node-text ) }">{ COND string( WHEN ls_node-expanded = abap_true THEN '-' ELSE '+' ) }</button>|.
      ELSE.
        lv_toggle = |<span class="gg-tree-toggle" aria-hidden="true"></span>|.
      ENDIF.
      DATA(lv_select) = frontend_event_value( event  = 'SELECT'
                                              params = lv_key_params ).
      DATA(lv_double_click) = frontend_event_value( event  = 'NODE_DOUBLE_CLICK'
                                                    params = lv_key_params ).
      DATA(lv_state_class) = cl_gui_control=>state_class( iv_selected = ls_node-selected ).
      DATA(lv_selected) = COND string(
        WHEN ls_node-selected = abap_true THEN ' aria-current="true" aria-selected="true"'
        ELSE ' aria-selected="false"' ).
      DATA(lv_expanded) = COND string( WHEN ls_node-expanded = abap_true THEN 'true' ELSE 'false' ).
      DATA(lv_drag) = drag_attributes( handle     = ls_node-dragdropid
                                       control_id = control_id
                                       key        = ls_node-node_key ).
      DATA(lv_drop) = drop_attributes( handle     = ls_node-dragdropid
                                       control_id = control_id
                                       row        = ls_node-node_key ).
      IF lv_drag IS NOT INITIAL.
        REPLACE FIRST OCCURRENCE OF ' tabindex="0"' IN lv_drop WITH ''.
      ENDIF.
      DATA(lv_image) = COND string( WHEN ls_node-expanded = abap_true AND ls_node-open_image IS NOT INITIAL
        THEN ls_node-open_image ELSE ls_node-node_image ).
      DATA(lv_icon) = COND string( WHEN lv_image IS NOT INITIAL THEN zcl_gg_host_icons=>icon( lv_image ) ).
      result = result && |<li class="gg-tree-node { lv_state_class }" role="treeitem" aria-level="{ lv_depth }" aria-expanded="{ lv_expanded }" data-node-key="{ escape_html( ls_node-node_key ) }" data-parent-key="{ escape_html( ls_node-parent_key ) }" style="padding-left:{ ( lv_depth - 1 ) * 18 }px"{ lv_selected }{ lv_drag }{ lv_drop }>| &&
        |{ lv_toggle }{ lv_icon }<span class="gg-tree-label" tabindex="0" data-gg-click-event="{ lv_select }" data-gg-dblclick-event="{ lv_double_click }">{ escape_html( ls_node-text ) }</span>{ node_items_html( ls_node-node_key ) }</li>|.
    ENDLOOP.
    result = result && |</ul>|.
  ENDMETHOD.

ENDCLASS.
