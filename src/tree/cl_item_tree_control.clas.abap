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

    METHODS delete_all_nodes REDEFINITION.

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
    TYPES: BEGIN OF ty_html_item,
             node_key   TYPE string,
             item_name  TYPE string,
             text       TYPE string,
             item_class TYPE i,
             chosen     TYPE abap_bool,
             editable   TYPE abap_bool,
             image      TYPE string,
           END OF ty_html_item.
    TYPES ty_html_items TYPE STANDARD TABLE OF ty_html_item WITH DEFAULT KEY.
    TYPES: BEGIN OF ty_item_state,
             node_key  TYPE string,
             item_name TYPE string,
             text      TYPE string,
             chosen    TYPE abap_bool,
             editable  TYPE abap_bool,
             image     TYPE string,
           END OF ty_item_state.
    TYPES ty_item_states TYPE STANDARD TABLE OF ty_item_state WITH DEFAULT KEY.
    DATA mt_html_items TYPE ty_html_items.
    DATA mt_item_states TYPE ty_item_states.
    DATA mv_selected_item_node TYPE string.
    DATA mv_selected_item_name TYPE string.

    METHODS refresh_item_html.
ENDCLASS.

CLASS cl_item_tree_control IMPLEMENTATION.

  METHOD refresh_item_html.
    refresh_tree_html( ).
  ENDMETHOD.

  METHOD delete_all_nodes.
    CLEAR mt_html_items.
    super->delete_all_nodes( ).
  ENDMETHOD.

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
    LOOP AT node_table ASSIGNING FIELD-SYMBOL(<node_row>).
      ASSIGN COMPONENT 'NODE_KEY' OF STRUCTURE <node_row> TO FIELD-SYMBOL(<node_key>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      DATA(lv_node_key) = CONV string( <node_key> ).
      READ TABLE mt_html_nodes TRANSPORTING NO FIELDS
        WITH KEY node_key = lv_node_key.
      IF sy-subrc <> 0.
        DATA(lv_parent_key) = ``.
        ASSIGN COMPONENT 'RELATKEY' OF STRUCTURE <node_row> TO FIELD-SYMBOL(<parent_key>).
        IF sy-subrc = 0.
          lv_parent_key = CONV string( <parent_key> ).
        ENDIF.
        APPEND VALUE #( node_key   = lv_node_key
                        parent_key = lv_parent_key
                        expanded   = abap_true ) TO mt_html_nodes.
      ENDIF.
    ENDLOOP.

    LOOP AT item_table ASSIGNING FIELD-SYMBOL(<item_row>).
      ASSIGN COMPONENT 'NODE_KEY' OF STRUCTURE <item_row> TO FIELD-SYMBOL(<item_node_key>).
      ASSIGN COMPONENT 'ITEM_NAME' OF STRUCTURE <item_row> TO FIELD-SYMBOL(<item_name>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      DATA(lv_item_node_key) = CONV string( <item_node_key> ).
      DATA(lv_item_name) = CONV string( <item_name> ).
      DELETE mt_html_items WHERE node_key = lv_item_node_key AND item_name = lv_item_name.
      DATA(ls_html_item) = VALUE ty_html_item( node_key   = lv_item_node_key
                                               item_name  = lv_item_name
                                               item_class = item_class_text ).
      ASSIGN COMPONENT 'TEXT' OF STRUCTURE <item_row> TO FIELD-SYMBOL(<item_text>).
      IF sy-subrc = 0.
        ls_html_item-text = CONV string( <item_text> ).
      ENDIF.
      ASSIGN COMPONENT 'CLASS' OF STRUCTURE <item_row> TO FIELD-SYMBOL(<item_class>).
      IF sy-subrc = 0.
        ls_html_item-item_class = CONV i( <item_class> ).
      ENDIF.
      ASSIGN COMPONENT 'CHOSEN' OF STRUCTURE <item_row> TO FIELD-SYMBOL(<item_chosen>).
      IF sy-subrc = 0.
        ls_html_item-chosen = CONV abap_bool( <item_chosen> ).
      ENDIF.
      ASSIGN COMPONENT 'EDITABLE' OF STRUCTURE <item_row> TO FIELD-SYMBOL(<item_editable>).
      IF sy-subrc = 0.
        ls_html_item-editable = CONV abap_bool( <item_editable> ).
      ENDIF.
      ASSIGN COMPONENT 'T_IMAGE' OF STRUCTURE <item_row> TO FIELD-SYMBOL(<item_image>).
      IF sy-subrc = 0.
        ls_html_item-image = CONV string( <item_image> ).
      ENDIF.
      APPEND ls_html_item TO mt_html_items.

      IF lv_item_name = 'NODE'.
        READ TABLE mt_html_nodes ASSIGNING FIELD-SYMBOL(<html_node>)
          WITH KEY node_key = lv_item_node_key.
        IF sy-subrc = 0.
          <html_node>-text = ls_html_item-text.
        ENDIF.
      ENDIF.
    ENDLOOP.
    refresh_item_html( ).
    cl_gui_control=>set_payload(
      control = me
      payload = |nodes={ lines( node_table ) }; items={ lines( item_table ) }; structure={ item_table_structure_name }| ).
  ENDMETHOD.

  METHOD update_nodes_and_items.
    DATA lv_node_count TYPE i.

    IF node_table IS SUPPLIED.
      lv_node_count = lines( node_table ).
    ENDIF.
    IF item_table IS SUPPLIED.
      add_nodes_and_items(
        item_table                = item_table
        item_table_structure_name = item_table_structure_name ).
    ELSE.
      refresh_item_html( ).
    ENDIF.
    cl_gui_control=>set_payload(
      control = me
      payload = |nodes={ lv_node_count }; items={ lines( item_table ) }; structure={ item_table_structure_name }; updated=true| ).
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
