CLASS zcl_gg_se01 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Transport Organizer (Extended View). Each of the five selection tabs owns a
* screen with its own criteria, so switching tabs never overwrites another
* tab's entries, and each tab validates request numbers against the number
* convention of its transport type. Display opens the shared request editor
* that SE09 also uses.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_transaction_v1.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_tab,
             transport_type TYPE string,
             suffix         TYPE string,
             text           TYPE string,
             screen         TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
             request_field  TYPE zif_gg_dynpro_types_v1=>ty_name,
           END OF ty_tab.
    TYPES ty_tabs TYPE STANDARD TABLE OF ty_tab WITH DEFAULT KEY.

    METHODS tabs
      RETURNING
        VALUE(rt_tabs) TYPE ty_tabs.
    METHODS tab_of_screen
      IMPORTING
        iv_screen     TYPE zif_gg_dynpro_types_v1=>ty_screen_number
      RETURNING
        VALUE(rs_tab) TYPE ty_tab.
    METHODS tab_of_type
      IMPORTING
        iv_transport_type TYPE string
      RETURNING
        VALUE(rs_tab)     TYPE ty_tab.
    METHODS build_tab_screen
      IMPORTING
        io_builder TYPE REF TO zif_gg_dynpro_builder_v1
        is_tab     TYPE ty_tab.
    METHODS add_criteria
      IMPORTING
        io_builder TYPE REF TO zif_gg_dynpro_builder_v1
        is_tab     TYPE ty_tab.
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
    METHODS add_flow
      IMPORTING
        io_builder TYPE REF TO zif_gg_dynpro_flow_builder_v1
        iv_screen  TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        iv_field   TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL.
    METHODS display_request
      IMPORTING
        is_tab           TYPE ty_tab
        iv_target_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        io_session       TYPE REF TO zif_gg_session_v1
      CHANGING
        ct_values        TYPE zif_gg_dynpro_types_v1=>ty_values.

ENDCLASS.

CLASS zcl_gg_se01 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'SE01' description = 'Transport Organizer (Extended View)' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD tabs.
    rt_tabs = VALUE #(
      ( transport_type = zif_gg_system_types_v1=>transport_individual
        suffix         = 'IND'
        text           = 'Display'
        screen         = '0100'
        request_field  = 'P_REQUEST' )
      ( transport_type = zif_gg_system_types_v1=>transport_standard
        suffix         = 'STD'
        text           = 'Transports'
        screen         = '0110'
        request_field  = 'P_STD_REQUEST' )
      ( transport_type = zif_gg_system_types_v1=>transport_piece
        suffix         = 'PCE'
        text           = 'Piece Lists'
        screen         = '0120'
        request_field  = 'P_PCE_REQUEST' )
      ( transport_type = zif_gg_system_types_v1=>transport_client
        suffix         = 'CLI'
        text           = 'Client'
        screen         = '0130'
        request_field  = 'P_CLI_REQUEST' )
      ( transport_type = zif_gg_system_types_v1=>transport_delivery
        suffix         = 'DLV'
        text           = 'Deliveries'
        screen         = '0140'
        request_field  = 'P_DLV_REQUEST' ) ).
  ENDMETHOD.

  METHOD tab_of_screen.
    READ TABLE tabs( ) INTO rs_tab WITH KEY screen = iv_screen.
    IF sy-subrc <> 0.
      CLEAR rs_tab.
    ENDIF.
  ENDMETHOD.

  METHOD tab_of_type.
    READ TABLE tabs( ) INTO rs_tab WITH KEY transport_type = iv_transport_type.
    IF sy-subrc <> 0.
      CLEAR rs_tab.
    ENDIF.
  ENDMETHOD.

  METHOD add_criteria.
    DATA(lo_service) = NEW zcl_gg_system_transport( ).
    DATA(lv_category) = lo_service->zif_gg_transport_service_v1~get_number_category( is_tab-transport_type ).

    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |T_{ is_tab-suffix }_REQUEST| ) position = VALUE #( row = 122 column = 18 width = 170 ) ) text = 'Request / task' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = is_tab-request_field position = VALUE #( row = 116 column = 200 width = 210 ) ) data_type = VALUE #( typ = 'C' length = 20 ) value_help = abap_true required = abap_true uppercase = abap_true ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |T_{ is_tab-suffix }_RULE| ) position = VALUE #( row = 158 column = 18 width = 620 ) ) text = COND string( WHEN lv_category IS INITIAL
                                                                                                                                                                            THEN 'Individual display accepts every request number convention this system knows.'
                                                                                                                                                                            ELSE |Request numbers on this tab follow the <SID>{ lv_category }nnnnn convention.| ) ) ).
    IF is_tab-transport_type = zif_gg_system_types_v1=>transport_standard
        OR is_tab-transport_type = zif_gg_system_types_v1=>transport_piece.
      io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |T_{ is_tab-suffix }_OWNER| ) position = VALUE #( row = 198 column = 18 width = 170 ) ) text = 'Owner' ) ).
      io_builder->add_input_field( VALUE #( control = VALUE #( name = CONV #( |P_{ is_tab-suffix }_OWNER| ) position = VALUE #( row = 192 column = 200 width = 210 ) ) data_type = VALUE #( typ = 'C' length = 12 ) uppercase = abap_true ) ).
    ENDIF.
    IF is_tab-transport_type = zif_gg_system_types_v1=>transport_standard.
      io_builder->add_text( VALUE #( control = VALUE #( name = 'T_STD_STATUS' position = VALUE #( row = 238 column = 18 width = 170 ) ) text = 'Request status' ) ).
      io_builder->add_listbox( VALUE #( control = VALUE #( name = 'P_STD_STATUS' position = VALUE #( row = 232 column = 200 width = 210 ) ) data_type = VALUE #( typ = 'C' length = 12 ) fixed_values = VALUE #( ( key = 'ALL' text = 'All statuses' ) ( key = 'MODIFIABLE' text = 'Modifiable' ) ( key = 'RELEASED' text = 'Released' ) ) ) ).
    ENDIF.
    IF is_tab-transport_type = zif_gg_system_types_v1=>transport_client
        OR is_tab-transport_type = zif_gg_system_types_v1=>transport_delivery.
      io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |T_{ is_tab-suffix }_TARGET| ) position = VALUE #( row = 198 column = 18 width = 170 ) ) text = 'Target system' ) ).
      io_builder->add_input_field( VALUE #( control = VALUE #( name = CONV #( |P_{ is_tab-suffix }_TARGET| ) position = VALUE #( row = 192 column = 200 width = 210 ) ) data_type = VALUE #( typ = 'C' length = 10 ) uppercase = abap_true ) ).
    ENDIF.
  ENDMETHOD.

  METHOD build_tab_screen.
    DATA lv_column TYPE i.

    io_builder->begin_screen( VALUE #( number = is_tab-screen title = |Transport Organizer (Extended View): { is_tab-text }| height = 380 ) ).
    io_builder->add_tabstrip( VALUE #( control = VALUE #( name = CONV #( |TABS_{ is_tab-suffix }| ) position = VALUE #( row = 4 column = 4 width = 560 height = 32 ) ) ) ).
    lv_column = 4.
    LOOP AT tabs( ) INTO DATA(ls_tab).
      io_builder->add_tab( VALUE #( control = VALUE #( name = CONV #( |TAB_{ ls_tab-suffix }_{ is_tab-suffix }| ) position = VALUE #( row = 4 column = lv_column width = 105 ) ) tabstrip = CONV #( |TABS_{ is_tab-suffix }| ) text = ls_tab-text subscreen = ls_tab-screen ucomm = CONV #( ls_tab-transport_type ) ) ).
      lv_column = lv_column + 109.
    ENDLOOP.
    add_criteria( io_builder = io_builder
                  is_tab     = is_tab ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = CONV #( |O_{ is_tab-suffix }_CAPABILITY| ) position = VALUE #( row = 278 column = 18 width = 620 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = CONV #( |PB_{ is_tab-suffix }_DISPLAY| ) position = VALUE #( row = 322 column = 18 width = 120 ) ) text = 'Display' ucomm = 'DISPLAY' ) ).
    IF is_tab-transport_type = zif_gg_system_types_v1=>transport_individual.
      io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_LOGS' position = VALUE #( row = 322 column = 152 width = 100 ) ) text = 'Logs' ucomm = 'LOGS' ) ).
      io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_ACTION_LOG' position = VALUE #( row = 322 column = 262 width = 120 ) ) text = 'Action Log' ucomm = 'ACTION_LOG' ) ).
      io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_SE09' position = VALUE #( row = 322 column = 392 width = 140 ) ) text = 'SE09 Organizer' ucomm = 'SE09' ) ).
    ENDIF.
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    LOOP AT tabs( ) INTO DATA(ls_tab).
      build_tab_screen( io_builder = io_builder
                        is_tab     = ls_tab ).
    ENDLOOP.
    zcl_gg_system_request_view=>build_screens( io_builder ).
  ENDMETHOD.

  METHOD add_flow.
    io_builder->begin_screen( iv_screen ).
    io_builder->begin_pbo( ).
    io_builder->add_module( VALUE #( name = |PBO_{ iv_screen }| ) ).
    io_builder->end_processing( ).
    io_builder->begin_pai( ).
    io_builder->add_module( VALUE #( name = |PAI_{ iv_screen }| on_input = abap_true ) ).
    io_builder->end_processing( ).
    IF iv_field IS NOT INITIAL.
      io_builder->begin_value_request( iv_field ).
      io_builder->add_module( VALUE #( name = |POV_{ iv_screen }| ) ).
      io_builder->end_processing( ).
      io_builder->begin_help_request( iv_field ).
      io_builder->add_module( VALUE #( name = |POH_{ iv_screen }| ) ).
      io_builder->end_processing( ).
    ENDIF.
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_flow_logic.
    LOOP AT tabs( ) INTO DATA(ls_tab).
      add_flow( io_builder = io_builder
                iv_screen  = ls_tab-screen
                iv_field   = ls_tab-request_field ).
    ENDLOOP.
    LOOP AT zcl_gg_system_request_view=>screens( ) INTO DATA(lv_screen).
      add_flow( io_builder = io_builder
                iv_screen  = lv_screen ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    put_value( EXPORTING iv_name = 'P_STD_STATUS'
                         iv_value = 'ALL' CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'P_ACTIVE_TAB'
                         iv_value = zif_gg_system_types_v1=>transport_individual CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = 'Display-only deployment: CTS persistence, release, and export are unavailable.' CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    DATA(lo_service) = NEW zcl_gg_system_transport( ).
    DATA(ls_capabilities) = lo_service->zif_gg_transport_service_v1~get_capabilities( ).

    io_session->get_dialog( )->set_status( VALUE #(
      status       = 'SE01'
      active_ucomm = VALUE #( ( 'DISPLAY' ) ( 'LOGS' ) ( 'ACTION_LOG' ) ( 'CREATE' ) ( 'RELEASE' ) ( 'EXPORT' ) ( 'SE09' ) ( 'PROPERTIES' ) ( 'OBJECTS' ) ( 'DOCUMENTATION' ) ( 'NEW' ) ( 'UTILITIES' ) ( 'INFO' ) )
      icon_bar     = VALUE #( ( ucomm = 'NEW' label = 'New' icon = 'file-code' ) ( ucomm = 'UTILITIES' label = 'Utilities' icon = 'edit' ) ( ucomm = 'INFO' label = 'Information' icon = 'info-circle' ) ) ) ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = ls_capabilities-explanation CHANGING ct_values = ct_values ).
    LOOP AT tabs( ) INTO DATA(ls_tab).
      put_value( EXPORTING iv_name = CONV #( |O_{ ls_tab-suffix }_CAPABILITY| )
                           iv_value = ls_capabilities-explanation CHANGING ct_values = ct_values ).
    ENDLOOP.
    zcl_gg_system_request_view=>disable_mutation( CHANGING ct_states = ct_states ).
  ENDMETHOD.

  METHOD display_request.
    DATA(lo_service) = NEW zcl_gg_system_transport( ).
    DATA ls_request TYPE zif_gg_system_types_v1=>ty_transport_request.

    ls_request = lo_service->zif_gg_transport_service_v1~resolve(
      iv_transport_type = is_tab-transport_type
      iv_request_id     = value_of( it_values = ct_values
                                    iv_name   = is_tab-request_field ) ).
    IF ls_request-error IS NOT INITIAL.
      io_session->message( VALUE #(
        type  = zif_gg_session_types_v1=>message_type_error
        text  = ls_request-error
        field = is_tab-request_field ) ).
      RETURN.
    ENDIF.
    zcl_gg_system_request_view=>fill( EXPORTING is_request = ls_request
                                      CHANGING  ct_values  = ct_values ).
    put_value( EXPORTING iv_name = 'P_ACTIVE_TAB'
                         iv_value = is_tab-transport_type CHANGING ct_values = ct_values ).
    io_session->get_dialog( )->set_next_screen( iv_target_screen ).
    io_session->get_dialog( )->leave_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA ls_tab TYPE ty_tab.
    DATA lv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

    ls_tab = tab_of_screen( is_context-screen ).
    IF is_context-ucomm = 'BACK'.
      IF is_context-screen = '0100'.
        io_session->get_navigation( )->leave_program( ).
        RETURN.
      ENDIF.
      IF ls_tab-screen IS NOT INITIAL.
        lv_screen = '0100'.
      ELSE.
        lv_screen = tab_of_type( value_of( it_values = ct_values
                                           iv_name   = 'P_ACTIVE_TAB' ) )-screen.
        IF lv_screen IS INITIAL.
          lv_screen = '0100'.
        ENDIF.
      ENDIF.
      io_session->get_dialog( )->set_next_screen( lv_screen ).
      io_session->get_dialog( )->leave_screen( ).
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
    IF is_context-ucomm = 'ACTION_LOG'.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'The action log needs a real CTS backend; this deployment cannot show it.' ) ).
      RETURN.
    ENDIF.
    DATA(ls_target_tab) = tab_of_type( CONV string( is_context-ucomm ) ).
    IF ls_target_tab-screen IS NOT INITIAL.
      io_session->get_dialog( )->set_next_screen( ls_target_tab-screen ).
      io_session->get_dialog( )->leave_screen( ).
      RETURN.
    ENDIF.
    IF ls_tab-screen IS NOT INITIAL
        AND ( is_context-ucomm = 'DISPLAY' OR is_context-ucomm = 'LOGS' ).
      display_request(
        EXPORTING
          is_tab           = ls_tab
          iv_target_screen = COND #( WHEN is_context-ucomm = 'LOGS'
                                     THEN zcl_gg_system_request_view=>screen_logs
                                     ELSE zcl_gg_system_request_view=>screen_overview )
          io_session       = io_session
        CHANGING
          ct_values        = ct_values ).
      RETURN.
    ENDIF.
    lv_screen = zcl_gg_system_request_view=>view_screen( is_context-ucomm ).
    IF lv_screen IS NOT INITIAL.
      io_session->get_dialog( )->set_next_screen( lv_screen ).
      io_session->get_dialog( )->leave_screen( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    DATA(lo_service) = NEW zcl_gg_system_transport( ).
    DATA(ls_tab) = tab_of_screen( is_context-screen ).

    IF ls_tab-screen IS INITIAL OR is_context-field <> ls_tab-request_field.
      RETURN.
    ENDIF.
    LOOP AT lo_service->zif_gg_transport_service_v1~get_request_ids( ls_tab-transport_type ) INTO DATA(lv_request_id).
      APPEND VALUE #( name = is_context-field value = lv_request_id ) TO rt_values.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    DATA(lo_service) = NEW zcl_gg_system_transport( ).
    DATA(ls_tab) = tab_of_screen( is_context-screen ).

    IF ls_tab-screen IS INITIAL OR is_context-field <> ls_tab-request_field.
      RETURN.
    ENDIF.
    DATA(lv_category) = lo_service->zif_gg_transport_service_v1~get_number_category( ls_tab-transport_type ).
    IF lv_category IS INITIAL.
      rv_text = 'Individual display resolves any request number this system knows.'.
      RETURN.
    ENDIF.
    rv_text = |This tab accepts <SID>{ lv_category }nnnnn numbers and rejects requests of another transport type.|.
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

ENDCLASS.
