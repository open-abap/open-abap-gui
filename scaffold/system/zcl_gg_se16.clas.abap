CLASS zcl_gg_se16 DEFINITION PUBLIC FINAL CREATE PUBLIC.

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

CLASS zcl_gg_se16 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'SE16' description = 'Data Browser' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' title = 'Data Browser' height = 350 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TABLE' position = VALUE #( row = 18 column = 18 width = 145 ) ) text = 'Table name' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_TABLE' position = VALUE #( row = 12 column = 175 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 30 ) search_help = 'DDIC_TABLE' value_help = abap_true required = abap_true uppercase = abap_true ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_CARRID' position = VALUE #( row = 58 column = 18 width = 145 ) ) text = 'Carrier range' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_CARRID_LOW' position = VALUE #( row = 52 column = 175 width = 80 ) ) data_type = VALUE #( typ = 'C' length = 3 ) uppercase = abap_true ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TO' position = VALUE #( row = 58 column = 263 width = 22 ) ) text = 'to' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_CARRID_HIGH' position = VALUE #( row = 52 column = 290 width = 80 ) ) data_type = VALUE #( typ = 'C' length = 3 ) uppercase = abap_true ) ).
    io_builder->add_checkbox( VALUE #( control = VALUE #( name = 'P_EXCLUDE' position = VALUE #( row = 92 column = 175 width = 180 ) ) text = 'Exclude carrier range' ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_MAX' position = VALUE #( row = 132 column = 18 width = 145 ) ) text = 'Maximum hits' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_MAX_ROWS' position = VALUE #( row = 126 column = 175 width = 80 ) ) data_type = VALUE #( typ = 'N' length = 3 ) required = abap_true ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_FIELDS' position = VALUE #( row = 172 column = 18 width = 145 ) ) text = 'Output fields' ) ).
    io_builder->add_listbox( VALUE #( control = VALUE #( name = 'P_FIELDS' position = VALUE #( row = 166 column = 175 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 12 ) fixed_values = VALUE #( ( key = 'ALL' text = 'All fields' ) ( key = 'KEYS' text = 'Key fields' ) ) ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'P_CAPABILITY' position = VALUE #( row = 210 column = 18 width = 540 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_EXECUTE' position = VALUE #( row = 264 column = 18 width = 100 ) ) text = 'Table Contents' ucomm = 'EXECUTE' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CHANGE' position = VALUE #( row = 264 column = 130 width = 100 ) ) text = 'Change' ucomm = 'CHANGE' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0200' title = 'Table Contents' height = 440 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_RESULT_TABLE' position = VALUE #( row = 12 column = 18 width = 90 ) ) text = 'Table' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_RESULT_TABLE' position = VALUE #( row = 12 column = 115 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_RESULT_COUNT' position = VALUE #( row = 48 column = 18 width = 90 ) ) text = 'Rows' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_RESULT_COUNT' position = VALUE #( row = 48 column = 115 width = 180 ) ) data_type = VALUE #( typ = 'N' length = 20 ) ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_RESULT_FEEDBACK' position = VALUE #( row = 82 column = 18 width = 540 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_RESULT' position = VALUE #( row = 116 column = 18 width = 760 height = 240 ) ) visible_rows = 8 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_true ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_RESULT' name = 'CARRID' title = 'Carrier' data_type = VALUE #( typ = 'C' length = 3 ) width = 80 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_RESULT' name = 'CONNID' title = 'Connection' data_type = VALUE #( typ = 'N' length = 4 ) width = 105 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_RESULT' name = 'FLDATE' title = 'Flight date' data_type = VALUE #( typ = 'D' length = 8 ) width = 105 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_RESULT' name = 'PRICE' title = 'Price' data_type = VALUE #( typ = 'P' length = 15 decimals = 2 ) width = 110 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_RESULT' name = 'CURRENCY' title = 'Currency' data_type = VALUE #( typ = 'C' length = 5 ) width = 90 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_RESULT' name = 'CITYFROM' title = 'From' data_type = VALUE #( typ = 'C' length = 20 ) width = 125 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_RESULT' name = 'CITYTO' title = 'To' data_type = VALUE #( typ = 'C' length = 20 ) width = 125 ) ).
    io_builder->end_table_control( ).
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
    put_value( EXPORTING iv_name = 'P_TABLE'
                         iv_value = 'ZSFLIGHT' CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'P_MAX_ROWS'
                         iv_value = '100' CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'P_FIELDS'
                         iv_value = 'ALL' CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = 'Read-only Data Browser: table mutation and arbitrary SQL are unavailable.' CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    DATA(lo_service) = NEW zcl_gg_system_table_data( ).
    DATA(ls_capabilities) = lo_service->zif_gg_table_data_service_v1~get_capabilities( ).

    io_session->get_dialog( )->set_status( VALUE #(
      status       = 'SE16'
      active_ucomm = VALUE #( ( 'EXECUTE' ) ( 'CHANGE' ) ) ) ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = ls_capabilities-explanation CHANGING ct_values = ct_values ).
    ct_states[ name = 'PB_CHANGE' ]-enabled = abap_false.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA(lo_service) = NEW zcl_gg_system_table_data( ).
    DATA ls_criteria TYPE zif_gg_system_types_v1=>ty_table_criteria.
    DATA ls_result TYPE zif_gg_system_types_v1=>ty_table_result.
    DATA lv_max_text TYPE string.
    DATA lv_max TYPE i.
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
    IF is_context-ucomm = 'CHANGE'.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'This display-only Data Browser does not provide table mutation.' ) ).
      RETURN.
    ENDIF.
    IF is_context-screen = '0100' AND is_context-ucomm = 'EXECUTE'.
      lv_max_text = value_of( it_values = ct_values
                              iv_name   = 'P_MAX_ROWS' ).
      IF lv_max_text IS NOT INITIAL AND lv_max_text CN '0123456789'.
        io_session->message( VALUE #(
          type  = zif_gg_session_types_v1=>message_type_error
          text  = 'Maximum hits must be a positive numeric value.'
          field = 'P_MAX_ROWS' ) ).
        RETURN.
      ENDIF.
      IF lv_max_text IS INITIAL.
        lv_max = 100.
      ELSE.
        lv_max = CONV i( lv_max_text ).
      ENDIF.
      IF lv_max <= 0.
        io_session->message( VALUE #(
          type  = zif_gg_session_types_v1=>message_type_error
          text  = 'Maximum hits must be greater than zero.'
          field = 'P_MAX_ROWS' ) ).
        RETURN.
      ENDIF.
      ls_criteria-table_name = value_of( it_values = ct_values
                                         iv_name   = 'P_TABLE' ).
      ls_criteria-carrid_low = value_of( it_values = ct_values
                                         iv_name   = 'P_CARRID_LOW' ).
      ls_criteria-carrid_high = value_of( it_values = ct_values
                                          iv_name   = 'P_CARRID_HIGH' ).
      ls_criteria-exclude_carrid = xsdbool( value_of( it_values = ct_values
                                                      iv_name   = 'P_EXCLUDE' ) = 'X' ).
      ls_criteria-max_rows = lv_max.
      ls_result = lo_service->zif_gg_table_data_service_v1~read( ls_criteria ).
      IF ls_result-error IS NOT INITIAL.
        io_session->message( VALUE #(
          type  = zif_gg_session_types_v1=>message_type_error
          text  = ls_result-error
          field = 'P_TABLE' ) ).
        RETURN.
      ENDIF.
      put_value( EXPORTING iv_name = 'O_RESULT_TABLE'
                           iv_value = ls_result-table_name CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_RESULT_COUNT'
                           iv_value = |{ ls_result-returned_rows }| CHANGING ct_values = ct_values ).
      IF ls_result-truncated = abap_true.
        put_value( EXPORTING iv_name = 'O_RESULT_FEEDBACK'
                             iv_value = |{ ls_result-returned_rows } of { ls_result-total_rows } rows returned; hard maximum reached.| CHANGING ct_values = ct_values ).
      ELSE.
        put_value( EXPORTING iv_name = 'O_RESULT_FEEDBACK'
                             iv_value = |{ ls_result-returned_rows } rows returned.| CHANGING ct_values = ct_values ).
      ENDIF.
      LOOP AT ls_result-rows INTO DATA(ls_row).
        lv_row = sy-tabix.
        put_cell( EXPORTING iv_container = 'TC_RESULT'
                            iv_name = 'CARRID'
                            iv_row = lv_row
                            iv_value = CONV string( ls_row-carrid ) CHANGING ct_values = ct_values ).
        put_cell( EXPORTING iv_container = 'TC_RESULT'
                            iv_name = 'CONNID'
                            iv_row = lv_row
                            iv_value = CONV string( ls_row-connid ) CHANGING ct_values = ct_values ).
        put_cell( EXPORTING iv_container = 'TC_RESULT'
                            iv_name = 'FLDATE'
                            iv_row = lv_row
                            iv_value = CONV string( ls_row-fldate ) CHANGING ct_values = ct_values ).
        put_cell( EXPORTING iv_container = 'TC_RESULT'
                            iv_name = 'PRICE'
                            iv_row = lv_row
                            iv_value = |{ ls_row-price DECIMALS = 2 }| CHANGING ct_values = ct_values ).
        put_cell( EXPORTING iv_container = 'TC_RESULT'
                            iv_name = 'CURRENCY'
                            iv_row = lv_row
                            iv_value = CONV string( ls_row-currency ) CHANGING ct_values = ct_values ).
        put_cell( EXPORTING iv_container = 'TC_RESULT'
                            iv_name = 'CITYFROM'
                            iv_row = lv_row
                            iv_value = CONV string( ls_row-cityfrom ) CHANGING ct_values = ct_values ).
        put_cell( EXPORTING iv_container = 'TC_RESULT'
                            iv_name = 'CITYTO'
                            iv_row = lv_row
                            iv_value = CONV string( ls_row-cityto ) CHANGING ct_values = ct_values ).
      ENDLOOP.
      io_session->get_dialog( )->set_next_screen( '0200' ).
      io_session->get_dialog( )->leave_screen( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    CASE is_context-field.
      WHEN 'P_TABLE'.
        APPEND VALUE #( name = 'P_TABLE' value = 'ZSFLIGHT' ) TO rt_values.
      WHEN 'P_CARRID_LOW' OR 'P_CARRID_HIGH'.
        APPEND VALUE #( name = is_context-field value = 'AA' ) TO rt_values.
        APPEND VALUE #( name = is_context-field value = 'LH' ) TO rt_values.
        APPEND VALUE #( name = is_context-field value = 'SQ' ) TO rt_values.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    CASE is_context-field.
      WHEN 'P_TABLE'.
        rv_text = 'Only Dictionary tables permitted by the server data-access policy can be read.'.
      WHEN 'P_MAX_ROWS'.
        rv_text = 'The server enforces a hard maximum of 100 rows before data is rendered.'.
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
