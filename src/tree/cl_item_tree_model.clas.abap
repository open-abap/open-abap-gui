CLASS cl_item_tree_model DEFINITION PUBLIC INHERITING FROM cl_tree_model.
  PUBLIC SECTION.

    CONSTANTS align_left TYPE i VALUE 0.
    CONSTANTS align_center TYPE i VALUE 1.
    CONSTANTS align_right TYPE i VALUE 2.

    CONSTANTS item_class_text TYPE i VALUE 2.
    CONSTANTS item_class_checkbox TYPE i VALUE 3.
    CONSTANTS item_class_button TYPE i VALUE 4.
    CONSTANTS item_class_link TYPE i VALUE 5.

    CONSTANTS item_font_default TYPE i VALUE 0.
    CONSTANTS item_font_fixed TYPE i VALUE 1.
    CONSTANTS item_font_prop TYPE i VALUE 2.

    CONSTANTS eventid_button_click TYPE i VALUE 100.
    CONSTANTS eventid_checkbox_change TYPE i VALUE 101.
    CONSTANTS eventid_header_click TYPE i VALUE 102.
    CONSTANTS eventid_header_context_men_req TYPE i VALUE 103.
    CONSTANTS eventid_item_context_menu_req TYPE i VALUE 104.
    CONSTANTS eventid_item_double_click TYPE i VALUE 105.
    CONSTANTS eventid_item_keypress TYPE i VALUE 106.
    CONSTANTS eventid_link_click TYPE i VALUE 107.

    EVENTS button_click
      EXPORTING
        VALUE(node_key)  TYPE tm_nodekey
        VALUE(item_name) TYPE tv_itmname.

    EVENTS checkbox_change
      EXPORTING
        VALUE(node_key)  TYPE tm_nodekey
        VALUE(item_name) TYPE tv_itmname
        VALUE(checked)   TYPE abap_bool.

    EVENTS link_click
      EXPORTING
        VALUE(node_key)  TYPE tm_nodekey
        VALUE(item_name) TYPE tv_itmname.

    EVENTS item_double_click
      EXPORTING
        VALUE(node_key)  TYPE tm_nodekey
        VALUE(item_name) TYPE tv_itmname.

    EVENTS item_keypress
      EXPORTING
        VALUE(node_key)  TYPE tm_nodekey
        VALUE(item_name) TYPE tv_itmname
        VALUE(key)       TYPE i.

    METHODS constructor
      IMPORTING
        node_selection_mode TYPE i OPTIONAL
        hide_selection      TYPE abap_bool OPTIONAL
        item_selection      TYPE abap_bool OPTIONAL.

    METHODS set_registered_events
      IMPORTING
        events TYPE cntl_simple_events
      EXCEPTIONS
        illegal_event_combination
        unknown_event.

    METHODS get_registered_events
      EXPORTING
        events TYPE cntl_simple_events.

    METHODS item_set_chosen
      IMPORTING
        node_key  TYPE tm_nodekey
        item_name TYPE tv_itmname
        chosen    TYPE abap_bool
      EXCEPTIONS
        node_not_found
        item_not_found
        chosen_not_supported.

    METHODS item_set_text
      IMPORTING
        node_key  TYPE tm_nodekey
        item_name TYPE tv_itmname
        text      TYPE tm_itemtxt
      EXCEPTIONS
        node_not_found
        item_not_found.

    METHODS item_set_style
      IMPORTING
        node_key  TYPE tm_nodekey
        item_name TYPE tv_itmname
        style     TYPE i
      EXCEPTIONS
        node_not_found
        item_not_found.

  PROTECTED SECTION.
    TYPES: BEGIN OF ty_model_item,
             node_key  TYPE string,
             item_name TYPE string,
             text      TYPE string,
             class     TYPE i,
             chosen    TYPE abap_bool,
             style     TYPE i,
             editable  TYPE abap_bool,
             hidden    TYPE abap_bool,
           END OF ty_model_item.
    TYPES ty_model_items TYPE STANDARD TABLE OF ty_model_item WITH DEFAULT KEY.
    DATA mt_model_items TYPE ty_model_items.
    DATA mt_registered_events TYPE cntl_simple_events.

    METHODS get_node_display_text REDEFINITION.

ENDCLASS.

CLASS cl_item_tree_model IMPLEMENTATION.

  METHOD constructor.
    super->constructor( node_selection_mode = node_selection_mode
                        hide_selection      = hide_selection ).
    mv_node_selection_mode = node_selection_mode.
    mv_hide_selection = hide_selection.
  ENDMETHOD.

  METHOD set_registered_events.
    mt_registered_events = events.
  ENDMETHOD.

  METHOD get_registered_events.
    CLEAR events.
    events = mt_registered_events.
  ENDMETHOD.

  METHOD item_set_chosen.
    READ TABLE mt_model_items ASSIGNING FIELD-SYMBOL(<item>)
      WITH KEY node_key = node_key
               item_name = item_name.
    IF sy-subrc = 0.
      <item>-chosen = chosen.
      update_view( ).
    ENDIF.
  ENDMETHOD.

  METHOD item_set_text.
    READ TABLE mt_model_items ASSIGNING FIELD-SYMBOL(<item>)
      WITH KEY node_key = node_key
               item_name = item_name.
    IF sy-subrc = 0.
      <item>-text = text.
      update_view( ).
    ENDIF.
  ENDMETHOD.

  METHOD item_set_style.
    READ TABLE mt_model_items ASSIGNING FIELD-SYMBOL(<item>)
      WITH KEY node_key = node_key
               item_name = item_name.
    IF sy-subrc = 0.
      <item>-style = style.
      update_view( ).
    ENDIF.
  ENDMETHOD.

  METHOD get_node_display_text.
    READ TABLE mt_model_nodes INTO DATA(ls_node)
      WITH KEY node_key = iv_node_key.
    IF sy-subrc = 0.
      rv_text = ls_node-text.
    ELSE.
      rv_text = iv_node_key.
    ENDIF.

    READ TABLE mt_model_items INTO DATA(ls_hierarchy_item)
      WITH KEY node_key  = iv_node_key
               item_name = 'NODE'.
    IF sy-subrc = 0 AND ls_hierarchy_item-text IS NOT INITIAL.
      rv_text = ls_hierarchy_item-text.
    ENDIF.
    LOOP AT mt_model_items INTO DATA(ls_item)
        WHERE node_key = iv_node_key.
      IF ls_item-item_name <> 'NODE' AND ls_item-text IS NOT INITIAL.
        rv_text = |{ rv_text } { ls_item-text }|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
