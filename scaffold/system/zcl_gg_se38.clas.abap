CLASS zcl_gg_se38 DEFINITION PUBLIC FINAL CREATE PUBLIC.

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
    METHODS add_flow
      IMPORTING io_builder TYPE REF TO zif_gg_dynpro_flow_builder_v1 iv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    METHODS load_program IMPORTING iv_program TYPE string RETURNING VALUE(rs_program) TYPE zif_gg_system_types_v1=>ty_program.

ENDCLASS.

CLASS zcl_gg_se38 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'SE38' description = 'ABAP Editor' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' title = 'ABAP Editor' height = 350 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_PROGRAM' position = VALUE #( row = 18 column = 18 width = 145 ) ) text = 'Program' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_PROGRAM' position = VALUE #( row = 12 column = 175 width = 260 ) ) data_type = VALUE #( typ = 'C' length = 40 ) search_help = 'ABAP_PROGRAM' value_help = abap_true required = abap_true uppercase = abap_true ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_SUBOBJECT' position = VALUE #( row = 58 column = 18 width = 145 ) ) text = 'Subobject' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_SUBOBJECT' position = VALUE #( row = 52 column = 175 width = 260 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_VARIANT' position = VALUE #( row = 98 column = 18 width = 145 ) ) text = 'Variant' ) ).
    io_builder->add_listbox( VALUE #( control = VALUE #( name = 'P_VARIANT' position = VALUE #( row = 92 column = 175 width = 260 ) ) data_type = VALUE #( typ = 'C' length = 14 ) fixed_values = VALUE #( ( key = 'DEFAULT' text = 'DEFAULT - Demo carrier LH' ) ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_EDITOR_INFO' position = VALUE #( row = 138 column = 18 width = 540 ) ) text = 'Display source and metadata from the server repository. Execute uses the normal report runtime.' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'P_CAPABILITY' position = VALUE #( row = 178 column = 18 width = 540 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_DISPLAY' position = VALUE #( row = 230 column = 18 width = 96 ) ) text = 'Display' ucomm = 'DISPLAY' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_EXECUTE' position = VALUE #( row = 230 column = 124 width = 96 ) ) text = 'Execute (F8)' ucomm = 'EXECUTE' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_WITH_VARIANT' position = VALUE #( row = 230 column = 230 width = 130 ) ) text = 'With Variant' ucomm = 'WITH_VARIANT' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CHANGE' position = VALUE #( row = 274 column = 18 width = 96 ) ) text = 'Change' ucomm = 'CHANGE' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CREATE' position = VALUE #( row = 274 column = 124 width = 96 ) ) text = 'Create' ucomm = 'CREATE' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0200' title = 'ABAP Source Code' height = 390 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_SOURCE' position = VALUE #( row = 12 column = 18 width = 540 ) ) text = 'Source Code - line numbers are supplied by the repository adapter.' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_LINE_001' position = VALUE #( row = 44 column = 18 width = 560 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_LINE_002' position = VALUE #( row = 78 column = 18 width = 560 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_LINE_003' position = VALUE #( row = 112 column = 18 width = 560 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_LINE_004' position = VALUE #( row = 146 column = 18 width = 560 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_LINE_005' position = VALUE #( row = 180 column = 18 width = 560 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_LINE_006' position = VALUE #( row = 214 column = 18 width = 560 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_SOURCE_CAPABILITY' position = VALUE #( row = 258 column = 18 width = 540 ) ) text = 'Editing, Save, and Activate are disabled until a real repository compiler is available.' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_ATTRIBUTES' position = VALUE #( row = 304 column = 18 width = 100 ) ) text = 'Attributes' ucomm = 'ATTRIBUTES' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_DOCUMENTATION' position = VALUE #( row = 304 column = 128 width = 125 ) ) text = 'Documentation' ucomm = 'DOCUMENTATION' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_TEXT_ELEMENTS' position = VALUE #( row = 304 column = 263 width = 120 ) ) text = 'Text Elements' ucomm = 'TEXT_ELEMENTS' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_VARIANTS' position = VALUE #( row = 304 column = 393 width = 95 ) ) text = 'Variants' ucomm = 'VARIANTS' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0210' title = 'Program Attributes' height = 270 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ATTR_PROGRAM' position = VALUE #( row = 18 column = 18 width = 130 ) ) text = 'Program' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ATTR_PROGRAM' position = VALUE #( row = 12 column = 155 width = 240 ) ) data_type = VALUE #( typ = 'C' length = 40 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ATTR_STATUS' position = VALUE #( row = 56 column = 18 width = 130 ) ) text = 'Status' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ATTR_STATUS' position = VALUE #( row = 50 column = 155 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ATTR_EXECUTABLE' position = VALUE #( row = 94 column = 18 width = 130 ) ) text = 'Executable' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ATTR_EXECUTABLE' position = VALUE #( row = 88 column = 155 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 10 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ATTR_DESCRIPTION' position = VALUE #( row = 132 column = 18 width = 130 ) ) text = 'Description' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ATTR_DESCRIPTION' position = VALUE #( row = 126 column = 155 width = 360 ) ) data_type = VALUE #( typ = 'C' length = 80 ) ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0220' title = 'Program Documentation' height = 270 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DOCUMENTATION' position = VALUE #( row = 20 column = 18 width = 520 ) ) text = 'Documentation' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DOCUMENTATION' position = VALUE #( row = 56 column = 18 width = 520 height = 120 ) ) data_type = VALUE #( typ = 'C' length = 255 ) ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0230' title = 'Text Elements' height = 270 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TEXT_ELEMENTS' position = VALUE #( row = 20 column = 18 width = 520 ) ) text = 'Text Elements' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_TEXT_ELEMENTS' position = VALUE #( row = 56 column = 18 width = 520 height = 120 ) ) data_type = VALUE #( typ = 'C' length = 255 ) ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0240' title = 'Program Variants' height = 270 ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_VARIANTS' position = VALUE #( row = 20 column = 18 width = 540 height = 100 ) ) visible_rows = 3 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_false ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_VARIANTS' name = 'VARIANT_NAME' title = 'Variant' data_type = VALUE #( typ = 'C' length = 14 ) width = 130 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_VARIANTS' name = 'VARIANT_TEXT' title = 'Description' data_type = VALUE #( typ = 'C' length = 60 ) width = 350 ) ).
    io_builder->end_table_control( ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_SELECT_VARIANT' position = VALUE #( row = 156 column = 18 width = 120 ) ) text = 'Use DEFAULT' ucomm = 'USE_DEFAULT' ) ).
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
    add_flow( io_builder = io_builder iv_screen = '0210' ).
    add_flow( io_builder = io_builder iv_screen = '0220' ).
    add_flow( io_builder = io_builder iv_screen = '0230' ).
    add_flow( io_builder = io_builder iv_screen = '0240' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    put_value( EXPORTING iv_name = 'P_CAPABILITY' iv_value = 'Display-only deployment: source edits, activation, and debugging require a real repository backend.' CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    DATA(lo_service) = NEW zcl_gg_system_repository( ).
    DATA(ls_capabilities) = lo_service->zif_gg_program_repository_v1~get_capabilities( ).

    io_session->get_dialog( )->set_status( VALUE #(
      status = 'SE38'
      active_ucomm = VALUE #( ( 'DISPLAY' ) ( 'EXECUTE' ) ( 'WITH_VARIANT' ) ( 'CHANGE' ) ( 'CREATE' ) ( 'SYNTAX' ) ( 'SAVE' ) ( 'ACTIVATE' ) ( 'DEBUG' ) ( 'ATTRIBUTES' ) ( 'DOCUMENTATION' ) ( 'TEXT_ELEMENTS' ) ( 'VARIANTS' ) ( 'USE_DEFAULT' ) ) ) ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY' iv_value = ls_capabilities-explanation CHANGING ct_values = ct_values ).
    ct_states[ name = 'PB_CHANGE' ]-enabled = abap_false.
    ct_states[ name = 'PB_CREATE' ]-enabled = abap_false.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA(lo_service) = NEW zcl_gg_system_repository( ).
    DATA lv_program TYPE string.
    DATA lv_variant TYPE string.
    DATA ls_program TYPE zif_gg_system_types_v1=>ty_program.
    DATA lt_variants TYPE zif_gg_system_types_v1=>ty_variants.

    IF is_context-ucomm = 'BACK'.
      IF is_context-screen = '0100'.
        io_session->get_navigation( )->leave_program( ).
      ELSE.
        io_session->get_dialog( )->set_next_screen( '0100' ).
        io_session->get_dialog( )->leave_screen( ).
      ENDIF.
      RETURN.
    ENDIF.
    IF is_context-ucomm = 'CHANGE' OR is_context-ucomm = 'CREATE'
        OR is_context-ucomm = 'SYNTAX' OR is_context-ucomm = 'SAVE'
        OR is_context-ucomm = 'ACTIVATE' OR is_context-ucomm = 'DEBUG'.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'This display-only deployment does not provide editing, activation, syntax check, or debugging.' ) ).
      RETURN.
    ENDIF.
    CASE is_context-ucomm.
      WHEN 'ATTRIBUTES'.
        io_session->get_dialog( )->set_next_screen( '0210' ).
        io_session->get_dialog( )->leave_screen( ).
        RETURN.
      WHEN 'DOCUMENTATION'.
        io_session->get_dialog( )->set_next_screen( '0220' ).
        io_session->get_dialog( )->leave_screen( ).
        RETURN.
      WHEN 'TEXT_ELEMENTS'.
        io_session->get_dialog( )->set_next_screen( '0230' ).
        io_session->get_dialog( )->leave_screen( ).
        RETURN.
      WHEN 'VARIANTS'.
        io_session->get_dialog( )->set_next_screen( '0240' ).
        io_session->get_dialog( )->leave_screen( ).
        RETURN.
      WHEN 'USE_DEFAULT'.
        put_value( EXPORTING iv_name = 'P_VARIANT' iv_value = 'DEFAULT' CHANGING ct_values = ct_values ).
        io_session->get_dialog( )->set_next_screen( '0100' ).
        io_session->get_dialog( )->leave_screen( ).
        RETURN.
    ENDCASE.
    lv_program = value_of( it_values = ct_values iv_name = 'P_PROGRAM' ).
    IF is_context-ucomm = 'DISPLAY' OR is_context-ucomm = 'EXECUTE' OR is_context-ucomm = 'WITH_VARIANT'.
      ls_program = load_program( lv_program ).
      IF ls_program-error IS NOT INITIAL.
        io_session->message( VALUE #(
          type = zif_gg_session_types_v1=>message_type_error
          text = ls_program-error
          field = 'P_PROGRAM' ) ).
        RETURN.
      ENDIF.
    ENDIF.
    IF is_context-ucomm = 'DISPLAY'.
      LOOP AT ls_program-source_lines INTO DATA(lv_line).
        IF sy-tabix > 6.
          EXIT.
        ENDIF.
        put_value( EXPORTING iv_name = CONV #( |O_LINE_{ sy-tabix WIDTH = 3 ALIGN = RIGHT PAD = '0' }| ) iv_value = |{ sy-tabix WIDTH = 3 ALIGN = RIGHT PAD = '0' } { lv_line }| CHANGING ct_values = ct_values ).
      ENDLOOP.
      put_value( EXPORTING iv_name = 'O_ATTR_PROGRAM' iv_value = ls_program-program CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_ATTR_STATUS' iv_value = ls_program-status CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_ATTR_EXECUTABLE' iv_value = COND string( WHEN ls_program-executable = abap_true THEN 'Yes' ELSE 'No' ) CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_ATTR_DESCRIPTION' iv_value = ls_program-description CHANGING ct_values = ct_values ).
      put_value( EXPORTING iv_name = 'O_DOCUMENTATION' iv_value = ls_program-documentation CHANGING ct_values = ct_values ).
      LOOP AT ls_program-text_elements INTO DATA(lv_text).
        IF sy-tabix = 1.
          put_value( EXPORTING iv_name = 'O_TEXT_ELEMENTS' iv_value = lv_text CHANGING ct_values = ct_values ).
        ELSE.
          put_value( EXPORTING iv_name = 'O_TEXT_ELEMENTS' iv_value = |{ value_of( it_values = ct_values iv_name = 'O_TEXT_ELEMENTS' ) }; { lv_text }| CHANGING ct_values = ct_values ).
        ENDIF.
      ENDLOOP.
      lt_variants = lo_service->zif_gg_program_repository_v1~get_variants( lv_program ).
      LOOP AT lt_variants INTO DATA(ls_variant).
        put_value( EXPORTING iv_name = 'P_VARIANT' iv_value = ls_variant-name CHANGING ct_values = ct_values ).
      ENDLOOP.
      io_session->get_dialog( )->set_next_screen( '0200' ).
      io_session->get_dialog( )->leave_screen( ).
      RETURN.
    ENDIF.
    IF is_context-ucomm = 'EXECUTE' OR is_context-ucomm = 'WITH_VARIANT'.
      lv_variant = value_of( it_values = ct_values iv_name = 'P_VARIANT' ).
      IF is_context-ucomm = 'WITH_VARIANT' AND lv_variant IS INITIAL.
        io_session->message( VALUE #(
          type = zif_gg_session_types_v1=>message_type_error
          text = 'Select a compatible program variant before execution.'
          field = 'P_VARIANT' ) ).
        RETURN.
      ENDIF.
      IF lv_variant IS NOT INITIAL.
        lt_variants = lo_service->zif_gg_program_repository_v1~get_variants( lv_program ).
        IF NOT line_exists( lt_variants[ name = lv_variant ] ).
          io_session->message( VALUE #(
            type = zif_gg_session_types_v1=>message_type_error
            text = 'Variant is unknown or incompatible with the selected program.'
            field = 'P_VARIANT' ) ).
          RETURN.
        ENDIF.
      ENDIF.
      io_session->get_navigation( )->submit_and_return(
        is_submit = VALUE #(
          program = 'ZGG_EX_015'
          variant = CONV #( lv_variant )
          via_selection_screen = abap_true
          values = COND #( WHEN lv_variant = 'DEFAULT'
                           THEN VALUE #( ( name = 'P_CARR' value = 'LH' ) ) ) )
        is_continuation = VALUE #( id = 'SE38_EXECUTION' state = lv_program ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    DATA(lo_service) = NEW zcl_gg_system_repository( ).
    CASE is_context-field.
      WHEN 'P_PROGRAM'.
        LOOP AT lo_service->zif_gg_program_repository_v1~get_program_names( ) INTO DATA(lv_program).
          APPEND VALUE #( name = 'P_PROGRAM' value = lv_program ) TO rt_values.
        ENDLOOP.
      WHEN 'P_VARIANT'.
        LOOP AT lo_service->zif_gg_program_repository_v1~get_variants( value_of( it_values = it_values iv_name = 'P_PROGRAM' ) ) INTO DATA(ls_variant).
          APPEND VALUE #( name = 'P_VARIANT' value = ls_variant-name ) TO rt_values.
        ENDLOOP.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    CASE is_context-field.
      WHEN 'P_PROGRAM'.
        rv_text = 'Only executable programs resolved by the repository adapter can be displayed or executed.'.
      WHEN 'P_VARIANT'.
        rv_text = 'Variants are checked against the selected program on the server before execution.'.
    ENDCASE.
  ENDMETHOD.

  METHOD load_program.
    DATA(lo_service) = NEW zcl_gg_system_repository( ).
    rs_program = lo_service->zif_gg_program_repository_v1~get_program( iv_program ).
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

ENDCLASS.
