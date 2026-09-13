CLASS cl_item_tree_control DEFINITION PUBLIC INHERITING FROM cl_tree_control_base.
  PUBLIC SECTION.
    CONSTANTS align_left   TYPE i VALUE 0.
    CONSTANTS align_center TYPE i VALUE 1.
    CONSTANTS align_right  TYPE i VALUE 2.

    CONSTANTS item_class_text     TYPE i VALUE 2.
    CONSTANTS item_class_checkbox TYPE i VALUE 3.
    CONSTANTS item_class_button   TYPE i VALUE 4.
    CONSTANTS item_class_link     TYPE i VALUE 5.

    CONSTANTS item_font_default TYPE i VALUE 0.
    CONSTANTS item_font_fixed   TYPE i VALUE 1.
    CONSTANTS item_font_prop    TYPE i VALUE 2.

    CONSTANTS eventid_button_click TYPE i VALUE 29.
    CONSTANTS eventid_checkbox_change TYPE i VALUE 33.
    CONSTANTS eventid_header_click TYPE i VALUE 28.
    CONSTANTS eventid_header_context_men_req TYPE i VALUE 41.
    CONSTANTS eventid_item_context_menu_req TYPE i VALUE 26.
    CONSTANTS eventid_item_double_click TYPE i VALUE 22.
    CONSTANTS eventid_item_keypress TYPE i VALUE 39.
    CONSTANTS eventid_link_click TYPE i VALUE 35.

    EVENTS button_click
      EXPORTING
        VALUE(node_key)  TYPE tv_nodekey
        VALUE(item_name) TYPE tv_itmname.

    EVENTS link_click
      EXPORTING
        VALUE(node_key)  TYPE tv_nodekey
        VALUE(item_name) TYPE tv_itmname.

    EVENTS item_context_menu_request
      EXPORTING
        VALUE(node_key)  TYPE tv_nodekey
        VALUE(item_name) TYPE tv_itmname
        VALUE(menu)      TYPE REF TO cl_ctmenu.

    EVENTS on_drag
      EXPORTING
      VALUE(node_key)         TYPE tv_nodekey
      VALUE(item_name)        TYPE tv_itmname
      VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

    EVENTS item_keypress
      EXPORTING
      VALUE(node_key)  TYPE tv_nodekey
      VALUE(item_name) TYPE tv_itmname
      VALUE(key)       TYPE i.

    EVENTS on_drag_multiple
      EXPORTING
      VALUE(node_key_table)   TYPE treev_nks
      VALUE(item_name)        TYPE tv_itmname
      VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

    EVENTS on_drop_complete
      EXPORTING
      VALUE(node_key)         TYPE tv_nodekey
      VALUE(item_name)        TYPE tv_itmname
      VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

    EVENTS on_drop_complete_multiple
      EXPORTING
      VALUE(node_key_table)   TYPE treev_nks
      VALUE(item_name)        TYPE tv_itmname
      VALUE(drag_drop_object) TYPE REF TO cl_dragdropobject.

    EVENTS header_click
      EXPORTING
      VALUE(header_name) TYPE tv_hdrname.

    EVENTS item_context_menu_select
      EXPORTING
      VALUE(node_key)  TYPE tv_nodekey
      VALUE(item_name) TYPE tv_itmname
      VALUE(fcode)     TYPE sy-ucomm.

    EVENTS item_double_click
      EXPORTING
        VALUE(node_key)  TYPE tv_nodekey
        VALUE(item_name) TYPE tv_itmname.

    METHODS add_nodes_and_items
      IMPORTING
        node_table                TYPE STANDARD TABLE OPTIONAL
        item_table                TYPE STANDARD TABLE
        item_table_structure_name TYPE clike
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_tables
        dp_error
        table_structure_name_not_found.

    METHODS update_nodes_and_items
      IMPORTING
        node_table                TYPE any OPTIONAL
        item_table                TYPE STANDARD TABLE OPTIONAL
        item_table_structure_name TYPE any
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_tables
        dp_error
        table_structure_name_not_found.

    METHODS delete_all_items_of_nodes
      IMPORTING
        node_key_table TYPE treev_nks
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_node_key_table
        dp_error.

    METHODS delete_items
      IMPORTING
        item_key_table TYPE any
      EXCEPTIONS
        failed
        cntl_system_error
        error_in_item_key_table
        dp_error.

    METHODS item_set_text
      IMPORTING
        node_key  TYPE clike
        item_name TYPE clike
        text      TYPE clike
      EXCEPTIONS
        failed
        node_not_found
        item_not_found
        cntl_system_error.

    METHODS item_set_t_image
      IMPORTING
        node_key  TYPE tv_nodekey
        item_name TYPE tv_itmname
        t_image   TYPE tv_image
      EXCEPTIONS
        failed
        node_not_found
        item_not_found
        cntl_system_error.

    METHODS item_set_chosen
      IMPORTING
        node_key  TYPE tv_nodekey
        item_name TYPE tv_itmname
        chosen    TYPE abap_bool
      EXCEPTIONS
        failed
        node_not_found
        item_not_found
        cntl_system_error
        chosen_not_supported.

    METHODS item_set_editable
      IMPORTING
        node_key  TYPE tv_nodekey
        item_name TYPE tv_itmname
        editable  TYPE abap_bool
      EXCEPTIONS
        failed
        node_not_found
        item_not_found
        cntl_system_error
        no_item_selection
        editable_not_supported.

    METHODS get_selected_item
      EXPORTING
        node_key  TYPE tv_nodekey
        item_name TYPE tv_itmname
      EXCEPTIONS
        failed
        cntl_system_error
        no_item_selection.

    METHODS select_item
      IMPORTING
        node_key  TYPE tv_nodekey
        item_name TYPE tv_itmname
      EXCEPTIONS
        failed
        cntl_system_error
        key_or_item_name_not_found
        no_item_selection.

    EVENTS checkbox_change
      EXPORTING
        VALUE(node_key)  TYPE tv_nodekey
        VALUE(item_name) TYPE tv_itmname
        VALUE(checked)   TYPE abap_bool.

  PROTECTED SECTION.
    TYPES: BEGIN OF ty_item_state,
             node_key  TYPE string,
             item_name TYPE string,
             text      TYPE string,
             chosen    TYPE abap_bool,
             editable  TYPE abap_bool,
             image     TYPE string,
           END OF ty_item_state.
    TYPES ty_item_states TYPE STANDARD TABLE OF ty_item_state WITH DEFAULT KEY.
    DATA mt_item_states TYPE ty_item_states.
    DATA mv_selected_item_node TYPE string.
    DATA mv_selected_item_name TYPE string.
ENDCLASS.

CLASS cl_item_tree_control IMPLEMENTATION.
  METHOD select_item.
    READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
      WITH KEY node_key = node_key.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    mv_selected_item_node = node_key.
    mv_selected_item_name = item_name.
    set_selected_node( node_key = node_key ).
  ENDMETHOD.

  METHOD add_nodes_and_items.
    cl_gui_control=>set_payload(
      control = me
      payload = |nodes={ lines( node_table ) }; items={ lines( item_table ) }; structure={ item_table_structure_name }| ).
  ENDMETHOD.

  METHOD update_nodes_and_items.
    cl_gui_control=>set_payload(
      control = me
      payload = |nodes={ lines( node_table ) }; items={ lines( item_table ) }; structure={ item_table_structure_name }; updated=true| ).
  ENDMETHOD.

  METHOD delete_all_items_of_nodes.
    LOOP AT node_key_table INTO DATA(lv_node_key).
      DELETE mt_item_states WHERE node_key = lv_node_key.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_items.
    CLEAR mt_item_states.
  ENDMETHOD.

  METHOD get_selected_item.
    node_key = mv_selected_item_node.
    item_name = mv_selected_item_name.
  ENDMETHOD.

  METHOD item_set_editable.
    READ TABLE mt_item_states ASSIGNING FIELD-SYMBOL(<item>)
      WITH KEY node_key = node_key item_name = item_name.
    IF sy-subrc = 0.
      <item>-editable = editable.
    ELSE.
      APPEND VALUE #( node_key = node_key item_name = item_name editable = editable )
        TO mt_item_states.
    ENDIF.
    cl_gui_control=>set_payload( control = me
                                 payload = |item={ node_key }/{ item_name }; editable={ editable }| ).
  ENDMETHOD.

  METHOD item_set_chosen.
    READ TABLE mt_item_states ASSIGNING FIELD-SYMBOL(<item>)
      WITH KEY node_key = node_key item_name = item_name.
    IF sy-subrc = 0.
      <item>-chosen = chosen.
    ELSE.
      APPEND VALUE #( node_key = node_key item_name = item_name chosen = chosen )
        TO mt_item_states.
    ENDIF.
    RAISE EVENT checkbox_change
      EXPORTING
        node_key  = node_key
        item_name = item_name
        checked   = chosen.
  ENDMETHOD.

  METHOD item_set_text.
    READ TABLE mt_item_states ASSIGNING FIELD-SYMBOL(<item>)
      WITH KEY node_key = node_key item_name = item_name.
    IF sy-subrc = 0.
      <item>-text = text.
    ELSE.
      APPEND VALUE #( node_key = node_key item_name = item_name text = text )
        TO mt_item_states.
    ENDIF.
    cl_gui_control=>set_payload( control = me
                                 payload = |item={ node_key }/{ item_name }; text={ text }| ).
  ENDMETHOD.

  METHOD item_set_t_image.
    READ TABLE mt_item_states ASSIGNING FIELD-SYMBOL(<item>)
      WITH KEY node_key = node_key item_name = item_name.
    IF sy-subrc = 0.
      <item>-image = t_image.
    ELSE.
      APPEND VALUE #( node_key = node_key item_name = item_name image = t_image )
        TO mt_item_states.
    ENDIF.
    cl_gui_control=>set_payload( control = me
                                 payload = |item={ node_key }/{ item_name }; image={ t_image }| ).
  ENDMETHOD.

ENDCLASS.
