CLASS zcl_gg_se38 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ABAP Editor. The initial screen chooses a program and one subobject; Display
* opens that subobject and Execute hands the resolved program to the report
* runtime. Missing, inactive, non-executable and unauthorized programs are
* reported with their own reason, and the entered program and subobject
* survive every rejection.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_transaction_v1.

  PRIVATE SECTION.
    CONSTANTS screen_initial TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0100'.
    CONSTANTS screen_source TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0200'.
    CONSTANTS screen_attributes TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0210'.
    CONSTANTS screen_documentation TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0220'.
    CONSTANTS screen_text_elements TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0230'.
    CONSTANTS screen_variants TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0240'.

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
    METHODS load_program
      IMPORTING
        iv_program        TYPE string
      RETURNING
        VALUE(rs_program) TYPE zif_gg_system_types_v1=>ty_program.
    TYPES: BEGIN OF ty_subobject,
             control TYPE zif_gg_dynpro_types_v1=>ty_name,
             text    TYPE string,
             screen  TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
           END OF ty_subobject.
    TYPES ty_subobjects TYPE STANDARD TABLE OF ty_subobject WITH DEFAULT KEY.

    "! Subobjects offered on the initial screen, in display order. The first
    "! entry is the default selection.
    METHODS subobjects
      RETURNING
        VALUE(rt_subobjects) TYPE ty_subobjects.
    METHODS selected_subobject
      IMPORTING
        it_values        TYPE zif_gg_dynpro_types_v1=>ty_values
      RETURNING
        VALUE(rv_screen) TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    METHODS execution_error
      IMPORTING
        is_program     TYPE zif_gg_system_types_v1=>ty_program
      RETURNING
        VALUE(rv_text) TYPE string.
    METHODS put_program
      IMPORTING
        is_program TYPE zif_gg_system_types_v1=>ty_program
      CHANGING
        ct_values  TYPE zif_gg_dynpro_types_v1=>ty_values.

ENDCLASS.

CLASS zcl_gg_se38 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'SE38' description = 'ABAP Editor' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = screen_initial.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = screen_initial title = 'ABAP Editor: Initial Screen' height = 430 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_PROGRAM' position = VALUE #( row = 18 column = 18 width = 145 ) ) text = 'Program' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_PROGRAM' position = VALUE #( row = 12 column = 175 width = 260 ) ) data_type = VALUE #( typ = 'C' length = 40 ) search_help = 'ABAP_PROGRAM' value_help = abap_true required = abap_true uppercase = abap_true ) ).
    io_builder->add_box( VALUE #( control = VALUE #( name = 'B_SUBOBJECT' position = VALUE #( row = 58 column = 18 width = 420 height = 190 ) ) text = 'Subobjects' ) ).
    LOOP AT subobjects( ) INTO DATA(ls_subobject).
      io_builder->add_radiobutton( VALUE #( control = VALUE #( name = ls_subobject-control position = VALUE #( row = 56 + sy-tabix * 32 column = 34 width = 240 ) ) text = ls_subobject-text group = 'SUB' ) ).
    ENDLOOP.
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'P_CAPABILITY' position = VALUE #( row = 268 column = 18 width = 620 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_DISPLAY' position = VALUE #( row = 320 column = 18 width = 96 ) ) text = 'Display' ucomm = 'DISPLAY' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_EXECUTE' position = VALUE #( row = 320 column = 124 width = 110 ) ) text = 'Execute (F8)' ucomm = 'EXECUTE' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CHANGE' position = VALUE #( row = 364 column = 18 width = 96 ) ) text = 'Change' ucomm = 'CHANGE' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CREATE' position = VALUE #( row = 364 column = 124 width = 96 ) ) text = 'Create' ucomm = 'CREATE' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_source title = 'ABAP Source Code' height = 390 ) ).
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
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_attributes title = 'Program Attributes' height = 300 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ATTR_PROGRAM' position = VALUE #( row = 18 column = 18 width = 130 ) ) text = 'Program' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ATTR_PROGRAM' position = VALUE #( row = 12 column = 155 width = 240 ) ) data_type = VALUE #( typ = 'C' length = 40 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ATTR_TYPE' position = VALUE #( row = 56 column = 18 width = 130 ) ) text = 'Program type' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ATTR_TYPE' position = VALUE #( row = 50 column = 155 width = 240 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ATTR_STATUS' position = VALUE #( row = 94 column = 18 width = 130 ) ) text = 'Status' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ATTR_STATUS' position = VALUE #( row = 88 column = 155 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ATTR_EXECUTABLE' position = VALUE #( row = 132 column = 18 width = 130 ) ) text = 'Executable' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ATTR_EXECUTABLE' position = VALUE #( row = 126 column = 155 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 10 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ATTR_DESCRIPTION' position = VALUE #( row = 170 column = 18 width = 130 ) ) text = 'Description' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ATTR_DESCRIPTION' position = VALUE #( row = 164 column = 155 width = 360 ) ) data_type = VALUE #( typ = 'C' length = 80 ) ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_documentation title = 'Program Documentation' height = 270 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DOCUMENTATION' position = VALUE #( row = 20 column = 18 width = 520 ) ) text = 'Documentation' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DOCUMENTATION' position = VALUE #( row = 56 column = 18 width = 520 height = 120 ) ) data_type = VALUE #( typ = 'C' length = 255 ) ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_text_elements title = 'Text Elements' height = 270 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TEXT_ELEMENTS' position = VALUE #( row = 20 column = 18 width = 520 ) ) text = 'Text Elements' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_TEXT_ELEMENTS' position = VALUE #( row = 56 column = 18 width = 520 height = 120 ) ) data_type = VALUE #( typ = 'C' length = 255 ) ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_variants title = 'Program Variants' height = 300 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_VARIANTS' position = VALUE #( row = 20 column = 18 width = 520 ) ) text = 'Variants of the selected program' ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_VARIANTS' position = VALUE #( row = 56 column = 18 width = 560 height = 130 ) ) visible_rows = 3 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_false ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_VARIANTS' name = 'VARIANT_NAME' title = 'Variant' data_type = VALUE #( typ = 'C' length = 30 ) width = 160 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_VARIANTS' name = 'VARIANT_TEXT' title = 'Description' data_type = VALUE #( typ = 'C' length = 60 ) width = 320 ) ).
    io_builder->end_table_control( ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_VARIANT_INFO' position = VALUE #( row = 206 column = 18 width = 560 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
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
    add_flow( io_builder = io_builder
              iv_screen  = screen_initial
              iv_field   = 'P_PROGRAM' ).
    add_flow( io_builder = io_builder
              iv_screen  = screen_source ).
    add_flow( io_builder = io_builder
              iv_screen  = screen_attributes ).
    add_flow( io_builder = io_builder
              iv_screen  = screen_documentation ).
    add_flow( io_builder = io_builder
              iv_screen  = screen_text_elements ).
    add_flow( io_builder = io_builder
              iv_screen  = screen_variants ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    put_value( EXPORTING iv_name = 'R_SOURCE'
                         iv_value = 'X' CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = 'Display-only deployment: source edits, activation, and debugging require a real repository backend.' CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    DATA(lo_service) = NEW zcl_gg_system_repository( ).
    DATA(ls_capabilities) = lo_service->zif_gg_program_repository_v1~get_capabilities( ).

    io_session->get_dialog( )->set_status( VALUE #(
      status       = 'SE38'
      active_ucomm = VALUE #( ( 'DISPLAY' ) ( 'EXECUTE' ) ( 'CHANGE' ) ( 'CREATE' ) ( 'SYNTAX' ) ( 'SAVE' ) ( 'ACTIVATE' ) ( 'DEBUG' ) ( 'ATTRIBUTES' ) ( 'DOCUMENTATION' ) ( 'TEXT_ELEMENTS' ) ) ) ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = ls_capabilities-explanation CHANGING ct_values = ct_values ).
    ct_states[ name = 'PB_CHANGE' ]-enabled = abap_false.
    ct_states[ name = 'PB_CREATE' ]-enabled = abap_false.
  ENDMETHOD.

  METHOD subobjects.
    rt_subobjects = VALUE #(
      ( control = 'R_SOURCE' text = 'Source Code' screen = screen_source )
      ( control = 'R_VARIANTS' text = 'Variants' screen = screen_variants )
      ( control = 'R_ATTRIBUTES' text = 'Attributes' screen = screen_attributes )
      ( control = 'R_DOCUMENTATION' text = 'Documentation' screen = screen_documentation )
      ( control = 'R_TEXT_ELEMENTS' text = 'Text Elements' screen = screen_text_elements ) ).
  ENDMETHOD.

  METHOD selected_subobject.
    DATA(lt_subobjects) = subobjects( ).

    rv_screen = lt_subobjects[ 1 ]-screen.
    LOOP AT lt_subobjects INTO DATA(ls_subobject).
      IF value_of( it_values = it_values
                   iv_name   = ls_subobject-control ) = 'X'.
        rv_screen = ls_subobject-screen.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD execution_error.
    IF is_program-status = zif_gg_system_types_v1=>program_inactive.
      rv_text = |Program { is_program-program } is inactive; activate it before execution.|.
      RETURN.
    ENDIF.
    IF is_program-executable = abap_false.
      rv_text = |Program { is_program-program } is a { is_program-program_type } and cannot be executed.|.
    ENDIF.
  ENDMETHOD.

  METHOD put_program.
    DATA lv_row TYPE i.

    LOOP AT is_program-source_lines INTO DATA(lv_line).
      IF sy-tabix > 6.
        EXIT.
      ENDIF.
      put_value( EXPORTING iv_name = CONV #( |O_LINE_{ sy-tabix WIDTH = 3 ALIGN = RIGHT PAD = '0' }| )
                           iv_value = |{ sy-tabix WIDTH = 3 ALIGN = RIGHT PAD = '0' } { lv_line }| CHANGING ct_values = ct_values ).
    ENDLOOP.
    lv_row = lines( is_program-source_lines ) + 1.
    WHILE lv_row <= 6.
      put_value( EXPORTING iv_name = CONV #( |O_LINE_{ lv_row WIDTH = 3 ALIGN = RIGHT PAD = '0' }| )
                           iv_value = `` CHANGING ct_values = ct_values ).
      lv_row = lv_row + 1.
    ENDWHILE.
    put_value( EXPORTING iv_name = 'O_ATTR_PROGRAM'
                         iv_value = is_program-program CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_ATTR_TYPE'
                         iv_value = is_program-program_type CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_ATTR_STATUS'
                         iv_value = is_program-status CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_ATTR_EXECUTABLE'
                         iv_value = COND string( WHEN is_program-executable = abap_true THEN 'Yes' ELSE 'No' ) CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_ATTR_DESCRIPTION'
                         iv_value = is_program-description CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_DOCUMENTATION'
                         iv_value = is_program-documentation CHANGING ct_values = ct_values ).
    CLEAR lv_row.
    put_value( EXPORTING iv_name = 'O_TEXT_ELEMENTS'
                         iv_value = `` CHANGING ct_values = ct_values ).
    LOOP AT is_program-text_elements INTO DATA(lv_text).
      IF sy-tabix = 1.
        put_value( EXPORTING iv_name = 'O_TEXT_ELEMENTS'
                             iv_value = lv_text CHANGING ct_values = ct_values ).
      ELSE.
        put_value( EXPORTING iv_name = 'O_TEXT_ELEMENTS'
                             iv_value = |{ value_of( it_values = ct_values iv_name = 'O_TEXT_ELEMENTS' ) }; { lv_text }| CHANGING ct_values = ct_values ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA(lo_service) = NEW zcl_gg_system_repository( ).
    DATA lv_program TYPE string.
    DATA lv_error TYPE string.
    DATA lv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    DATA ls_program TYPE zif_gg_system_types_v1=>ty_program.
    DATA lt_variants TYPE zif_gg_system_types_v1=>ty_variants.
    DATA lv_row TYPE i.

    IF is_context-ucomm = 'BACK'.
      IF is_context-screen = screen_initial.
        io_session->get_navigation( )->leave_program( ).
      ELSE.
        io_session->get_dialog( )->set_next_screen( screen_initial ).
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
        io_session->get_dialog( )->set_next_screen( screen_attributes ).
        io_session->get_dialog( )->leave_screen( ).
        RETURN.
      WHEN 'DOCUMENTATION'.
        io_session->get_dialog( )->set_next_screen( screen_documentation ).
        io_session->get_dialog( )->leave_screen( ).
        RETURN.
      WHEN 'TEXT_ELEMENTS'.
        io_session->get_dialog( )->set_next_screen( screen_text_elements ).
        io_session->get_dialog( )->leave_screen( ).
        RETURN.
      WHEN OTHERS.
        CLEAR lv_screen.
    ENDCASE.
    IF is_context-ucomm <> 'DISPLAY' AND is_context-ucomm <> 'EXECUTE'.
      RETURN.
    ENDIF.
    lv_program = value_of( it_values = ct_values
                           iv_name   = 'P_PROGRAM' ).
    ls_program = load_program( lv_program ).
    IF ls_program-error IS NOT INITIAL.
      io_session->message( VALUE #(
        type  = zif_gg_session_types_v1=>message_type_error
        text  = ls_program-error
        field = 'P_PROGRAM' ) ).
      RETURN.
    ENDIF.
    IF is_context-ucomm = 'DISPLAY'.
      put_program( EXPORTING is_program = ls_program
                   CHANGING  ct_values  = ct_values ).
      lv_screen = selected_subobject( ct_values ).
      IF lv_screen = screen_variants.
        lt_variants = lo_service->zif_gg_program_repository_v1~get_variants( ls_program-program ).
        LOOP AT lt_variants INTO DATA(ls_variant).
          lv_row = sy-tabix.
          put_cell( EXPORTING iv_container = 'TC_VARIANTS'
                              iv_name = 'VARIANT_NAME'
                              iv_row = lv_row
                              iv_value = ls_variant-name CHANGING ct_values = ct_values ).
          put_cell( EXPORTING iv_container = 'TC_VARIANTS'
                              iv_name = 'VARIANT_TEXT'
                              iv_row = lv_row
                              iv_value = ls_variant-description CHANGING ct_values = ct_values ).
        ENDLOOP.
        put_value( EXPORTING iv_name = 'O_VARIANT_INFO'
                             iv_value = |{ lines( lt_variants ) } variant(s) for { ls_program-program }.| CHANGING ct_values = ct_values ).
      ENDIF.
      io_session->get_dialog( )->set_next_screen( lv_screen ).
      io_session->get_dialog( )->leave_screen( ).
      RETURN.
    ENDIF.
    lv_error = execution_error( ls_program ).
    IF lv_error IS NOT INITIAL.
      io_session->message( VALUE #(
        type  = zif_gg_session_types_v1=>message_type_error
        text  = lv_error
        field = 'P_PROGRAM' ) ).
      RETURN.
    ENDIF.
    io_session->get_navigation( )->submit_and_return(
      is_submit       = VALUE #(
        program              = CONV #( ls_program-program )
        via_selection_screen = abap_true )
      is_continuation = VALUE #( id = 'SE38_EXECUTION' state = ls_program-program ) ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    DATA(lo_service) = NEW zcl_gg_system_repository( ).
    IF is_context-field = 'P_PROGRAM'.
      LOOP AT lo_service->zif_gg_program_repository_v1~get_program_names( ) INTO DATA(lv_program).
        APPEND VALUE #( name = 'P_PROGRAM' value = lv_program ) TO rt_values.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    IF is_context-field = 'P_PROGRAM'.
      rv_text = 'The repository resolves the program and its status.'
        && ` Missing, inactive, non-executable and unauthorized programs are reported separately.`.
    ENDIF.
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
