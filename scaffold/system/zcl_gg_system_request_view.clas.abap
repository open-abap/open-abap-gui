CLASS zcl_gg_system_request_view DEFINITION PUBLIC FINAL CREATE PUBLIC.

* The transport request editor shared by SE09 and SE01. It owns the request
* to task hierarchy and the Properties, Objects, Documentation and Logs views,
* so the Transport Organizer and its extended view cannot drift apart. Every
* value comes from the transport service; the caller passes a request id it
* has already resolved.

  PUBLIC SECTION.
    CONSTANTS screen_overview TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0200'.
    CONSTANTS screen_properties TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0210'.
    CONSTANTS screen_objects TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0220'.
    CONSTANTS screen_documentation TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0230'.
    CONSTANTS screen_logs TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0240'.

    TYPES ty_screens TYPE STANDARD TABLE OF zif_gg_dynpro_types_v1=>ty_screen_number
      WITH DEFAULT KEY.

    "! Screen numbers owned by the editor, in flow-logic order.
    CLASS-METHODS screens
      RETURNING
        VALUE(rt_screens) TYPE ty_screens.

    CLASS-METHODS build_screens
      IMPORTING
        io_builder TYPE REF TO zif_gg_dynpro_builder_v1.

    "! Screen a view command opens, or initial when the command is not one of
    "! the editor views.
    CLASS-METHODS view_screen
      IMPORTING
        iv_ucomm         TYPE zif_gg_dynpro_types_v1=>ty_ucomm
      RETURNING
        VALUE(rv_screen) TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

    CLASS-METHODS fill
      IMPORTING
        is_request TYPE zif_gg_system_types_v1=>ty_transport_request
      CHANGING
        ct_values  TYPE zif_gg_dynpro_types_v1=>ty_values.

    "! Disable the actions no display-only deployment can perform.
    CLASS-METHODS disable_mutation
      CHANGING
        ct_states TYPE zif_gg_dynpro_types_v1=>ty_states.

  PRIVATE SECTION.
    CLASS-METHODS put_value
      IMPORTING
        iv_name   TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_value  TYPE string
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    CLASS-METHODS put_cell
      IMPORTING
        iv_container TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_name      TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_row       TYPE i
        iv_value     TYPE string
      CHANGING
        ct_values    TYPE zif_gg_dynpro_types_v1=>ty_values.
    CLASS-METHODS disable
      IMPORTING
        iv_name   TYPE zif_gg_dynpro_types_v1=>ty_name
      CHANGING
        ct_states TYPE zif_gg_dynpro_types_v1=>ty_states.

ENDCLASS.

CLASS zcl_gg_system_request_view IMPLEMENTATION.

  METHOD screens.
    rt_screens = VALUE #(
      ( screen_overview )
      ( screen_properties )
      ( screen_objects )
      ( screen_documentation )
      ( screen_logs ) ).
  ENDMETHOD.

  METHOD view_screen.
    CASE iv_ucomm.
      WHEN 'PROPERTIES'.
        rv_screen = screen_properties.
      WHEN 'OBJECTS'.
        rv_screen = screen_objects.
      WHEN 'DOCUMENTATION'.
        rv_screen = screen_documentation.
      WHEN 'LOGS'.
        rv_screen = screen_logs.
      WHEN OTHERS.
        CLEAR rv_screen.
    ENDCASE.
  ENDMETHOD.

  METHOD build_screens.
    io_builder->begin_screen( VALUE #( number = screen_overview title = 'Transport Request Overview' height = 360 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_REQ_ID' position = VALUE #( row = 12 column = 18 width = 115 ) ) text = 'Request' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_REQ_ID' position = VALUE #( row = 8 column = 140 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_REQ_TYPE' position = VALUE #( row = 46 column = 18 width = 115 ) ) text = 'Type' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_REQ_TYPE' position = VALUE #( row = 42 column = 140 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_REQ_OWNER' position = VALUE #( row = 80 column = 18 width = 115 ) ) text = 'Owner' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_REQ_OWNER' position = VALUE #( row = 76 column = 140 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_REQ_TEXT' position = VALUE #( row = 114 column = 18 width = 115 ) ) text = 'Short text' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_REQ_TEXT' position = VALUE #( row = 110 column = 140 width = 380 ) ) data_type = VALUE #( typ = 'C' length = 60 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_REQ_STATUS' position = VALUE #( row = 148 column = 18 width = 115 ) ) text = 'Status' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_REQ_STATUS' position = VALUE #( row = 144 column = 140 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_TASKS' position = VALUE #( row = 182 column = 18 width = 540 height = 80 ) ) visible_rows = 2 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_false ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_TASKS' name = 'TASK_ID' title = 'Task' data_type = VALUE #( typ = 'C' length = 12 ) width = 130 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_TASKS' name = 'TASK_OWNER' title = 'Owner' data_type = VALUE #( typ = 'C' length = 20 ) width = 150 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_TASKS' name = 'TASK_STATUS' title = 'Status' data_type = VALUE #( typ = 'C' length = 20 ) width = 150 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_TASKS' name = 'TASK_TEXT' title = 'Short text' data_type = VALUE #( typ = 'C' length = 60 ) width = 240 ) ).
    io_builder->end_table_control( ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_PROPERTIES' position = VALUE #( row = 278 column = 18 width = 100 ) ) text = 'Properties' ucomm = 'PROPERTIES' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_OBJECTS' position = VALUE #( row = 278 column = 128 width = 100 ) ) text = 'Objects' ucomm = 'OBJECTS' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_DOCUMENTATION' position = VALUE #( row = 278 column = 238 width = 125 ) ) text = 'Documentation' ucomm = 'DOCUMENTATION' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_LOGS' position = VALUE #( row = 278 column = 373 width = 80 ) ) text = 'Logs' ucomm = 'LOGS' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_RELEASE' position = VALUE #( row = 316 column = 18 width = 100 ) ) text = 'Release' ucomm = 'RELEASE' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_EXPORT' position = VALUE #( row = 316 column = 128 width = 100 ) ) text = 'Export' ucomm = 'EXPORT' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CREATE_OVERVIEW' position = VALUE #( row = 316 column = 238 width = 100 ) ) text = 'Create' ucomm = 'CREATE' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_properties title = 'Transport Request Properties' height = 300 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TRANSPORT_TYPE' position = VALUE #( row = 20 column = 18 width = 120 ) ) text = 'Transport type' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_TRANSPORT_TYPE' position = VALUE #( row = 16 column = 150 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_SOURCE' position = VALUE #( row = 56 column = 18 width = 120 ) ) text = 'Source system' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_SOURCE' position = VALUE #( row = 52 column = 150 width = 150 ) ) data_type = VALUE #( typ = 'C' length = 10 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TARGET' position = VALUE #( row = 92 column = 18 width = 120 ) ) text = 'Target system' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_TARGET' position = VALUE #( row = 88 column = 150 width = 150 ) ) data_type = VALUE #( typ = 'C' length = 10 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ROUTE' position = VALUE #( row = 128 column = 18 width = 120 ) ) text = 'Route' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ROUTE' position = VALUE #( row = 124 column = 150 width = 360 ) ) data_type = VALUE #( typ = 'C' length = 50 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ATTRIBUTES' position = VALUE #( row = 164 column = 18 width = 120 ) ) text = 'Attributes' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ATTRIBUTES' position = VALUE #( row = 160 column = 150 width = 360 ) ) data_type = VALUE #( typ = 'C' length = 60 ) ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_objects title = 'Transport Objects' height = 260 ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_OBJECTS' position = VALUE #( row = 18 column = 18 width = 540 height = 100 ) ) visible_rows = 3 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_false ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_OBJECTS' name = 'OBJECT_TYPE' title = 'Type' data_type = VALUE #( typ = 'C' length = 8 ) width = 100 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_OBJECTS' name = 'OBJECT_NAME' title = 'Name' data_type = VALUE #( typ = 'C' length = 30 ) width = 170 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_OBJECTS' name = 'OBJECT_TEXT' title = 'Description' data_type = VALUE #( typ = 'C' length = 60 ) width = 250 ) ).
    io_builder->end_table_control( ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_documentation title = 'Transport Documentation' height = 260 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DOCUMENTATION' position = VALUE #( row = 20 column = 18 width = 520 ) ) text = 'Request documentation' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DOCUMENTATION' position = VALUE #( row = 56 column = 18 width = 520 height = 100 ) ) data_type = VALUE #( typ = 'C' length = 255 ) ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_logs title = 'Transport Logs' height = 280 ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_LOGS' position = VALUE #( row = 18 column = 18 width = 540 height = 140 ) ) visible_rows = 4 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_true ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_LOGS' name = 'LOG_SEVERITY' title = 'Severity' data_type = VALUE #( typ = 'C' length = 8 ) width = 100 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_LOGS' name = 'LOG_TEXT' title = 'Message' data_type = VALUE #( typ = 'C' length = 120 ) width = 400 ) ).
    io_builder->end_table_control( ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD fill.
    DATA(lo_service) = NEW zcl_gg_system_transport( ).
    DATA lv_row TYPE i.
    DATA lv_route TYPE string.

    put_value( EXPORTING iv_name = 'O_REQ_ID'
                         iv_value = is_request-request_id CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_REQ_TYPE'
                         iv_value = is_request-request_type CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_REQ_OWNER'
                         iv_value = is_request-owner CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_REQ_TEXT'
                         iv_value = is_request-short_text CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_REQ_STATUS'
                         iv_value = is_request-status CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_TRANSPORT_TYPE'
                         iv_value = is_request-transport_type CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_SOURCE'
                         iv_value = is_request-source_system CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_TARGET'
                         iv_value = is_request-target_system CHANGING ct_values = ct_values ).
    IF is_request-target_system IS INITIAL.
      lv_route = |{ is_request-source_system } (no transport route)|.
    ELSE.
      lv_route = |{ is_request-source_system } -> { is_request-target_system }|.
    ENDIF.
    put_value( EXPORTING iv_name = 'O_ROUTE'
                         iv_value = lv_route CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_ATTRIBUTES'
                         iv_value = is_request-attributes CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_DOCUMENTATION'
                         iv_value = is_request-documentation CHANGING ct_values = ct_values ).
    LOOP AT lo_service->zif_gg_transport_service_v1~get_tasks( is_request-request_id ) INTO DATA(ls_task).
      lv_row = sy-tabix.
      put_cell( EXPORTING iv_container = 'TC_TASKS'
                          iv_name = 'TASK_ID'
                          iv_row = lv_row
                          iv_value = ls_task-task_id CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_TASKS'
                          iv_name = 'TASK_OWNER'
                          iv_row = lv_row
                          iv_value = ls_task-owner CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_TASKS'
                          iv_name = 'TASK_STATUS'
                          iv_row = lv_row
                          iv_value = ls_task-status CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_TASKS'
                          iv_name = 'TASK_TEXT'
                          iv_row = lv_row
                          iv_value = ls_task-short_text CHANGING ct_values = ct_values ).
    ENDLOOP.
    LOOP AT lo_service->zif_gg_transport_service_v1~get_objects( is_request-request_id ) INTO DATA(ls_object).
      lv_row = sy-tabix.
      put_cell( EXPORTING iv_container = 'TC_OBJECTS'
                          iv_name = 'OBJECT_TYPE'
                          iv_row = lv_row
                          iv_value = ls_object-object_type CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_OBJECTS'
                          iv_name = 'OBJECT_NAME'
                          iv_row = lv_row
                          iv_value = ls_object-object_name CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_OBJECTS'
                          iv_name = 'OBJECT_TEXT'
                          iv_row = lv_row
                          iv_value = ls_object-description CHANGING ct_values = ct_values ).
    ENDLOOP.
    LOOP AT lo_service->zif_gg_transport_service_v1~get_logs( is_request-request_id ) INTO DATA(ls_log).
      lv_row = sy-tabix.
      put_cell( EXPORTING iv_container = 'TC_LOGS'
                          iv_name = 'LOG_SEVERITY'
                          iv_row = lv_row
                          iv_value = ls_log-severity CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_LOGS'
                          iv_name = 'LOG_TEXT'
                          iv_row = lv_row
                          iv_value = ls_log-text CHANGING ct_values = ct_values ).
    ENDLOOP.
  ENDMETHOD.

  METHOD disable_mutation.
    disable( EXPORTING iv_name   = 'PB_RELEASE'
             CHANGING  ct_states = ct_states ).
    disable( EXPORTING iv_name   = 'PB_EXPORT'
             CHANGING  ct_states = ct_states ).
    disable( EXPORTING iv_name   = 'PB_CREATE_OVERVIEW'
             CHANGING  ct_states = ct_states ).
  ENDMETHOD.

  METHOD disable.
    FIELD-SYMBOLS <ls_state> TYPE zif_gg_dynpro_types_v1=>ty_state.

    READ TABLE ct_states ASSIGNING <ls_state>
      WITH KEY container = `` name = iv_name row = 0.
    IF sy-subrc = 0.
      <ls_state>-enabled = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD put_value.
    FIELD-SYMBOLS <ls_value> TYPE zif_gg_dynpro_types_v1=>ty_value.

    READ TABLE ct_values ASSIGNING <ls_value>
      WITH KEY container = `` name = iv_name row = 0.
    IF sy-subrc <> 0.
      INSERT VALUE #( name = iv_name value = iv_value ) INTO TABLE ct_values.
    ELSE.
      <ls_value>-value = iv_value.
    ENDIF.
  ENDMETHOD.

  METHOD put_cell.
    FIELD-SYMBOLS <ls_value> TYPE zif_gg_dynpro_types_v1=>ty_value.

    READ TABLE ct_values ASSIGNING <ls_value>
      WITH KEY container = iv_container name = iv_name row = iv_row.
    IF sy-subrc <> 0.
      INSERT VALUE #( container = iv_container name = iv_name row = iv_row value = iv_value ) INTO TABLE ct_values.
    ELSE.
      <ls_value>-value = iv_value.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
