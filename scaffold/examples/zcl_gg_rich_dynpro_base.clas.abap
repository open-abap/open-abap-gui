CLASS zcl_gg_rich_dynpro_base DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

* Shared implementation for the dynpro examples 99-116. The host's typed
* builder and flow model are deliberately exercised by each mode.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string.

  PRIVATE SECTION.
    DATA mv_mode TYPE string.

    METHODS status_for
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1
        iv_screen  TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

    METHODS add_value
      IMPORTING
        iv_name   TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_value  TYPE string
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.

    METHODS add_cell
      IMPORTING
        iv_container TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_name      TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_row       TYPE i
        iv_value     TYPE string
      CHANGING
        ct_values    TYPE zif_gg_dynpro_types_v1=>ty_values.
ENDCLASS.

CLASS zcl_gg_rich_dynpro_base IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
  ENDMETHOD.

  METHOD add_value.
    INSERT VALUE #( name = iv_name value = iv_value ) INTO TABLE ct_values.
  ENDMETHOD.

  METHOD add_cell.
    INSERT VALUE #( container = iv_container name = iv_name row = iv_row value = iv_value ) INTO TABLE ct_values.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    DATA ls_position TYPE zif_gg_dynpro_types_v1=>ty_position.

    CASE mv_mode.
      WHEN '99'.
        io_builder->begin_screen( VALUE #( number = '0100' title = 'Control gallery 99' height = 220 ) ).
        io_builder->add_box( VALUE #( control = VALUE #( name = 'BOX' position = VALUE #( row = 1 column = 1 width = 560 height = 200 ) ) text = 'All basic dynpro controls' ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_INPUT' position = VALUE #( row = 20 column = 20 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
        io_builder->add_output_field( VALUE #( control = VALUE #( name = 'P_OUTPUT' position = VALUE #( row = 50 column = 20 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
        io_builder->add_text( VALUE #( control = VALUE #( name = 'P_TEXT' position = VALUE #( row = 80 column = 20 width = 180 ) ) text = 'Text control' ) ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_GO' position = VALUE #( row = 110 column = 20 width = 90 ) ) text = 'Apply' ucomm = 'GO' ) ).
        io_builder->add_checkbox( VALUE #( control = VALUE #( name = 'P_CHECK' position = VALUE #( row = 110 column = 130 width = 120 ) ) text = 'Enabled' ) ).
        io_builder->add_radiobutton( VALUE #( control = VALUE #( name = 'P_RADIO_A' position = VALUE #( row = 140 column = 20 width = 110 ) ) text = 'Alpha' group = 'G1' ) ).
        io_builder->add_radiobutton( VALUE #( control = VALUE #( name = 'P_RADIO_B' position = VALUE #( row = 140 column = 140 width = 110 ) ) text = 'Beta' group = 'G1' ) ).
        io_builder->add_listbox( VALUE #( control = VALUE #( name = 'P_LIST' position = VALUE #( row = 170 column = 20 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 10 ) fixed_values = VALUE #( ( key = 'A' text = 'Alpha' ) ( key = 'B' text = 'Beta' ) ) ) ).
        io_builder->end_screen( ).
      WHEN '100'.
        io_builder->begin_screen( VALUE #( number = '0100' title = 'PBO and PAI 100' height = 140 ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_INPUT' position = VALUE #( row = 20 column = 20 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
        io_builder->add_output_field( VALUE #( control = VALUE #( name = 'P_OUTPUT' position = VALUE #( row = 55 column = 20 width = 250 ) ) data_type = VALUE #( typ = 'C' length = 40 ) ) ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_APPLY' position = VALUE #( row = 90 column = 20 width = 90 ) ) text = 'Apply' ucomm = 'APPLY' ) ).
        io_builder->end_screen( ).
      WHEN '101'.
        io_builder->begin_screen( VALUE #( number = '0100' title = 'Cursor error 101' height = 150 ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_GOOD' position = VALUE #( row = 20 column = 20 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_BAD' position = VALUE #( row = 55 column = 20 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 20 ) required = abap_true ) ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_VALIDATE' position = VALUE #( row = 90 column = 20 width = 100 ) ) text = 'Validate' ucomm = 'VALIDATE' ) ).
        io_builder->end_screen( ).
      WHEN '102'.
        io_builder->begin_screen( VALUE #( number = '0100' title = 'POV and POH 102' height = 120 ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_VALUE' position = VALUE #( row = 20 column = 20 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 30 ) value_help = abap_true search_help = 'ZGG_DYNPRO_HELP' ) ).
        io_builder->end_screen( ).
      WHEN '103'.
        io_builder->begin_screen( VALUE #( number = '0100' title = 'Dynamic states 103' height = 140 ) ).
        io_builder->add_checkbox( VALUE #( control = VALUE #( name = 'P_ENABLE' position = VALUE #( row = 20 column = 20 width = 130 ) ) text = 'Enable detail' ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_DEP' position = VALUE #( row = 60 column = 20 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 25 ) ) ).
        io_builder->end_screen( ).
      WHEN '104'.
        io_builder->begin_screen( VALUE #( number = '0100' title = 'CHAIN validation 104' height = 140 ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_LEFT' position = VALUE #( row = 20 column = 20 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_RIGHT' position = VALUE #( row = 55 column = 20 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CHECK' position = VALUE #( row = 90 column = 20 width = 100 ) ) text = 'Check' ucomm = 'CHECK' ) ).
        io_builder->end_screen( ).
      WHEN '105' OR '106' OR '107'.
        io_builder->begin_screen( VALUE #( number = '0100' title = |Table control { mv_mode }| height = 240 ) ).
        io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_FLIGHTS' position = VALUE #( row = 20 column = 20 width = 460 height = 150 ) ) visible_rows = 3 selection_mode = 'SINGLE' with_hscroll = abap_true with_vscroll = abap_true ) ).
        io_builder->add_table_column( VALUE #( table_control = 'TC_FLIGHTS' name = 'CARRID' title = 'Carrier' width = 90 input = xsdbool( mv_mode = '106' ) required = xsdbool( mv_mode = '106' ) data_type = VALUE #( typ = 'C' length = 3 ) ) ).
        io_builder->add_table_column( VALUE #( table_control = 'TC_FLIGHTS' name = 'CITY' title = 'City' width = 160 input = xsdbool( mv_mode = '106' ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->end_table_control( ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_TABLE' position = VALUE #( row = 190 column = 20 width = 100 ) ) text = 'Continue' ucomm = 'CONTINUE' ) ).
        io_builder->end_screen( ).
      WHEN '108'.
        io_builder->begin_screen( VALUE #( number = '0100' title = 'Parent 108' height = 130 ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_PARENT' position = VALUE #( row = 20 column = 20 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->add_subscreen_area( VALUE #( control = VALUE #( name = 'SUB_AREA' position = VALUE #( row = 55 column = 20 width = 260 height = 50 ) ) ) ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_NEXT' position = VALUE #( row = 105 column = 20 width = 100 ) ) text = 'Continue' ucomm = 'NEXT' ) ).
        io_builder->end_screen( ).
        io_builder->begin_screen( VALUE #( number = '0200' title = 'Subscreen 108' height = 130 ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_CHILD' position = VALUE #( row = 20 column = 20 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->end_screen( ).
      WHEN '109'.
        io_builder->begin_screen( VALUE #( number = '0100' title = 'Tabs 109' height = 150 ) ).
        io_builder->add_tabstrip( VALUE #( control = VALUE #( name = 'TABSTRIP' position = VALUE #( row = 10 column = 10 width = 400 height = 100 ) ) ucomm = 'TAB' ) ).
        io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_ONE' ) tabstrip = 'TABSTRIP' text = 'One' subscreen = '0200' ucomm = 'TAB_ONE' ) ).
        io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_TWO' ) tabstrip = 'TABSTRIP' text = 'Two' subscreen = '0300' ucomm = 'TAB_TWO' ) ).
        io_builder->end_screen( ).
        io_builder->begin_screen( VALUE #( number = '0200' title = 'Tab one 109' height = 120 ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_TAB_ONE' position = VALUE #( row = 20 column = 20 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->end_screen( ).
        io_builder->begin_screen( VALUE #( number = '0300' title = 'Tab two 109' height = 120 ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_TAB_TWO' position = VALUE #( row = 20 column = 20 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->end_screen( ).
      WHEN '110'.
        io_builder->begin_screen( VALUE #( number = '0100' title = 'Parent modal 110' height = 130 ) ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_OPEN' position = VALUE #( row = 20 column = 20 width = 110 ) ) text = 'Open dialog' ucomm = 'OPEN' ) ).
        io_builder->end_screen( ).
        io_builder->begin_screen( VALUE #( number = '0200' title = 'Modal dialog 110' modal = abap_true width = 300 height = 160 ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_DIALOG' position = VALUE #( row = 20 column = 20 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->end_screen( ).
      WHEN '111'.
        io_builder->begin_screen( VALUE #( number = '0100' title = 'Nested parent 111' height = 130 ) ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_OPEN' position = VALUE #( row = 20 column = 20 width = 110 ) ) text = 'Open first' ucomm = 'OPEN1' ) ).
        io_builder->end_screen( ).
        io_builder->begin_screen( VALUE #( number = '0200' title = 'Nested first 111' modal = abap_true height = 130 ) ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_OPEN2' position = VALUE #( row = 20 column = 20 width = 120 ) ) text = 'Open second' ucomm = 'OPEN2' ) ).
        io_builder->end_screen( ).
        io_builder->begin_screen( VALUE #( number = '0300' title = 'Nested second 111' modal = abap_true height = 130 ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_NESTED' position = VALUE #( row = 20 column = 20 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->end_screen( ).
      WHEN '112'.
        io_builder->begin_screen( VALUE #( number = '0100' title = 'Screen scheduling 112' height = 140 ) ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_NEXT' position = VALUE #( row = 20 column = 20 width = 100 ) ) text = 'Set next' ucomm = 'NEXT' ) ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_JUMP' position = VALUE #( row = 55 column = 20 width = 100 ) ) text = 'Jump now' ucomm = 'JUMP' ) ).
        io_builder->end_screen( ).
        io_builder->begin_screen( VALUE #( number = '0200' title = 'Scheduled screen 112' height = 120 ) ).
        io_builder->add_text( VALUE #( control = VALUE #( name = 'P_SCREEN' position = VALUE #( row = 20 column = 20 width = 180 ) ) text = 'Reached screen 0200' ) ).
        io_builder->end_screen( ).
      WHEN '113' OR '114' OR '115'.
        io_builder->begin_screen( VALUE #( number = '0100' title = |Flow semantics { mv_mode }| height = 150 ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_MESSAGE' position = VALUE #( row = 20 column = 20 width = 230 ) ) data_type = VALUE #( typ = 'C' length = 25 ) ) ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_ACTION' position = VALUE #( row = 60 column = 20 width = 100 ) ) text = 'Action' ucomm = 'ACTION' ) ).
        io_builder->end_screen( ).
        IF mv_mode = '115'.
          io_builder->begin_screen( VALUE #( number = '0200' title = 'Second status 115' height = 130 ) ).
          io_builder->add_text( VALUE #( control = VALUE #( name = 'P_SECOND' position = VALUE #( row = 20 column = 20 width = 200 ) ) text = 'Second screen owns its status' ) ).
          io_builder->end_screen( ).
        ENDIF.
      WHEN '116'.
        io_builder->begin_screen( VALUE #( number = '0100' title = 'Flight header editor' height = 140 ) ).
        io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_CARRIER' position = VALUE #( row = 20 column = 20 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 3 ) value_help = abap_true ) ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_EDIT' position = VALUE #( row = 60 column = 20 width = 100 ) ) text = 'Edit rows' ucomm = 'EDIT' ) ).
        io_builder->end_screen( ).
        io_builder->begin_screen( VALUE #( number = '0200' title = 'Flight rows editor' height = 230 ) ).
        io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_ROWS' position = VALUE #( row = 20 column = 20 width = 430 height = 150 ) ) visible_rows = 2 selection_mode = 'SINGLE' with_vscroll = abap_true ) ).
        io_builder->add_table_column( VALUE #( table_control = 'TC_ROWS' name = 'CONN' title = 'Connection' width = 120 input = abap_true data_type = VALUE #( typ = 'C' length = 5 ) ) ).
        io_builder->add_table_column( VALUE #( table_control = 'TC_ROWS' name = 'CITY' title = 'City' width = 180 input = abap_true data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->end_table_control( ).
        io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_SAVE' position = VALUE #( row = 190 column = 20 width = 100 ) ) text = 'Save' ucomm = 'SAVE' ) ).
        io_builder->end_screen( ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_flow_logic.
    DATA lt_screens TYPE STANDARD TABLE OF zif_gg_dynpro_types_v1=>ty_screen_number WITH DEFAULT KEY.
    lt_screens = VALUE #( ( '0100' ) ).
    IF mv_mode = '108' OR mv_mode = '109' OR mv_mode = '110' OR mv_mode = '111' OR mv_mode = '112' OR mv_mode = '115' OR mv_mode = '116'.
      APPEND '0200' TO lt_screens.
    ENDIF.
    IF mv_mode = '109' OR mv_mode = '111'.
      APPEND '0300' TO lt_screens.
    ENDIF.
    LOOP AT lt_screens INTO DATA(lv_screen).
      io_builder->begin_screen( lv_screen ).
      io_builder->begin_pbo( ).
      io_builder->add_module( VALUE #( name = 'PBO' ) ).
      io_builder->end_processing( ).
      io_builder->begin_pai( ).
      CASE mv_mode.
        WHEN '104'.
          io_builder->begin_chain( ).
          io_builder->add_field( 'P_LEFT' ).
          io_builder->add_field( 'P_RIGHT' ).
          io_builder->add_module( VALUE #( name = 'PAI' on_chain_input = abap_true ) ).
          io_builder->end_chain( ).
        WHEN '105' OR '106' OR '107' OR '116'.
          io_builder->begin_table_loop( VALUE #( table_control = COND #( WHEN mv_mode = '116' THEN 'TC_ROWS' ELSE 'TC_FLIGHTS' ) ) ).
          io_builder->add_module( VALUE #( name = 'PAI' on_input = abap_true ) ).
          io_builder->end_table_loop( ).
        WHEN OTHERS.
          io_builder->add_module( VALUE #( name = 'PAI' on_input = abap_true ) ).
      ENDCASE.
      io_builder->end_processing( ).
      IF mv_mode = '102' AND lv_screen = '0100'.
        io_builder->begin_value_request( 'P_VALUE' ).
        io_builder->add_module( VALUE #( name = 'POV' ) ).
        io_builder->end_processing( ).
        io_builder->begin_help_request( 'P_VALUE' ).
        io_builder->add_module( VALUE #( name = 'POH' ) ).
        io_builder->end_processing( ).
      ENDIF.
      IF mv_mode = '108' AND lv_screen = '0100'.
        io_builder->call_subscreen( VALUE #( area = 'SUB_AREA' program = 'ZGG_EX_108' screen = '0200' ) ).
      ENDIF.
      io_builder->end_screen( ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    CASE mv_mode.
      WHEN '99'.
        add_value( EXPORTING iv_name = 'P_INPUT'
                             iv_value = 'input' CHANGING ct_values = ct_values ).
        add_value( EXPORTING iv_name = 'P_OUTPUT'
                             iv_value = 'output' CHANGING ct_values = ct_values ).
        add_value( EXPORTING iv_name = 'P_CHECK'
                             iv_value = 'X' CHANGING ct_values = ct_values ).
        add_value( EXPORTING iv_name = 'P_RADIO_A'
                             iv_value = 'X' CHANGING ct_values = ct_values ).
        add_value( EXPORTING iv_name = 'P_LIST'
                             iv_value = 'A' CHANGING ct_values = ct_values ).
      WHEN '100'.
        add_value( EXPORTING iv_name = 'P_INPUT'
                             iv_value = 'initial' CHANGING ct_values = ct_values ).
        add_value( EXPORTING iv_name = 'P_OUTPUT'
                             iv_value = 'derived: initial' CHANGING ct_values = ct_values ).
      WHEN '101'.
        add_value( EXPORTING iv_name = 'P_GOOD'
                             iv_value = 'valid sibling' CHANGING ct_values = ct_values ).
        add_value( EXPORTING iv_name = 'P_BAD'
                             iv_value = `` CHANGING ct_values = ct_values ).
      WHEN '102'.
        add_value( EXPORTING iv_name = 'P_VALUE'
                             iv_value = `` CHANGING ct_values = ct_values ).
      WHEN '103'.
        add_value( EXPORTING iv_name = 'P_ENABLE'
                             iv_value = `` CHANGING ct_values = ct_values ).
        add_value( EXPORTING iv_name = 'P_DEP'
                             iv_value = 'retained' CHANGING ct_values = ct_values ).
      WHEN '104'.
        add_value( EXPORTING iv_name = 'P_LEFT'
                             iv_value = 'left' CHANGING ct_values = ct_values ).
        add_value( EXPORTING iv_name = 'P_RIGHT'
                             iv_value = 'right' CHANGING ct_values = ct_values ).
      WHEN '105' OR '106' OR '107'.
        add_cell( EXPORTING iv_container = 'TC_FLIGHTS'
                            iv_name = 'CARRID'
                            iv_row = 1
                            iv_value = 'AA' CHANGING ct_values = ct_values ).
        add_cell( EXPORTING iv_container = 'TC_FLIGHTS'
                            iv_name = 'CITY'
                            iv_row = 1
                            iv_value = 'Frankfurt' CHANGING ct_values = ct_values ).
        add_cell( EXPORTING iv_container = 'TC_FLIGHTS'
                            iv_name = 'CARRID'
                            iv_row = 2
                            iv_value = 'LH' CHANGING ct_values = ct_values ).
        add_cell( EXPORTING iv_container = 'TC_FLIGHTS'
                            iv_name = 'CITY'
                            iv_row = 2
                            iv_value = 'Berlin' CHANGING ct_values = ct_values ).
      WHEN '108'.
        add_value( EXPORTING iv_name = 'P_PARENT'
                             iv_value = 'parent' CHANGING ct_values = ct_values ).
        add_value( EXPORTING iv_name = 'P_CHILD'
                             iv_value = 'child' CHANGING ct_values = ct_values ).
      WHEN '109'.
        add_value( EXPORTING iv_name = 'P_TAB_ONE'
                             iv_value = 'one' CHANGING ct_values = ct_values ).
        add_value( EXPORTING iv_name = 'P_TAB_TWO'
                             iv_value = 'two' CHANGING ct_values = ct_values ).
      WHEN '110'.
        add_value( EXPORTING iv_name = 'P_DIALOG'
                             iv_value = 'modal value' CHANGING ct_values = ct_values ).
      WHEN '111'.
        add_value( EXPORTING iv_name = 'P_NESTED'
                             iv_value = 'nested value' CHANGING ct_values = ct_values ).
      WHEN '113' OR '114' OR '115'.
        add_value( EXPORTING iv_name = 'P_MESSAGE'
                             iv_value = `` CHANGING ct_values = ct_values ).
      WHEN '116'.
        add_value( EXPORTING iv_name = 'P_CARRIER'
                             iv_value = 'AA' CHANGING ct_values = ct_values ).
        add_cell( EXPORTING iv_container = 'TC_ROWS'
                            iv_name = 'CONN'
                            iv_row = 1
                            iv_value = '001' CHANGING ct_values = ct_values ).
        add_cell( EXPORTING iv_container = 'TC_ROWS'
                            iv_name = 'CITY'
                            iv_row = 1
                            iv_value = 'Frankfurt' CHANGING ct_values = ct_values ).
    ENDCASE.
  ENDMETHOD.

  METHOD status_for.
    DATA(lo_dialog) = io_session->get_dialog( ).
    lo_dialog->set_title( |ZCL_GG_EX_{ mv_mode }| ).
    CASE mv_mode.
      WHEN '99'.
        lo_dialog->set_status( VALUE #( status = 'CONTROLS' active_ucomm = VALUE #( ( 'GO' ) ) ) ).
      WHEN '100'.
        lo_dialog->set_status( VALUE #( status = 'PBO/PAI' active_ucomm = VALUE #( ( 'APPLY' ) ) icon_bar = VALUE #( ( ucomm = 'APPLY' label = 'Apply' icon = 'arrow-right' ) ) ) ).
      WHEN '101'.
        lo_dialog->set_status( VALUE #( status = 'VALIDATE' active_ucomm = VALUE #( ( 'VALIDATE' ) ) ) ).
      WHEN '103'.
        lo_dialog->set_status( VALUE #( status = 'DYNAMIC' active_ucomm = VALUE #( ( 'APPLY' ) ) ) ).
      WHEN '104'.
        lo_dialog->set_status( VALUE #( status = 'CHAIN' active_ucomm = VALUE #( ( 'CHECK' ) ) ) ).
      WHEN '105' OR '106' OR '107'.
        lo_dialog->set_status( VALUE #( status = 'TABLE' active_ucomm = VALUE #( ( 'CONTINUE' ) ) ) ).
      WHEN '108'.
        lo_dialog->set_status( VALUE #( status = |SCREEN { iv_screen }| active_ucomm = VALUE #( ( 'NEXT' ) ) ) ).
      WHEN '109' OR '110' OR '111' OR '112' OR '116'.
        lo_dialog->set_status( VALUE #( status = |SCREEN { iv_screen }| ) ).
      WHEN '113'.
        lo_dialog->set_status( VALUE #( status = 'BACK EXIT CANCEL' active_ucomm = VALUE #( ( 'BACK' ) ( 'EXIT' ) ( 'CANCEL' ) ) ) ).
      WHEN '114'.
        lo_dialog->set_status( VALUE #( status = 'MESSAGES' active_ucomm = VALUE #( ( 'ACTION' ) ) ) ).
      WHEN '115'.
        lo_dialog->set_status( VALUE #( status = |STATUS { iv_screen }| active_ucomm = VALUE #( ( 'ACTION' ) ( 'NEXT' ) ) active_pf_keys = VALUE #( ( 5 ) ) icon_bar = VALUE #( ( ucomm = 'ACTION' label = 'Action' icon = 'arrow-right' ) ) ) ).
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    status_for( io_session = io_session
                iv_screen  = is_context-screen ).
    CASE mv_mode.
      WHEN '100'.
        IF line_exists( ct_values[ name = 'P_INPUT' ] ) AND line_exists( ct_values[ name = 'P_OUTPUT' ] ).
          ct_values[ name = 'P_OUTPUT' ]-value = |derived: { ct_values[ name = 'P_INPUT' ]-value }|.
        ENDIF.
      WHEN '101'.
        io_session->get_dialog( )->set_cursor( VALUE #( field = 'P_BAD' ) ).
      WHEN '103'.
        IF line_exists( ct_values[ name = 'P_ENABLE' ] ) AND ct_values[ name = 'P_ENABLE' ]-value = 'X'.
          ct_states[ name = 'P_DEP' ]-visible = abap_true.
          ct_states[ name = 'P_DEP' ]-enabled = abap_true.
          ct_states[ name = 'P_DEP' ]-required = abap_true.
        ELSE.
          ct_states[ name = 'P_DEP' ]-visible = abap_false.
          ct_states[ name = 'P_DEP' ]-enabled = abap_false.
          ct_states[ name = 'P_DEP' ]-required = abap_false.
        ENDIF.
      WHEN '115'.
        IF is_context-screen = '0200'.
          io_session->get_dialog( )->set_status( VALUE #( status = 'STATUS-0200' active_ucomm = VALUE #( ( 'SAVE' ) ) excluded_ucomm = VALUE #( ( 'ACTION' ) ) ) ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA(lo_dialog) = io_session->get_dialog( ).
    CASE mv_mode.
      WHEN '100'.
        IF is_context-ucomm = 'APPLY'.
          ct_values[ name = 'P_OUTPUT' ]-value = |accepted: { ct_values[ name = 'P_INPUT' ]-value }|.
        ENDIF.
      WHEN '101'.
        IF is_context-ucomm = 'VALIDATE' AND ct_values[ name = 'P_BAD' ]-value IS INITIAL.
          io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_error text = 'P_BAD is invalid' field = 'P_BAD' ) ).
        ENDIF.
        IF is_context-ucomm = 'VALIDATE'.
          ct_values[ name = 'P_GOOD' ]-value = 'accepted sibling'.
        ENDIF.
      WHEN '104'.
        IF is_context-ucomm = 'CHECK' AND ct_values[ name = 'P_LEFT' ]-value <> ct_values[ name = 'P_RIGHT' ]-value.
          io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_error text = 'CHAIN values must match' field = 'P_RIGHT' ) ).
        ENDIF.
      WHEN '105' OR '106' OR '107'.
        IF is_context-ucomm = 'CONTINUE'.
          io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_success text = 'Table accepted' ) ).
        ENDIF.
      WHEN '108'.
        IF is_context-screen = '0100'.
          lo_dialog->set_next_screen( '0200' ).
          lo_dialog->leave_screen( ).
        ENDIF.
      WHEN '109'.
        CASE is_context-ucomm.
          WHEN 'TAB_TWO'.
            lo_dialog->set_next_screen( '0300' ).
            lo_dialog->leave_screen( ).
          WHEN 'TAB_ONE'.
            lo_dialog->set_next_screen( '0200' ).
            lo_dialog->leave_screen( ).
        ENDCASE.
      WHEN '110'.
        IF is_context-ucomm = 'OPEN'.
          lo_dialog->set_next_screen( '0200' ).
          lo_dialog->leave_screen( ).
        ENDIF.
      WHEN '111'.
        CASE is_context-ucomm.
          WHEN 'OPEN1'.
            lo_dialog->set_next_screen( '0200' ).
            lo_dialog->leave_screen( ).
          WHEN 'OPEN2'.
            lo_dialog->set_next_screen( '0300' ).
            lo_dialog->leave_screen( ).
        ENDCASE.
      WHEN '112'.
        CASE is_context-ucomm.
          WHEN 'NEXT'.
            lo_dialog->set_next_screen( '0200' ).
          WHEN 'JUMP'.
            lo_dialog->set_next_screen( '0200' ).
            lo_dialog->leave_screen( ).
        ENDCASE.
      WHEN '113'.
        CASE is_context-ucomm.
          WHEN 'BACK'.
            lo_dialog->leave_to_screen( '0000' ).
          WHEN 'EXIT'.
            io_session->get_navigation( )->leave_program( ).
          WHEN 'CANCEL'.
            io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_warning text = 'Cancelled' ) ).
        ENDCASE.
      WHEN '114'.
        IF is_context-ucomm = 'ACTION'.
          IF ct_values[ name = 'P_MESSAGE' ]-value IS INITIAL.
            io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_error text = 'Enter a message value' field = 'P_MESSAGE' ) ).
          ELSE.
            io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_warning text = 'Warning accepted' display_like = zif_gg_session_types_v1=>message_type_warning ) ).
          ENDIF.
        ENDIF.
      WHEN '115'.
        IF is_context-screen = '0100' AND is_context-ucomm = 'NEXT'.
          lo_dialog->set_next_screen( '0200' ).
          lo_dialog->leave_screen( ).
        ENDIF.
      WHEN '116'.
        IF is_context-screen = '0100' AND is_context-ucomm = 'EDIT'.
          lo_dialog->set_next_screen( '0200' ).
          lo_dialog->leave_screen( ).
        ELSEIF is_context-screen = '0200' AND is_context-ucomm = 'SAVE'.
          io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_success text = 'Flight saved' ) ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    CASE mv_mode.
      WHEN '102'.
        rt_values = VALUE #( ( name = 'P_VALUE' value = 'AA' ) ( name = 'P_VALUE' value = 'LH' ) ).
      WHEN '116'.
        rt_values = VALUE #( ( name = 'P_CARRIER' value = 'AA' ) ( name = 'P_CARRIER' value = 'LH' ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    CASE mv_mode.
      WHEN '102'.
        rv_text = 'Typed dynpro help for P_VALUE'.
      WHEN '116'.
        rv_text = 'Choose a carrier for the flight editor'.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
