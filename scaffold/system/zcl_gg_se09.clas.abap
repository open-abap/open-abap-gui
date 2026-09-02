CLASS zcl_gg_se09 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Transport Organizer. The selection screen belongs to this transaction; the
* request editor behind it is the shared zcl_gg_system_request_view, so SE09
* and the SE01 extended view show one hierarchy and one set of request views.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_transaction_v1.

  PRIVATE SECTION.
    CONSTANTS screen_selection TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0100'.

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
    METHODS build_flow_screen
      IMPORTING
        io_builder TYPE REF TO zif_gg_dynpro_flow_builder_v1
        iv_screen  TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        iv_field   TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL.

ENDCLASS.

CLASS zcl_gg_se09 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'SE09' description = 'Transport Organizer' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = screen_selection.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = screen_selection title = 'Transport Organizer' height = 310 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_INTRO' position = VALUE #( row = 12 column = 18 width = 540 ) ) text = 'Select requests and tasks owned by the server transport catalog.' ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_OWNER' position = VALUE #( row = 48 column = 18 width = 125 ) ) text = 'Owner' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_OWNER' position = VALUE #( row = 42 column = 155 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 12 ) value_help = abap_true ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_REQUEST' position = VALUE #( row = 84 column = 18 width = 125 ) ) text = 'Request / task' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_REQUEST' position = VALUE #( row = 78 column = 155 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 12 ) value_help = abap_true required = abap_true uppercase = abap_true ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TYPE' position = VALUE #( row = 120 column = 18 width = 125 ) ) text = 'Request type' ) ).
    io_builder->add_listbox( VALUE #( control = VALUE #( name = 'P_TYPE' position = VALUE #( row = 114 column = 155 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 12 ) fixed_values = VALUE #( ( key = 'WORKBENCH' text = 'Workbench' ) ( key = 'CUSTOMIZING' text = 'Customizing' ) ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_STATUS' position = VALUE #( row = 156 column = 18 width = 125 ) ) text = 'Request status' ) ).
    io_builder->add_listbox( VALUE #( control = VALUE #( name = 'P_STATUS' position = VALUE #( row = 150 column = 155 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 12 ) fixed_values = VALUE #( ( key = 'ALL' text = 'All statuses' ) ( key = 'MODIFIABLE' text = 'Modifiable' ) ( key = 'RELEASED' text = 'Released' ) ) ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'P_CAPABILITY' position = VALUE #( row = 192 column = 18 width = 540 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_DISPLAY' position = VALUE #( row = 238 column = 18 width = 96 ) ) text = 'Display' ucomm = 'DISPLAY' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CREATE' position = VALUE #( row = 238 column = 124 width = 96 ) ) text = 'Create' ucomm = 'CREATE' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_EXTENDED' position = VALUE #( row = 238 column = 230 width = 140 ) ) text = 'SE01 Extended View' ucomm = 'SE01' ) ).
    io_builder->end_screen( ).

    zcl_gg_system_request_view=>build_screens( io_builder ).
  ENDMETHOD.

  METHOD build_flow_screen.
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
    build_flow_screen( io_builder = io_builder
                       iv_screen  = screen_selection
                       iv_field   = 'P_REQUEST' ).
    LOOP AT zcl_gg_system_request_view=>screens( ) INTO DATA(lv_screen).
      build_flow_screen( io_builder = io_builder
                         iv_screen  = lv_screen ).
    ENDLOOP.
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
      active_ucomm = VALUE #( ( 'DISPLAY' ) ( 'CREATE' ) ( 'SE01' ) ( 'PROPERTIES' ) ( 'OBJECTS' ) ( 'DOCUMENTATION' ) ( 'LOGS' ) ( 'RELEASE' ) ( 'EXPORT' ) ) ) ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = ls_capabilities-explanation CHANGING ct_values = ct_values ).
    ct_states[ name = 'PB_CREATE' ]-enabled = abap_false.
    zcl_gg_system_request_view=>disable_mutation( CHANGING ct_states = ct_states ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA(lo_service) = NEW zcl_gg_system_transport( ).
    DATA lv_request_id TYPE string.
    DATA lv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    DATA ls_request TYPE zif_gg_system_types_v1=>ty_transport_request.

    IF is_context-ucomm = 'BACK'.
      IF is_context-screen = screen_selection.
        io_session->get_navigation( )->leave_program( ).
      ELSE.
        io_session->get_dialog( )->set_next_screen( screen_selection ).
        io_session->get_dialog( )->leave_screen( ).
      ENDIF.
      RETURN.
    ENDIF.
    IF is_context-ucomm = 'SE01'.
      io_session->get_navigation( )->leave_to_transaction( VALUE #( tcode = 'SE01' ) ).
      RETURN.
    ENDIF.
    IF is_context-ucomm = 'CREATE' OR is_context-ucomm = 'RELEASE' OR is_context-ucomm = 'EXPORT'.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'This display-only deployment does not provide transport mutation or release.' ) ).
      RETURN.
    ENDIF.
    IF is_context-screen = screen_selection AND is_context-ucomm = 'DISPLAY'.
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
      zcl_gg_system_request_view=>fill( EXPORTING is_request = ls_request
                                        CHANGING  ct_values  = ct_values ).
      io_session->get_dialog( )->set_next_screen( zcl_gg_system_request_view=>screen_overview ).
      io_session->get_dialog( )->leave_screen( ).
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

ENDCLASS.
