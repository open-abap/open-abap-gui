CLASS zcl_gg_se09 DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_transaction_v1.

  PRIVATE SECTION.
    METHODS put_value
      IMPORTING
        iv_name   TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_value  TYPE string
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS value_of
      IMPORTING
        it_values       TYPE zif_gg_dynpro_types_v1=>ty_values
        iv_name         TYPE zif_gg_dynpro_types_v1=>ty_name
      RETURNING
        VALUE(rv_value) TYPE string.
    METHODS put_cell
      IMPORTING
        iv_container TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_name      TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_row       TYPE i
        iv_value     TYPE string
      CHANGING
        ct_values    TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS build_flow_screen
      IMPORTING
        io_builder TYPE REF TO zif_gg_dynpro_flow_builder_v1
        iv_screen  TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

ENDCLASS.

CLASS zcl_gg_se09 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'SE09' description = 'Transport Organizer' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' title = 'Transport Organizer' height = 310 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_INTRO' position = VALUE #( row = 12 column = 18 width = 540 ) ) text = 'Select requests and tasks owned by the server transport catalog.' ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_OWNER' position = VALUE #( row = 48 column = 18 width = 125 ) ) text = 'Owner' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_OWNER' position = VALUE #( row = 42 column = 155 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 12 ) value_help = abap_true ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_REQUEST' position = VALUE #( row = 84 column = 18 width = 125 ) ) text = 'Request / task' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_REQUEST' position = VALUE #( row = 78 column = 155 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 12 ) value_help = abap_true required = abap_true ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TYPE' position = VALUE #( row = 120 column = 18 width = 125 ) ) text = 'Request type' ) ).
    io_builder->add_listbox( VALUE #( control = VALUE #( name = 'P_TYPE' position = VALUE #( row = 114 column = 155 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 12 ) fixed_values = VALUE #( ( key = 'WORKBENCH' text = 'Workbench' ) ( key = 'CUSTOMIZING' text = 'Customizing' ) ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_STATUS' position = VALUE #( row = 156 column = 18 width = 125 ) ) text = 'Request status' ) ).
    io_builder->add_listbox( VALUE #( control = VALUE #( name = 'P_STATUS' position = VALUE #( row = 150 column = 155 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 12 ) fixed_values = VALUE #( ( key = 'ALL' text = 'All statuses' ) ( key = 'MODIFIABLE' text = 'Modifiable' ) ( key = 'RELEASED' text = 'Released' ) ) ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'P_CAPABILITY' position = VALUE #( row = 192 column = 18 width = 540 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_DISPLAY' position = VALUE #( row = 238 column = 18 width = 96 ) ) text = 'Display' ucomm = 'DISPLAY' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CREATE' position = VALUE #( row = 238 column = 124 width = 96 ) ) text = 'Create' ucomm = 'CREATE' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_EXTENDED' position = VALUE #( row = 238 column = 230 width = 140 ) ) text = 'SE01 Extended View' ucomm = 'SE01' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0200' title = 'Transport Request Overview' height = 360 ) ).
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
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CREATE_OVERVIEW' position = VALUE #( row = 316 column = 128 width = 100 ) ) text = 'Create' ucomm = 'CREATE' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0210' title = 'Transport Request Properties' height = 260 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_SOURCE' position = VALUE #( row = 20 column = 18 width = 120 ) ) text = 'Source system' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_SOURCE' position = VALUE #( row = 16 column = 150 width = 150 ) ) data_type = VALUE #( typ = 'C' length = 10 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TARGET' position = VALUE #( row = 56 column = 18 width = 120 ) ) text = 'Target system' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_TARGET' position = VALUE #( row = 52 column = 150 width = 150 ) ) data_type = VALUE #( typ = 'C' length = 10 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ATTRIBUTES' position = VALUE #( row = 92 column = 18 width = 120 ) ) text = 'Attributes' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ATTRIBUTES' position = VALUE #( row = 88 column = 150 width = 360 ) ) data_type = VALUE #( typ = 'C' length = 60 ) ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0220' title = 'Transport Objects' height = 260 ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_OBJECTS' position = VALUE #( row = 18 column = 18 width = 540 height = 100 ) ) visible_rows = 3 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_false ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_OBJECTS' name = 'OBJECT_TYPE' title = 'Type' data_type = VALUE #( typ = 'C' length = 8 ) width = 100 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_OBJECTS' name = 'OBJECT_NAME' title = 'Name' data_type = VALUE #( typ = 'C' length = 30 ) width = 170 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_OBJECTS' name = 'OBJECT_TEXT' title = 'Description' data_type = VALUE #( typ = 'C' length = 60 ) width = 250 ) ).
    io_builder->end_table_control( ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0230' title = 'Transport Documentation' height = 260 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DOCUMENTATION' position = VALUE #( row = 20 column = 18 width = 520 ) ) text = 'Request documentation' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DOCUMENTATION' position = VALUE #( row = 56 column = 18 width = 520 height = 100 ) ) data_type = VALUE #( typ = 'C' length = 255 ) ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0240' title = 'Transport Logs' height = 280 ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_LOGS' position = VALUE #( row = 18 column = 18 width = 540 height = 140 ) ) visible_rows = 4 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_true ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_LOGS' name = 'LOG_SEVERITY' title = 'Severity' data_type = VALUE #( typ = 'C' length = 8 ) width = 100 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_LOGS' name = 'LOG_TEXT' title = 'Message' data_type = VALUE #( typ = 'C' length = 120 ) width = 400 ) ).
    io_builder->end_table_control( ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD build_flow_screen.
    io_builder->begin_screen( iv_screen ).
    io_builder->begin_pbo( ).
    io_builder->add_module( VALUE #( name = |PBO_{ iv_screen }| ) ).
    io_builder->end_processing( ).
    io_builder->begin_pai( ).
    io_builder->add_module( VALUE #( name = |PAI_{ iv_screen }| on_input = abap_true ) ).
    io_builder->end_processing( ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_flow_logic.
    build_flow_screen( io_builder = io_builder
                       iv_screen  = '0100' ).
    build_flow_screen( io_builder = io_builder
                       iv_screen  = '0200' ).
    build_flow_screen( io_builder = io_builder
                       iv_screen  = '0210' ).
    build_flow_screen( io_builder = io_builder
                       iv_screen  = '0220' ).
    build_flow_screen( io_builder = io_builder
                       iv_screen  = '0230' ).
    build_flow_screen( io_builder = io_builder
                       iv_screen  = '0240' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    put_value( EXPORTING iv_name = 'P_OWNER'
                         iv_value = 'DEVELOPER' CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'P_TYPE'
                         iv_value = 'WORKBENCH' CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'P_STATUS'
                         iv_value = 'ALL' CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = 'Display-only deployment: CTS persistence, release, and export are unavailable.' CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    DATA(lo_service) = NEW zcl_gg_system_transport( ).
    DATA(ls_capabilities) = lo_service->zif_gg_transport_service_v1~get_capabilities( ).

    io_session->get_dialog( )->set_status( VALUE #(
      status       = 'SE09'
      active_ucomm = VALUE #( ( 'DISPLAY' ) ( 'CREATE' ) ( 'SE01' ) ( 'PROPERTIES' ) ( 'OBJECTS' ) ( 'DOCUMENTATION' ) ( 'LOGS' ) ( 'RELEASE' ) ) ) ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = ls_capabilities-explanation CHANGING ct_values = ct_values ).
    ct_states[ name = 'PB_CREATE' ]-enabled = abap_false.
    ct_states[ name = 'PB_CREATE_OVERVIEW' ]-enabled = abap_false.
    IF is_context-screen <> '0100'.
      ct_states[ name = 'PB_RELEASE' ]-enabled = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA(lo_service) = NEW zcl_gg_system_transport( ).
    DATA lv_request_id TYPE string.
    DATA ls_request TYPE zif_gg_system_types_v1=>ty_transport_request.
    DATA lt_tasks TYPE zif_gg_system_types_v1=>ty_transport_tasks.
    DATA lt_objects TYPE zif_gg_system_types_v1=>ty_transport_objects.
    DATA lt_logs TYPE zif_gg_system_types_v1=>ty_transport_logs.
    DATA lv_row TYPE i.

    IF is_context-ucomm = 'BACK'.
      IF is_context-screen = '0100'.
        io_session->get_navigation( )->leave_program( ).
      ELSE.
        io_session->get_dialog( )->set_next_screen( '0100' ).
        io_session->get_dialog( )->leave_screen( ).
      ENDIF.
      RETURN.
    ENDIF.
    IF is_context-ucomm = 'SE01'.
      io_session->get_navigation( )->leave_to_transaction( VALUE #( tcode = 'SE01' ) ).
      RETURN.
    ENDIF.
    IF is_context-ucomm = 'CREATE' OR is_context-ucomm = 'RELEASE'.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'This display-only deployment does not provide transport mutation or release.' ) ).
      RETURN.
    ENDIF.
    IF is_context-screen = '0100' AND is_context-ucomm = 'DISPLAY'.
      lv_request_id = value_of( it_values = ct_values
                                iv_name   = 'P_REQUEST' ).
      ls_request = lo_service->zif_gg_transport_service_v1~get_request( lv_request_id ).
      IF ls_request-error IS NOT INITIAL.
        io_session->message( VALUE #(
          type  = zif_gg_session_types_v1=>message_type_error
          text  = ls_request-error
          field = 'P_REQUEST' ) ).
        RETURN.
      ENDIF.
      put_value( EXPORTING iv_name = 'O_REQ_ID'
                           iv_value = ls_request-request_id CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_REQ_TYPE'
                           iv_value = ls_request-request_type CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_REQ_OWNER'
                           iv_value = ls_request-owner CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_REQ_TEXT'
                           iv_value = ls_request-short_text CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_REQ_STATUS'
                           iv_value = ls_request-status CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_SOURCE'
                           iv_value = ls_request-source_system CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_TARGET'
                           iv_value = ls_request-target_system CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_ATTRIBUTES'
                           iv_value = ls_request-attributes CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_DOCUMENTATION'
                           iv_value = ls_request-documentation CHANGING ct_values = ct_values ).
      lt_tasks = lo_service->zif_gg_transport_service_v1~get_tasks( lv_request_id ).
      LOOP AT lt_tasks INTO DATA(ls_task).
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
      lt_objects = lo_service->zif_gg_transport_service_v1~get_objects( lv_request_id ).
      LOOP AT lt_objects INTO DATA(ls_object).
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
      lt_logs = lo_service->zif_gg_transport_service_v1~get_logs( lv_request_id ).
      LOOP AT lt_logs INTO DATA(ls_log).
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
      io_session->get_dialog( )->set_next_screen( '0200' ).
      io_session->get_dialog( )->leave_screen( ).
      RETURN.
    ENDIF.
    CASE is_context-ucomm.
      WHEN 'PROPERTIES'.
        io_session->get_dialog( )->set_next_screen( '0210' ).
        io_session->get_dialog( )->leave_screen( ).
      WHEN 'OBJECTS'.
        io_session->get_dialog( )->set_next_screen( '0220' ).
        io_session->get_dialog( )->leave_screen( ).
      WHEN 'DOCUMENTATION'.
        io_session->get_dialog( )->set_next_screen( '0230' ).
        io_session->get_dialog( )->leave_screen( ).
      WHEN 'LOGS'.
        io_session->get_dialog( )->set_next_screen( '0240' ).
        io_session->get_dialog( )->leave_screen( ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    DATA(lo_service) = NEW zcl_gg_system_transport( ).
    IF is_context-field = 'P_REQUEST'.
      LOOP AT lo_service->zif_gg_transport_service_v1~get_request_ids( ) INTO DATA(lv_request_id).
        APPEND VALUE #( name = 'P_REQUEST' value = lv_request_id ) TO rt_values.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    CASE is_context-field.
      WHEN 'P_REQUEST'.
        rv_text = 'Enter a server-owned request such as DEVK900001.'
          && ` Tasks and objects are resolved from the transport service.`.
      WHEN 'P_OWNER'.
        rv_text = 'Owner is a display filter; it does not grant authorization.'
          && ` Authorization remains server-owned.`.
    ENDCASE.
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

  METHOD value_of.
    READ TABLE it_values INTO DATA(ls_value)
      WITH KEY container = `` name = iv_name row = 0.
    IF sy-subrc = 0.
      rv_value = ls_value-value.
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
