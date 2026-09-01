CLASS zcl_gg_se01 DEFINITION PUBLIC FINAL CREATE PUBLIC.

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
    METHODS add_flow
      IMPORTING
        io_builder TYPE REF TO zif_gg_dynpro_flow_builder_v1
        iv_screen  TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

ENDCLASS.

CLASS zcl_gg_se01 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'SE01' description = 'Transport Organizer (Extended View)' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' title = 'Transport Organizer (Extended View)' height = 300 ) ).
    io_builder->add_tabstrip( VALUE #( control = VALUE #( name = 'TAB_ORGANIZER' position = VALUE #( row = 4 column = 4 width = 560 height = 32 ) ) ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_DISPLAY' position = VALUE #( row = 4 column = 4 width = 105 ) ) tabstrip = 'TAB_ORGANIZER' text = 'Display' subscreen = '0100' ucomm = 'INDIVIDUAL' ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_TRANSPORTS' position = VALUE #( row = 4 column = 113 width = 105 ) ) tabstrip = 'TAB_ORGANIZER' text = 'Transports' subscreen = '0100' ucomm = 'STANDARD' ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_PIECE' position = VALUE #( row = 4 column = 222 width = 105 ) ) tabstrip = 'TAB_ORGANIZER' text = 'Piece Lists' subscreen = '0100' ucomm = 'PIECE' ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_CLIENT' position = VALUE #( row = 4 column = 331 width = 85 ) ) tabstrip = 'TAB_ORGANIZER' text = 'Client' subscreen = '0100' ucomm = 'CLIENT' ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_DELIVERIES' position = VALUE #( row = 4 column = 420 width = 105 ) ) tabstrip = 'TAB_ORGANIZER' text = 'Deliveries' subscreen = '0100' ucomm = 'DELIVERY' ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_REQUEST' position = VALUE #( row = 116 column = 12 width = 150 ) ) text = 'Request/Task' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_REQUEST' position = VALUE #( row = 110 column = 200 width = 210 ) ) data_type = VALUE #( typ = 'C' length = 20 ) value_help = abap_true required = abap_true ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_DISPLAY' position = VALUE #( row = 166 column = 12 width = 200 ) ) text = 'Display' ucomm = 'DISPLAY' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_LOGS' position = VALUE #( row = 166 column = 212 width = 200 ) ) text = 'Logs' ucomm = 'LOGS' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_ACTION_LOG' position = VALUE #( row = 166 column = 412 width = 200 ) ) text = 'Action Log' ucomm = 'ACTION_LOG' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0200' title = 'Extended Request Display' height = 340 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_REQ_ID' position = VALUE #( row = 14 column = 18 width = 120 ) ) text = 'Request' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_REQ_ID' position = VALUE #( row = 10 column = 150 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_REQ_TYPE' position = VALUE #( row = 48 column = 18 width = 120 ) ) text = 'Request type' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_REQ_TYPE' position = VALUE #( row = 44 column = 150 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_OWNER' position = VALUE #( row = 82 column = 18 width = 120 ) ) text = 'Owner' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_OWNER' position = VALUE #( row = 78 column = 150 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_STATUS' position = VALUE #( row = 116 column = 18 width = 120 ) ) text = 'Status' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_STATUS' position = VALUE #( row = 112 column = 150 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ROUTE' position = VALUE #( row = 150 column = 18 width = 120 ) ) text = 'Route' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ROUTE' position = VALUE #( row = 146 column = 150 width = 360 ) ) data_type = VALUE #( typ = 'C' length = 50 ) ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_OBJECTS' position = VALUE #( row = 182 column = 18 width = 540 height = 80 ) ) visible_rows = 2 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_false ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_OBJECTS' name = 'OBJECT_TYPE' title = 'Type' data_type = VALUE #( typ = 'C' length = 8 ) width = 100 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_OBJECTS' name = 'OBJECT_NAME' title = 'Object' data_type = VALUE #( typ = 'C' length = 30 ) width = 170 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_OBJECTS' name = 'OBJECT_TEXT' title = 'Description' data_type = VALUE #( typ = 'C' length = 60 ) width = 250 ) ).
    io_builder->end_table_control( ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_RELEASE' position = VALUE #( row = 282 column = 18 width = 96 ) ) text = 'Release' ucomm = 'RELEASE' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_EXPORT' position = VALUE #( row = 282 column = 124 width = 96 ) ) text = 'Export' ucomm = 'EXPORT' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_SE09' position = VALUE #( row = 282 column = 230 width = 120 ) ) text = 'SE09 Organizer' ucomm = 'SE09' ) ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD add_flow.
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
    add_flow( io_builder = io_builder
              iv_screen  = '0100' ).
    add_flow( io_builder = io_builder
              iv_screen  = '0200' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    put_value( EXPORTING iv_name = 'P_REQUEST_TYPE'
                         iv_value = 'STANDARD' CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = 'Display-only deployment: CTS persistence, release, and export are unavailable.' CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    DATA(lo_service) = NEW zcl_gg_system_transport( ).
    DATA(ls_capabilities) = lo_service->zif_gg_transport_service_v1~get_capabilities( ).

    io_session->get_dialog( )->set_status( VALUE #(
      status       = ''
      active_ucomm = VALUE #( ( 'DISPLAY' ) ( 'LOGS' ) ( 'ACTION_LOG' ) ( 'CREATE' ) ( 'RELEASE' ) ( 'EXPORT' ) ( 'SE09' ) ( 'NEW' ) ( 'UTILITIES' ) ( 'INFO' ) )
      icon_bar     = VALUE #( ( ucomm = 'NEW' label = 'New' icon = 'file-code' ) ( ucomm = 'UTILITIES' label = 'Utilities' icon = 'edit' ) ( ucomm = 'INFO' label = 'Information' icon = 'info-circle' ) ) ) ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = ls_capabilities-explanation CHANGING ct_values = ct_values ).
    ct_states[ name = 'PB_RELEASE' ]-enabled = abap_false.
    ct_states[ name = 'PB_EXPORT' ]-enabled = abap_false.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA(lo_service) = NEW zcl_gg_system_transport( ).
    DATA lv_request_id TYPE string.
    DATA ls_request TYPE zif_gg_system_types_v1=>ty_transport_request.
    DATA lt_objects TYPE zif_gg_system_types_v1=>ty_transport_objects.
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
    IF is_context-ucomm = 'SE09'.
      io_session->get_navigation( )->leave_to_transaction( VALUE #( tcode = 'SE09' ) ).
      RETURN.
    ENDIF.
    IF is_context-ucomm = 'CREATE' OR is_context-ucomm = 'RELEASE' OR is_context-ucomm = 'EXPORT'.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'This display-only deployment does not provide create, release, or export operations.' ) ).
      RETURN.
    ENDIF.
    IF is_context-screen = '0100'
        AND ( is_context-ucomm = 'STANDARD' OR is_context-ucomm = 'PIECE'
          OR is_context-ucomm = 'CLIENT' OR is_context-ucomm = 'DELIVERY'
          OR is_context-ucomm = 'INDIVIDUAL' ).
      put_value( EXPORTING iv_name = 'P_REQUEST_TYPE'
                           iv_value = CONV string( is_context-ucomm ) CHANGING ct_values = ct_values ).
      io_session->get_dialog( )->set_next_screen( '0100' ).
      io_session->get_dialog( )->leave_screen( ).
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
      put_value( EXPORTING iv_name = 'O_OWNER'
                           iv_value = ls_request-owner CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_STATUS'
                           iv_value = ls_request-status CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_ROUTE'
                           iv_value = |{ ls_request-source_system } -> { ls_request-target_system }| CHANGING ct_values = ct_values ).
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
      io_session->get_dialog( )->set_next_screen( '0200' ).
      io_session->get_dialog( )->leave_screen( ).
    ENDIF.
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
    IF is_context-field = 'P_REQUEST'.
      rv_text = 'Standard request DEVK900001 is available in the server-owned catalog.'
        && ` Other identifiers are rejected.`.
    ENDIF.
  ENDMETHOD.

  METHOD put_value.
    FIELD-SYMBOLS <ls_value> TYPE zif_gg_dynpro_types_v1=>ty_value.
    READ TABLE ct_values ASSIGNING <ls_value> WITH KEY container = `` name = iv_name row = 0.
    IF sy-subrc <> 0.
      INSERT VALUE #( name = iv_name value = iv_value ) INTO TABLE ct_values.
    ELSE.
      <ls_value>-value = iv_value.
    ENDIF.
  ENDMETHOD.

  METHOD value_of.
    READ TABLE it_values INTO DATA(ls_value) WITH KEY container = `` name = iv_name row = 0.
    IF sy-subrc = 0.
      rv_value = ls_value-value.
    ENDIF.
  ENDMETHOD.

  METHOD put_cell.
    FIELD-SYMBOLS <ls_value> TYPE zif_gg_dynpro_types_v1=>ty_value.
    READ TABLE ct_values ASSIGNING <ls_value> WITH KEY container = iv_container name = iv_name row = iv_row.
    IF sy-subrc <> 0.
      INSERT VALUE #( container = iv_container name = iv_name row = iv_row value = iv_value ) INTO TABLE ct_values.
    ELSE.
      <ls_value>-value = iv_value.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
