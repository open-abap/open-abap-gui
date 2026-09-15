CLASS cl_tree_model DEFINITION PUBLIC.
  PUBLIC SECTION.

    CONSTANTS node_sel_mode_single TYPE i VALUE 0.
    CONSTANTS node_sel_mode_multiple TYPE i VALUE 1.

    CONSTANTS relat_first_child TYPE i VALUE 0.
    CONSTANTS relat_last_child TYPE i VALUE 1.
    CONSTANTS relat_prev_sibling TYPE i VALUE 2.
    CONSTANTS relat_next_sibling TYPE i VALUE 3.
    CONSTANTS relat_first_sibling TYPE i VALUE 4.
    CONSTANTS relat_last_sibling TYPE i VALUE 5.

    CONSTANTS eventid_def_context_menu_req TYPE i VALUE 1.
    CONSTANTS eventid_node_context_menu_req TYPE i VALUE 2.
    CONSTANTS eventid_node_double_click TYPE i VALUE 3.
    CONSTANTS eventid_node_keypress TYPE i VALUE 4.
    CONSTANTS eventid_selection_changed TYPE i VALUE 5.

    CONSTANTS style_inherited TYPE i VALUE 0.
    CONSTANTS style_default TYPE i VALUE 1.
    CONSTANTS style_intensified TYPE i VALUE 2.
    CONSTANTS style_inactive TYPE i VALUE 3.
    CONSTANTS style_intensifd_critical TYPE i VALUE 4.
    CONSTANTS style_emphasized_negative TYPE i VALUE 5.
    CONSTANTS style_emphasized_positive TYPE i VALUE 6.
    CONSTANTS style_emphasized TYPE i VALUE 7.

    CONSTANTS scroll_up_line TYPE i VALUE 1.
    CONSTANTS scroll_down_line TYPE i VALUE 2.
    CONSTANTS scroll_up_page TYPE i VALUE 3.
    CONSTANTS scroll_down_page TYPE i VALUE 4.
    CONSTANTS scroll_home TYPE i VALUE 5.
    CONSTANTS scroll_end TYPE i VALUE 6.

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

    METHODS expand_node
      IMPORTING
        node_key       TYPE tm_nodekey
        expand_subtree TYPE abap_bool OPTIONAL
        level_count    TYPE i OPTIONAL
        expand_parents TYPE abap_bool OPTIONAL
      EXCEPTIONS
        node_not_found
        failed
        cntl_system_error.

    METHODS collapse_node
      IMPORTING
        node_key TYPE tm_nodekey
      EXCEPTIONS
        node_not_found
        failed
        cntl_system_error.

    METHODS get_expanded_nodes
      EXPORTING
        node_key_table TYPE STANDARD TABLE.

    METHODS node_get_parent
      IMPORTING
        node_key        TYPE tm_nodekey
      EXPORTING
        parent_node_key TYPE tm_nodekey
      EXCEPTIONS
        node_not_found.

    METHODS delete_all_nodes.

    METHODS delete_node
      IMPORTING
        node_key TYPE tm_nodekey
      EXCEPTIONS
        node_not_found.

    METHODS update_view.

  PROTECTED SECTION.
    METHODS get_state_summary
      RETURNING
        VALUE(rv_summary) TYPE string.

    TYPES: BEGIN OF ty_model_node,
             node_key   TYPE string,
             parent_key TYPE string,
             text       TYPE string,
             expanded   TYPE abap_bool,
             selected   TYPE abap_bool,
             hidden     TYPE abap_bool,
           END OF ty_model_node.
    TYPES ty_model_nodes TYPE STANDARD TABLE OF ty_model_node WITH DEFAULT KEY.
    DATA mt_model_nodes TYPE ty_model_nodes.
    DATA mv_node_selection_mode TYPE i.
    DATA mv_hide_selection TYPE abap_bool.
    DATA mv_model_kind TYPE string.
    DATA mr_tree_control TYPE REF TO cl_tree_control_base.

    METHODS store_node
      IMPORTING
        is_node TYPE ty_model_node.

ENDCLASS.

CLASS cl_tree_model IMPLEMENTATION.

  METHOD constructor.
    mv_node_selection_mode = node_selection_mode.
    mv_hide_selection = hide_selection.
    mv_model_kind = 'TREE'.
  ENDMETHOD.

  METHOD create_tree_control.
    IF parent IS BOUND.
      mr_tree_control = NEW cl_gui_simple_tree(
        parent              = parent
        node_selection_mode = mv_node_selection_mode
        hide_selection      = mv_hide_selection
        shellstyle          = shellstyle
        lifetime            = lifetime
        name                = name ).
    ENDIF.
  ENDMETHOD.

  METHOD expand_node.
    READ TABLE mt_model_nodes ASSIGNING FIELD-SYMBOL(<node>)
      WITH KEY node_key = node_key.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    <node>-expanded = abap_true.
    IF expand_parents = abap_true.
      DATA(lv_parent) = <node>-parent_key.
      DO 32 TIMES.
        IF lv_parent IS INITIAL.
          EXIT.
        ENDIF.
        READ TABLE mt_model_nodes ASSIGNING FIELD-SYMBOL(<parent>)
          WITH KEY node_key = lv_parent.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.
        <parent>-expanded = abap_true.
        lv_parent = <parent>-parent_key.
      ENDDO.
    ENDIF.
  ENDMETHOD.

  METHOD collapse_node.
    READ TABLE mt_model_nodes ASSIGNING FIELD-SYMBOL(<node>)
      WITH KEY node_key = node_key.
    IF sy-subrc = 0.
      <node>-expanded = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD get_expanded_nodes.
    CLEAR node_key_table.
    LOOP AT mt_model_nodes INTO DATA(ls_node) WHERE expanded = abap_true.
      APPEND ls_node-node_key TO node_key_table.
    ENDLOOP.
  ENDMETHOD.

  METHOD node_get_parent.
    CLEAR parent_node_key.
    READ TABLE mt_model_nodes INTO DATA(ls_node)
      WITH KEY node_key = node_key.
    IF sy-subrc = 0.
      parent_node_key = ls_node-parent_key.
    ENDIF.
  ENDMETHOD.

  METHOD delete_all_nodes.
    CLEAR mt_model_nodes.
  ENDMETHOD.

  METHOD delete_node.
    DATA lt_delete TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    APPEND node_key TO lt_delete.
    DO 32 TIMES.
      LOOP AT mt_model_nodes INTO DATA(ls_child).
        IF line_exists( lt_delete[ table_line = ls_child-parent_key ] )
            AND NOT line_exists( lt_delete[ table_line = ls_child-node_key ] ).
          APPEND ls_child-node_key TO lt_delete.
        ENDIF.
      ENDLOOP.
    ENDDO.
    LOOP AT lt_delete INTO DATA(lv_delete_key).
      DELETE mt_model_nodes WHERE node_key = lv_delete_key.
    ENDLOOP.
  ENDMETHOD.

  METHOD update_view.
    RETURN.
  ENDMETHOD.

  METHOD get_state_summary.
    DATA(lv_expanded) = 0.
    DATA(lv_selected) = 0.
    LOOP AT mt_model_nodes INTO DATA(ls_node).
      lv_expanded = lv_expanded + COND i( WHEN ls_node-expanded = abap_true THEN 1 ELSE 0 ).
      lv_selected = lv_selected + COND i( WHEN ls_node-selected = abap_true THEN 1 ELSE 0 ).
    ENDLOOP.
    rv_summary = |model={ mv_model_kind };nodes={ lines( mt_model_nodes ) };expanded={ lv_expanded };selected={ lv_selected }|.
  ENDMETHOD.

  METHOD store_node.
    DELETE mt_model_nodes WHERE node_key = is_node-node_key.
    APPEND is_node TO mt_model_nodes.
  ENDMETHOD.

ENDCLASS.
