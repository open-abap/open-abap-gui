CLASS zcl_gg_se16 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Data Browser. The criteria screen and the result table are generated from
* the Dictionary metadata of each table the data-access policy permits, one
* screen pair per table. A criterion control carries the field position, so
* the browser never names a field, an operator target, a sort or a filter.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_transaction_v1.

  PRIVATE SECTION.
    CONSTANTS screen_table_name TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0100'.
    CONSTANTS criteria_base TYPE i VALUE 150.
    CONSTANTS result_base TYPE i VALUE 200.
    CONSTANTS screen_step TYPE i VALUE 10.
    CONSTANTS default_max_rows TYPE string VALUE '100'.

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
        iv_screen  TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        iv_field   TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL.
    METHODS permitted_tables
      RETURNING
        VALUE(rt_names) TYPE string_table.
    METHODS criteria_screen
      IMPORTING
        iv_index         TYPE i
      RETURNING
        VALUE(rv_screen) TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    METHODS result_screen
      IMPORTING
        iv_index         TYPE i
      RETURNING
        VALUE(rv_screen) TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    METHODS index_of_screen
      IMPORTING
        iv_screen       TYPE zif_gg_dynpro_types_v1=>ty_screen_number
      RETURNING
        VALUE(rv_index) TYPE i.
    METHODS index_of_table
      IMPORTING
        iv_table_name   TYPE string
      RETURNING
        VALUE(rv_index) TYPE i.
    METHODS build_criteria_screen
      IMPORTING
        io_builder TYPE REF TO zif_gg_dynpro_builder_v1
        iv_index   TYPE i
        iv_table   TYPE string
        it_fields  TYPE zif_gg_system_types_v1=>ty_ddic_fields.
    METHODS build_result_screen
      IMPORTING
        io_builder TYPE REF TO zif_gg_dynpro_builder_v1
        iv_index   TYPE i
        iv_table   TYPE string
        it_fields  TYPE zif_gg_system_types_v1=>ty_ddic_fields.
    METHODS collect_criteria
      IMPORTING
        iv_index           TYPE i
        iv_table           TYPE string
        it_fields          TYPE zif_gg_system_types_v1=>ty_ddic_fields
        it_values          TYPE zif_gg_dynpro_types_v1=>ty_values
      RETURNING
        VALUE(rs_criteria) TYPE zif_gg_system_types_v1=>ty_table_criteria.
    METHODS put_result
      IMPORTING
        iv_index  TYPE i
        is_result TYPE zif_gg_system_types_v1=>ty_table_result
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS field_label
      IMPORTING
        is_field        TYPE zif_gg_system_types_v1=>ty_ddic_field
      RETURNING
        VALUE(rv_label) TYPE string.
    METHODS operator_values
      RETURNING
        VALUE(rt_values) TYPE zif_gg_dynpro_types_v1=>ty_fixed_values.

ENDCLASS.

CLASS zcl_gg_se16 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'SE16' description = 'Data Browser' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = screen_table_name.
  ENDMETHOD.

  METHOD permitted_tables.
    DATA(lo_service) = NEW zcl_gg_system_table_data( ).
    rt_names = lo_service->zif_gg_table_data_service_v1~get_table_names( ).
  ENDMETHOD.

  METHOD criteria_screen.
    rv_screen = criteria_base + ( iv_index - 1 ) * screen_step.
  ENDMETHOD.

  METHOD result_screen.
    rv_screen = result_base + ( iv_index - 1 ) * screen_step.
  ENDMETHOD.

  METHOD index_of_screen.
    DATA lv_index TYPE i.

    LOOP AT permitted_tables( ) INTO DATA(lv_table).
      lv_index = sy-tabix.
      IF iv_screen = criteria_screen( lv_index ) OR iv_screen = result_screen( lv_index ).
        rv_index = lv_index.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD index_of_table.
    DATA lv_table_name TYPE string.

    lv_table_name = iv_table_name.
    SHIFT lv_table_name LEFT DELETING LEADING space.
    TRANSLATE lv_table_name TO UPPER CASE.
    LOOP AT permitted_tables( ) INTO DATA(lv_table).
      IF lv_table = lv_table_name.
        rv_index = sy-tabix.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD field_label.
    rv_label = |{ is_field-name }|.
    IF is_field-description IS NOT INITIAL.
      rv_label = |{ rv_label } - { is_field-description }|.
    ENDIF.
  ENDMETHOD.

  METHOD operator_values.
    rt_values = VALUE #(
      ( key = zif_gg_system_types_v1=>operator_eq text = 'Equal to' )
      ( key = zif_gg_system_types_v1=>operator_bt text = 'Between (range)' )
      ( key = zif_gg_system_types_v1=>operator_ne text = 'Exclude value' )
      ( key = zif_gg_system_types_v1=>operator_nb text = 'Exclude range' ) ).
  ENDMETHOD.

  METHOD build_criteria_screen.
    DATA lv_row TYPE i.
    DATA lv_position TYPE i.

    io_builder->begin_screen( VALUE #( number = criteria_screen( iv_index ) title = |Data Browser: { iv_table }| height = 200 + lines( it_fields ) * 40 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_TITLE| ) position = VALUE #( row = 14 column = 18 width = 620 ) ) text = |Selection criteria generated from the Dictionary metadata of { iv_table }.| ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_HFIELD| ) position = VALUE #( row = 54 column = 18 width = 230 ) ) text = 'Field' ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_HOP| ) position = VALUE #( row = 54 column = 256 width = 130 ) ) text = 'Operator' ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_HLOW| ) position = VALUE #( row = 54 column = 396 width = 110 ) ) text = 'Value' ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_HHIGH| ) position = VALUE #( row = 54 column = 546 width = 110 ) ) text = 'To' ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_HOUT| ) position = VALUE #( row = 54 column = 690 width = 110 ) ) text = 'Output' ) ).
    LOOP AT it_fields INTO DATA(ls_field).
      lv_row = 84 + ( sy-tabix - 1 ) * 40.
      lv_position = ls_field-position.
      io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_LBL{ lv_position }| ) position = VALUE #( row = lv_row + 6 column = 18 width = 230 ) ) text = field_label( ls_field ) ) ).
      io_builder->add_listbox( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_OP{ lv_position }| ) position = VALUE #( row = lv_row column = 256 width = 130 ) ) data_type = VALUE #( typ = 'C' length = 2 ) fixed_values = operator_values( ) ) ).
      io_builder->add_input_field( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_LOW{ lv_position }| ) position = VALUE #( row = lv_row column = 396 width = 110 ) ) data_type = VALUE #( typ = ls_field-int_type length = ls_field-length decimals = ls_field-decimals ) value_help = xsdbool( ls_field-search_help IS NOT INITIAL ) uppercase = abap_true ) ).
      io_builder->add_input_field( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_HIGH{ lv_position }| ) position = VALUE #( row = lv_row column = 546 width = 110 ) ) data_type = VALUE #( typ = ls_field-int_type length = ls_field-length decimals = ls_field-decimals ) uppercase = abap_true ) ).
      io_builder->add_checkbox( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_OUT{ lv_position }| ) position = VALUE #( row = lv_row column = 690 width = 110 ) ) text = 'Output' ) ).
    ENDLOOP.
    lv_row = 104 + lines( it_fields ) * 40.
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_TMAX| ) position = VALUE #( row = lv_row + 6 column = 18 width = 230 ) ) text = 'Maximum number of hits' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_MAX| ) position = VALUE #( row = lv_row column = 256 width = 110 ) ) data_type = VALUE #( typ = 'N' length = 3 ) required = abap_true ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_CAP| ) position = VALUE #( row = lv_row + 40 column = 18 width = 620 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_RUN| ) position = VALUE #( row = lv_row + 82 column = 18 width = 120 ) ) text = 'Execute' ucomm = 'EXECUTE' ) ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD build_result_screen.
    DATA lv_position TYPE i.
    DATA(lv_container) = CONV zif_gg_dynpro_types_v1=>ty_name( |P_T{ iv_index }_TC| ).

    io_builder->begin_screen( VALUE #( number = result_screen( iv_index ) title = |Table Contents: { iv_table }| height = 440 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_RTAB| ) position = VALUE #( row = 16 column = 18 width = 90 ) ) text = 'Table' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_ONAME| ) position = VALUE #( row = 12 column = 115 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_RCNT| ) position = VALUE #( row = 52 column = 18 width = 90 ) ) text = 'Rows' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_OCNT| ) position = VALUE #( row = 48 column = 115 width = 180 ) ) data_type = VALUE #( typ = 'N' length = 20 ) ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_OFB| ) position = VALUE #( row = 82 column = 18 width = 620 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = CONV #( |P_T{ iv_index }_OFLD| ) position = VALUE #( row = 116 column = 18 width = 620 ) ) data_type = VALUE #( typ = 'C' length = 200 ) ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = lv_container position = VALUE #( row = 150 column = 18 width = 900 height = 240 ) ) visible_rows = 8 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_true ) ).
    LOOP AT it_fields INTO DATA(ls_field).
      lv_position = ls_field-position.
      io_builder->add_table_column( VALUE #( table_control = lv_container name = CONV #( |P_T{ iv_index }_C{ lv_position }| ) title = COND string( WHEN ls_field-description IS INITIAL THEN ls_field-name ELSE ls_field-description ) data_type = VALUE #( typ = ls_field-int_type length = ls_field-length decimals = ls_field-decimals ) width = 130 ) ).
    ENDLOOP.
    io_builder->end_table_control( ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    DATA(lo_service) = NEW zcl_gg_system_table_data( ).
    DATA lv_index TYPE i.

    io_builder->begin_screen( VALUE #( number = screen_table_name title = 'Data Browser' height = 260 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TABLE' position = VALUE #( row = 18 column = 18 width = 145 ) ) text = 'Table name' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_TABLE' position = VALUE #( row = 12 column = 175 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 30 ) search_help = 'DDIC_TABLE' value_help = abap_true required = abap_true uppercase = abap_true ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TABLE_INFO' position = VALUE #( row = 58 column = 18 width = 620 ) ) text = 'Table Contents opens the selection screen generated from the field metadata of that table.' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'P_CAPABILITY' position = VALUE #( row = 98 column = 18 width = 620 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_SELECTION' position = VALUE #( row = 150 column = 18 width = 120 ) ) text = 'Table Contents' ucomm = 'SELECTION' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CHANGE' position = VALUE #( row = 150 column = 150 width = 100 ) ) text = 'Change' ucomm = 'CHANGE' ) ).
    io_builder->end_screen( ).

    LOOP AT permitted_tables( ) INTO DATA(lv_table).
      lv_index = sy-tabix.
      DATA(lt_fields) = lo_service->zif_gg_table_data_service_v1~get_fields( lv_table ).
      build_criteria_screen( io_builder = io_builder
                             iv_index   = lv_index
                             iv_table   = lv_table
                             it_fields  = lt_fields ).
      build_result_screen( io_builder = io_builder
                           iv_index   = lv_index
                           iv_table   = lv_table
                           it_fields  = lt_fields ).
    ENDLOOP.
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
    DATA lv_index TYPE i.

    add_flow( io_builder = io_builder
              iv_screen  = screen_table_name
              iv_field   = 'P_TABLE' ).
    LOOP AT permitted_tables( ) INTO DATA(lv_table).
      lv_index = sy-tabix.
      add_flow( io_builder = io_builder
                iv_screen  = criteria_screen( lv_index )
                iv_field   = CONV #( |P_T{ lv_index }_LOW1| ) ).
      add_flow( io_builder = io_builder
                iv_screen  = result_screen( lv_index ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    DATA(lo_service) = NEW zcl_gg_system_table_data( ).
    DATA lv_index TYPE i.
    DATA lv_position TYPE i.

    LOOP AT permitted_tables( ) INTO DATA(lv_table).
      lv_index = sy-tabix.
      IF lv_index = 1.
        put_value( EXPORTING iv_name = 'P_TABLE'
                             iv_value = lv_table CHANGING ct_values = ct_values ).
      ENDIF.
      put_value( EXPORTING iv_name = CONV #( |P_T{ lv_index }_MAX| )
                           iv_value = default_max_rows CHANGING ct_values = ct_values ).
      LOOP AT lo_service->zif_gg_table_data_service_v1~get_fields( lv_table ) INTO DATA(ls_field).
        lv_position = ls_field-position.
        put_value( EXPORTING iv_name = CONV #( |P_T{ lv_index }_OP{ lv_position }| )
                             iv_value = zif_gg_system_types_v1=>operator_eq CHANGING ct_values = ct_values ).
      ENDLOOP.
    ENDLOOP.
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = 'Read-only Data Browser: table mutation and arbitrary SQL are unavailable.' CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    DATA(lo_service) = NEW zcl_gg_system_table_data( ).
    DATA(ls_capabilities) = lo_service->zif_gg_table_data_service_v1~get_capabilities( ).
    DATA lv_index TYPE i.

    io_session->get_dialog( )->set_status( VALUE #(
      status       = 'SE16'
      active_ucomm = VALUE #( ( 'SELECTION' ) ( 'EXECUTE' ) ( 'CHANGE' ) ) ) ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = ls_capabilities-explanation CHANGING ct_values = ct_values ).
    LOOP AT permitted_tables( ) INTO DATA(lv_table).
      lv_index = sy-tabix.
      put_value( EXPORTING iv_name = CONV #( |P_T{ lv_index }_CAP| )
                           iv_value = ls_capabilities-explanation CHANGING ct_values = ct_values ).
    ENDLOOP.
    ct_states[ name = 'PB_CHANGE' ]-enabled = abap_false.
  ENDMETHOD.

  METHOD collect_criteria.
    DATA lv_max TYPE string.
    DATA lv_position TYPE i.

    rs_criteria-table_name = iv_table.
    lv_max = value_of( it_values = it_values
                       iv_name   = CONV #( |P_T{ iv_index }_MAX| ) ).
    IF lv_max IS INITIAL.
      lv_max = default_max_rows.
    ENDIF.
    IF lv_max CO '0123456789'.
      rs_criteria-max_rows = CONV i( lv_max ).
    ENDIF.
    LOOP AT it_fields INTO DATA(ls_field).
      lv_position = ls_field-position.
      APPEND VALUE #(
        position = lv_position
        operator = value_of( it_values = it_values
                             iv_name   = CONV #( |P_T{ iv_index }_OP{ lv_position }| ) )
        low      = value_of( it_values = it_values
                             iv_name   = CONV #( |P_T{ iv_index }_LOW{ lv_position }| ) )
        high     = value_of( it_values = it_values
                             iv_name   = CONV #( |P_T{ iv_index }_HIGH{ lv_position }| ) )
        output   = xsdbool( value_of( it_values = it_values
                                      iv_name   = CONV #( |P_T{ iv_index }_OUT{ lv_position }| ) ) = 'X' )
        ) TO rs_criteria-rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD put_result.
    DATA lv_fields TYPE string.
    DATA lv_position TYPE i.

    put_value( EXPORTING iv_name = CONV #( |P_T{ iv_index }_ONAME| )
                         iv_value = is_result-table_name CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = CONV #( |P_T{ iv_index }_OCNT| )
                         iv_value = |{ is_result-returned_rows }| CHANGING ct_values = ct_values ).
    IF is_result-truncated = abap_true.
      put_value( EXPORTING iv_name = CONV #( |P_T{ iv_index }_OFB| )
                           iv_value = |{ is_result-returned_rows } of { is_result-total_rows } rows returned; hard maximum reached.| CHANGING ct_values = ct_values ).
    ELSE.
      put_value( EXPORTING iv_name = CONV #( |P_T{ iv_index }_OFB| )
                           iv_value = |{ is_result-returned_rows } rows returned.| CHANGING ct_values = ct_values ).
    ENDIF.
    LOOP AT is_result-fields INTO DATA(ls_field).
      IF lv_fields IS INITIAL.
        lv_fields = ls_field-name.
      ELSE.
        lv_fields = |{ lv_fields }, { ls_field-name }|.
      ENDIF.
    ENDLOOP.
    put_value( EXPORTING iv_name = CONV #( |P_T{ iv_index }_OFLD| )
                         iv_value = |Output fields: { lv_fields }| CHANGING ct_values = ct_values ).
    LOOP AT is_result-cells INTO DATA(ls_cell).
      lv_position = ls_cell-position.
      put_cell( EXPORTING iv_container = CONV #( |P_T{ iv_index }_TC| )
                          iv_name = CONV #( |P_T{ iv_index }_C{ lv_position }| )
                          iv_row = ls_cell-row
                          iv_value = ls_cell-value CHANGING ct_values = ct_values ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA(lo_service) = NEW zcl_gg_system_table_data( ).
    DATA ls_criteria TYPE zif_gg_system_types_v1=>ty_table_criteria.
    DATA ls_result TYPE zif_gg_system_types_v1=>ty_table_result.
    DATA lt_tables TYPE string_table.
    DATA lv_index TYPE i.
    DATA lv_table TYPE string.

    IF is_context-ucomm = 'BACK'.
      IF is_context-screen = screen_table_name.
        io_session->get_navigation( )->leave_program( ).
        RETURN.
      ENDIF.
      lv_index = index_of_screen( is_context-screen ).
      IF lv_index > 0 AND is_context-screen = result_screen( lv_index ).
        io_session->get_dialog( )->set_next_screen( criteria_screen( lv_index ) ).
      ELSE.
        io_session->get_dialog( )->set_next_screen( screen_table_name ).
      ENDIF.
      io_session->get_dialog( )->leave_screen( ).
      RETURN.
    ENDIF.
    IF is_context-ucomm = 'CHANGE'.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'This display-only Data Browser does not provide table mutation.' ) ).
      RETURN.
    ENDIF.
    IF is_context-screen = screen_table_name AND is_context-ucomm = 'SELECTION'.
      lv_table = value_of( it_values = ct_values
                           iv_name   = 'P_TABLE' ).
      lv_index = index_of_table( lv_table ).
      IF lv_index = 0.
        io_session->message( VALUE #(
          type  = zif_gg_session_types_v1=>message_type_error
          text  = 'Table is unknown or not permitted by the data-access policy.'
          field = 'P_TABLE' ) ).
        RETURN.
      ENDIF.
      io_session->get_dialog( )->set_next_screen( criteria_screen( lv_index ) ).
      io_session->get_dialog( )->leave_screen( ).
      RETURN.
    ENDIF.
    IF is_context-ucomm = 'EXECUTE'.
      lv_index = index_of_screen( is_context-screen ).
      IF lv_index = 0 OR is_context-screen <> criteria_screen( lv_index ).
        io_session->message( VALUE #(
          type = zif_gg_session_types_v1=>message_type_error
          text = 'Execute is only available on a generated selection screen.' ) ).
        RETURN.
      ENDIF.
      lt_tables = permitted_tables( ).
      READ TABLE lt_tables INTO lv_table INDEX lv_index.
      DATA(lt_fields) = lo_service->zif_gg_table_data_service_v1~get_fields( lv_table ).
      ls_criteria = collect_criteria( iv_index  = lv_index
                                      iv_table  = lv_table
                                      it_fields = lt_fields
                                      it_values = ct_values ).
      ls_result = lo_service->zif_gg_table_data_service_v1~read( ls_criteria ).
      IF ls_result-error IS NOT INITIAL.
        io_session->message( VALUE #(
          type  = zif_gg_session_types_v1=>message_type_error
          text  = ls_result-error
          field = CONV #( |P_T{ lv_index }_MAX| ) ) ).
        RETURN.
      ENDIF.
      put_result( EXPORTING iv_index  = lv_index
                            is_result = ls_result
                  CHANGING  ct_values = ct_values ).
      io_session->get_dialog( )->set_next_screen( result_screen( lv_index ) ).
      io_session->get_dialog( )->leave_screen( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    DATA(lo_service) = NEW zcl_gg_system_table_data( ).
    DATA(lo_dictionary) = NEW zcl_gg_system_dictionary( ).
    DATA lt_tables TYPE string_table.
    DATA lv_index TYPE i.
    DATA lv_table TYPE string.
    DATA lv_position TYPE i.

    IF is_context-field = 'P_TABLE'.
      LOOP AT permitted_tables( ) INTO lv_table.
        APPEND VALUE #( name = 'P_TABLE' value = lv_table ) TO rt_values.
      ENDLOOP.
      RETURN.
    ENDIF.
    lv_index = index_of_screen( is_context-screen ).
    IF lv_index = 0.
      RETURN.
    ENDIF.
    lt_tables = permitted_tables( ).
    READ TABLE lt_tables INTO lv_table INDEX lv_index.
    LOOP AT lo_service->zif_gg_table_data_service_v1~get_fields( lv_table ) INTO DATA(ls_field).
      lv_position = ls_field-position.
      IF ls_field-search_help IS INITIAL
          OR is_context-field <> CONV zif_gg_dynpro_types_v1=>ty_name( |P_T{ lv_index }_LOW{ lv_position }| ).
        CONTINUE.
      ENDIF.
      DATA(ls_element) = lo_dictionary->zif_gg_dictionary_service_v1~get_object(
        iv_object_type = zif_gg_system_types_v1=>ddic_data_element
        iv_name        = ls_field-data_element ).
      DATA(ls_help) = lo_dictionary->zif_gg_dictionary_service_v1~get_object(
        iv_object_type = zif_gg_system_types_v1=>ddic_domain
        iv_name        = ls_element-data_element-domain ).
      LOOP AT ls_help-domain-fixed_values INTO DATA(ls_fixed).
        APPEND VALUE #( name = is_context-field value = ls_fixed-value ) TO rt_values.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    IF is_context-field = 'P_TABLE'.
      rv_text = 'Only Dictionary tables permitted by the server data-access policy can be read.'.
      RETURN.
    ENDIF.
    rv_text = |The server builds the query from field metadata and enforces a hard maximum of { zcl_gg_system_table_data=>max_rows } rows.|.
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
