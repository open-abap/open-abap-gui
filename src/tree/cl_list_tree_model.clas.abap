CLASS cl_list_tree_model DEFINITION PUBLIC INHERITING FROM cl_item_tree_model.
  PUBLIC SECTION.

    CONSTANTS align_auto TYPE i VALUE 3.

    METHODS constructor
      IMPORTING
        with_headers        TYPE abap_bool
        node_selection_mode TYPE i OPTIONAL
        hide_selection      TYPE abap_bool OPTIONAL
        item_selection      TYPE abap_bool OPTIONAL
        hierarchy_header    TYPE treemhhdr OPTIONAL
        list_header         TYPE treemlhdr OPTIONAL.

    METHODS add_node
      IMPORTING
        node_key          TYPE tm_nodekey
        relative_node_key TYPE tm_nodekey OPTIONAL
        relationship      TYPE i OPTIONAL
        isfolder          TYPE abap_bool OPTIONAL
        hidden            TYPE abap_bool OPTIONAL
        disabled          TYPE abap_bool OPTIONAL
        no_branch         TYPE abap_bool OPTIONAL
        expander          TYPE abap_bool OPTIONAL
        image             TYPE tv_image OPTIONAL
        expanded_image    TYPE tv_image OPTIONAL
        style             TYPE i OPTIONAL
        drag_drop_id      TYPE i OPTIONAL
        items_incomplete  TYPE abap_bool OPTIONAL
        item_table        TYPE treemlitab OPTIONAL
        last_hitem        TYPE tv_itmname OPTIONAL
        user_object       TYPE REF TO object OPTIONAL
      EXCEPTIONS
        node_key_exists
        node_key_empty
        illegal_relationship
        relative_node_not_found
        error_in_item_table.

    METHODS add_nodes
      IMPORTING
        node_table TYPE treemlnota
      EXCEPTIONS
        error_in_node_table
        failed
        cntl_system_error.

    METHODS add_items
      IMPORTING
        item_table TYPE treemlitac
      EXCEPTIONS
        node_not_found
        error_in_item_table
        failed
        cntl_system_error.

    METHODS node_get_item
      IMPORTING
        node_key  TYPE tm_nodekey
        item_name TYPE tv_itmname
      EXPORTING
        item      TYPE treemlitem
      EXCEPTIONS
        node_not_found
        item_not_found.

ENDCLASS.

CLASS cl_list_tree_model IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
  ENDMETHOD.

  METHOD add_node.
    DATA lv_parent TYPE string.
    lv_parent = relative_node_key.
    IF relationship = relat_prev_sibling OR relationship = relat_next_sibling
        OR relationship = relat_first_sibling OR relationship = relat_last_sibling.
      READ TABLE mt_model_nodes INTO DATA(ls_relative)
        WITH KEY node_key = lv_parent.
      IF sy-subrc = 0.
        lv_parent = ls_relative-parent_key.
      ENDIF.
    ENDIF.
    store_node( VALUE #( node_key   = CONV string( node_key )
                         parent_key = lv_parent
                         text       = CONV string( node_key )
                         expanded   = xsdbool( expander = abap_true OR isfolder = abap_true )
                         hidden     = hidden ) ).
    IF item_table IS NOT INITIAL.
      LOOP AT item_table INTO DATA(ls_item).
        DELETE mt_model_items WHERE node_key = node_key
                                AND item_name = ls_item-item_name.
        APPEND VALUE #( node_key  = node_key
                        item_name = ls_item-item_name
                        text      = ls_item-text
                        class     = ls_item-class
                        chosen    = xsdbool( ls_item-chosen IS NOT INITIAL )
                        style     = ls_item-style
                        editable  = xsdbool( ls_item-editable IS NOT INITIAL )
                        hidden    = xsdbool( ls_item-hidden IS NOT INITIAL ) ) TO mt_model_items.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD add_nodes.
    LOOP AT node_table INTO DATA(ls_node).
      add_node(
        node_key          = CONV tm_nodekey( ls_node-node_key )
        relative_node_key = CONV tm_nodekey( ls_node-relatkey )
        relationship      = ls_node-relatship
        isfolder          = ls_node-isfolder
        hidden            = ls_node-hidden
        disabled          = ls_node-disabled
        no_branch         = ls_node-no_branch
        expander          = ls_node-expander
        image             = ls_node-n_image
        expanded_image    = ls_node-exp_image
        style             = ls_node-style
        drag_drop_id      = ls_node-dragdropid
        last_hitem        = ls_node-last_hitem ).
    ENDLOOP.
  ENDMETHOD.

  METHOD add_items.
    LOOP AT item_table INTO DATA(ls_item).
      DELETE mt_model_items WHERE node_key = CONV string( ls_item-node_key )
                              AND item_name = CONV string( ls_item-item_name ).
      APPEND VALUE #( node_key  = CONV string( ls_item-node_key )
                      item_name = CONV string( ls_item-item_name )
                      text      = CONV string( ls_item-text )
                      class     = ls_item-class
                      chosen    = xsdbool( ls_item-chosen IS NOT INITIAL )
                      style     = ls_item-style
                      editable  = xsdbool( ls_item-editable IS NOT INITIAL )
                      hidden    = xsdbool( ls_item-hidden IS NOT INITIAL ) ) TO mt_model_items.
    ENDLOOP.
  ENDMETHOD.

  METHOD node_get_item.
    CLEAR item.
    READ TABLE mt_model_items INTO DATA(ls_item)
      WITH KEY node_key  = node_key
               item_name = item_name.
    IF sy-subrc = 0.
      item-item_name = CONV tv_itmname( ls_item-item_name ).
      item-class = ls_item-class.
      item-chosen = xsdbool( ls_item-chosen = abap_true ).
      item-style = ls_item-style.
      item-editable = xsdbool( ls_item-editable = abap_true ).
      item-hidden = xsdbool( ls_item-hidden = abap_true ).
      item-text = ls_item-text.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
