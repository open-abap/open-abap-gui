CLASS zcl_gg_se11 DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_transaction_v1.

  PRIVATE SECTION.
    METHODS put_value
      IMPORTING iv_name TYPE zif_gg_dynpro_types_v1=>ty_name iv_value TYPE string
      CHANGING ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS value_of
      IMPORTING it_values TYPE zif_gg_dynpro_types_v1=>ty_values iv_name TYPE zif_gg_dynpro_types_v1=>ty_name
      RETURNING VALUE(rv_value) TYPE string.
    METHODS put_cell
      IMPORTING iv_container TYPE zif_gg_dynpro_types_v1=>ty_name iv_name TYPE zif_gg_dynpro_types_v1=>ty_name iv_row TYPE i iv_value TYPE string
      CHANGING ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS add_flow
      IMPORTING io_builder TYPE REF TO zif_gg_dynpro_flow_builder_v1 iv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

ENDCLASS.

CLASS zcl_gg_se11 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'SE11' description = 'ABAP Dictionary' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' title = 'ABAP Dictionary' height = 330 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_OBJECT_TYPE' position = VALUE #( row = 18 column = 18 width = 140 ) ) text = 'Object type' ) ).
    io_builder->add_listbox( VALUE #( control = VALUE #( name = 'P_OBJECT_TYPE' position = VALUE #( row = 12 column = 170 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 20 ) fixed_values = VALUE #( ( key = 'TABLE' text = 'Database table' ) ( key = 'STRUCTURE' text = 'Structure' ) ( key = 'DATA_ELEMENT' text = 'Data element' ) ( key = 'DOMAIN' text = 'Domain' ) ( key = 'VIEW' text = 'View' ) ( key = 'SEARCH_HELP' text = 'Search help' ) ( key = 'LOCK_OBJECT' text = 'Lock object' ) ( key = 'TABLE_TYPE' text = 'Table type' ) ( key = 'TYPE_GROUP' text = 'Type group' ) ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_OBJECT_NAME' position = VALUE #( row = 60 column = 18 width = 140 ) ) text = 'Object name' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_OBJECT_NAME' position = VALUE #( row = 54 column = 170 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 30 ) value_help = abap_true required = abap_true ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_CHOOSER_INFO' position = VALUE #( row = 102 column = 18 width = 540 ) ) text = 'Display reads server-owned Dictionary metadata. Change and Create are unavailable.' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'P_CAPABILITY' position = VALUE #( row = 142 column = 18 width = 540 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_DISPLAY' position = VALUE #( row = 198 column = 18 width = 96 ) ) text = 'Display' ucomm = 'DISPLAY' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CHANGE' position = VALUE #( row = 198 column = 124 width = 96 ) ) text = 'Change' ucomm = 'CHANGE' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CREATE' position = VALUE #( row = 198 column = 230 width = 96 ) ) text = 'Create' ucomm = 'CREATE' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0200' title = 'Dictionary Object Display' height = 390 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TYPE' position = VALUE #( row = 12 column = 18 width = 120 ) ) text = 'Object type' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_TYPE' position = VALUE #( row = 8 column = 150 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_NAME' position = VALUE #( row = 46 column = 18 width = 120 ) ) text = 'Name' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_NAME' position = VALUE #( row = 42 column = 150 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DESCRIPTION' position = VALUE #( row = 80 column = 18 width = 120 ) ) text = 'Description' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DESCRIPTION' position = VALUE #( row = 76 column = 150 width = 380 ) ) data_type = VALUE #( typ = 'C' length = 80 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DELIVERY' position = VALUE #( row = 114 column = 18 width = 120 ) ) text = 'Delivery class' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DELIVERY' position = VALUE #( row = 110 column = 150 width = 120 ) ) data_type = VALUE #( typ = 'C' length = 4 ) ) ).
    io_builder->add_tabstrip( VALUE #( control = VALUE #( name = 'TAB_DICTIONARY' position = VALUE #( row = 150 column = 18 width = 560 height = 32 ) ) ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_ATTRIBUTES' position = VALUE #( row = 150 column = 18 width = 110 ) ) tabstrip = 'TAB_DICTIONARY' text = 'Attributes' subscreen = '0200' ucomm = 'ATTRIBUTES' ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_FIELDS' position = VALUE #( row = 150 column = 138 width = 90 ) ) tabstrip = 'TAB_DICTIONARY' text = 'Fields' subscreen = '0200' ucomm = 'FIELDS' ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_KEYS' position = VALUE #( row = 150 column = 240 width = 80 ) ) tabstrip = 'TAB_DICTIONARY' text = 'Keys' subscreen = '0200' ucomm = 'KEYS' ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_CHECKS' position = VALUE #( row = 150 column = 330 width = 90 ) ) tabstrip = 'TAB_DICTIONARY' text = 'Checks' subscreen = '0200' ucomm = 'CHECKS' ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_TECHNICAL' position = VALUE #( row = 150 column = 430 width = 110 ) ) tabstrip = 'TAB_DICTIONARY' text = 'Technical settings' subscreen = '0200' ucomm = 'TECHNICAL' ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_FIELDS' position = VALUE #( row = 194 column = 18 width = 560 height = 120 ) ) visible_rows = 4 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_false ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_FIELDS' name = 'FIELD_POSITION' title = 'Pos.' data_type = VALUE #( typ = 'N' length = 4 ) width = 55 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_FIELDS' name = 'FIELD_NAME' title = 'Field' data_type = VALUE #( typ = 'C' length = 30 ) width = 130 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_FIELDS' name = 'FIELD_KEY' title = 'Key' data_type = VALUE #( typ = 'C' length = 3 ) width = 55 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_FIELDS' name = 'FIELD_TYPE' title = 'Data type' data_type = VALUE #( typ = 'C' length = 10 ) width = 100 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_FIELDS' name = 'FIELD_LENGTH' title = 'Length' data_type = VALUE #( typ = 'N' length = 8 ) width = 75 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_FIELDS' name = 'FIELD_TEXT' title = 'Description' data_type = VALUE #( typ = 'C' length = 60 ) width = 180 ) ).
    io_builder->end_table_control( ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TECHNICAL' position = VALUE #( row = 328 column = 18 width = 540 ) ) text = 'Technical settings and database checks are display-only.' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CONTENTS' position = VALUE #( row = 360 column = 18 width = 120 ) ) text = 'Table Contents' ucomm = 'CONTENTS' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CHANGE_DETAILS' position = VALUE #( row = 360 column = 150 width = 96 ) ) text = 'Change' ucomm = 'CHANGE' ) ).
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
    add_flow( io_builder = io_builder iv_screen = '0100' ).
    add_flow( io_builder = io_builder iv_screen = '0200' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    put_value( EXPORTING iv_name = 'P_OBJECT_TYPE' iv_value = 'TABLE' CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY' iv_value = 'Display-only deployment: Dictionary changes require a repository activation pipeline.' CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    DATA(lo_service) = NEW zcl_gg_system_dictionary( ).
    DATA(ls_capabilities) = lo_service->zif_gg_dictionary_service_v1~get_capabilities( ).

    io_session->get_dialog( )->set_status( VALUE #(
      status = 'SE11'
      active_ucomm = VALUE #( ( 'DISPLAY' ) ( 'CHANGE' ) ( 'CREATE' ) ( 'CONTENTS' ) ) ) ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY' iv_value = ls_capabilities-explanation CHANGING ct_values = ct_values ).
    ct_states[ name = 'PB_CHANGE' ]-enabled = abap_false.
    ct_states[ name = 'PB_CHANGE_DETAILS' ]-enabled = abap_false.
    ct_states[ name = 'PB_CREATE' ]-enabled = abap_false.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA(lo_service) = NEW zcl_gg_system_dictionary( ).
    DATA lv_type TYPE string.
    DATA lv_name TYPE string.
    DATA ls_object TYPE zif_gg_system_types_v1=>ty_ddic_object.
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
    IF is_context-ucomm = 'CHANGE' OR is_context-ucomm = 'CREATE'.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'This display-only deployment does not provide Dictionary changes or creation.' ) ).
      RETURN.
    ENDIF.
    IF is_context-screen = '0200' AND is_context-ucomm = 'CONTENTS'.
      io_session->get_navigation( )->leave_to_transaction( VALUE #( tcode = 'SE16' ) ).
      RETURN.
    ENDIF.
    IF is_context-screen = '0200'
        AND ( is_context-ucomm = 'ATTRIBUTES' OR is_context-ucomm = 'FIELDS'
          OR is_context-ucomm = 'KEYS' OR is_context-ucomm = 'CHECKS'
          OR is_context-ucomm = 'TECHNICAL' ).
      RETURN.
    ENDIF.
    IF is_context-screen = '0100' AND is_context-ucomm = 'DISPLAY'.
      lv_type = value_of( it_values = ct_values iv_name = 'P_OBJECT_TYPE' ).
      lv_name = value_of( it_values = ct_values iv_name = 'P_OBJECT_NAME' ).
      ls_object = lo_service->zif_gg_dictionary_service_v1~get_object(
        iv_object_type = lv_type
        iv_name = lv_name ).
      IF ls_object-error IS NOT INITIAL.
        io_session->message( VALUE #(
          type = zif_gg_session_types_v1=>message_type_error
          text = ls_object-error
          field = 'P_OBJECT_NAME' ) ).
        RETURN.
      ENDIF.
      put_value( EXPORTING iv_name = 'O_TYPE' iv_value = ls_object-object_type CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_NAME' iv_value = ls_object-name CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_DESCRIPTION' iv_value = ls_object-description CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_DELIVERY' iv_value = ls_object-delivery_class CHANGING ct_values = ct_values ).
      LOOP AT ls_object-fields INTO DATA(ls_field).
        lv_row = sy-tabix.
        put_cell( EXPORTING iv_container = 'TC_FIELDS' iv_name = 'FIELD_POSITION' iv_row = lv_row iv_value = |{ ls_field-position }| CHANGING ct_values = ct_values ).
        put_cell( EXPORTING iv_container = 'TC_FIELDS' iv_name = 'FIELD_NAME' iv_row = lv_row iv_value = ls_field-name CHANGING ct_values = ct_values ).
        put_cell( EXPORTING iv_container = 'TC_FIELDS' iv_name = 'FIELD_KEY' iv_row = lv_row iv_value = COND string( WHEN ls_field-key_flag = abap_true THEN 'X' ELSE `` ) CHANGING ct_values = ct_values ).
        put_cell( EXPORTING iv_container = 'TC_FIELDS' iv_name = 'FIELD_TYPE' iv_row = lv_row iv_value = ls_field-data_type CHANGING ct_values = ct_values ).
        put_cell( EXPORTING iv_container = 'TC_FIELDS' iv_name = 'FIELD_LENGTH' iv_row = lv_row iv_value = |{ ls_field-length }| CHANGING ct_values = ct_values ).
        put_cell( EXPORTING iv_container = 'TC_FIELDS' iv_name = 'FIELD_TEXT' iv_row = lv_row iv_value = ls_field-description CHANGING ct_values = ct_values ).
      ENDLOOP.
      io_session->get_dialog( )->set_next_screen( '0200' ).
      io_session->get_dialog( )->leave_screen( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    DATA(lo_service) = NEW zcl_gg_system_dictionary( ).
    DATA lv_type TYPE string.
    READ TABLE it_values INTO DATA(ls_type) WITH KEY container = `` name = 'P_OBJECT_TYPE' row = 0.
    IF sy-subrc = 0.
      lv_type = ls_type-value.
    ENDIF.
    IF is_context-field = 'P_OBJECT_NAME'.
      LOOP AT lo_service->zif_gg_dictionary_service_v1~get_names( lv_type ) INTO DATA(lv_name).
        APPEND VALUE #( name = 'P_OBJECT_NAME' value = lv_name ) TO rt_values.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    CASE is_context-field.
      WHEN 'P_OBJECT_NAME'.
        rv_text = 'Use F4 to select a permitted Dictionary table or view.'
          && ` The initial delivery exposes ZSFLIGHT.`.
      WHEN 'P_OBJECT_TYPE'.
        rv_text = 'Object kinds remain distinct; unsupported kinds are rejected without metadata leakage.'.
    ENDCASE.
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
