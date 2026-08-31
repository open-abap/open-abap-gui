CLASS zcl_gg_rich_selection_base DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

* Shared implementation for the rich selection-screen examples 71-82.
* The numbered classes only provide transaction metadata and a feature mode;
* all callbacks still run through the public report contract.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string.

  PRIVATE SECTION.
    DATA mv_mode TYPE string.
    DATA mv_order TYPE string.

    METHODS add_order
      IMPORTING
        iv_value TYPE string.

    METHODS stop_with_message
      IMPORTING
        iv_text    TYPE string
        io_session TYPE REF TO zif_gg_session_v1.

    METHODS range_text
      IMPORTING
        is_range       TYPE zif_gg_selection_screen_types=>ty_range
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_gg_rich_selection_base IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
  ENDMETHOD.

  METHOD add_order.
    IF mv_order IS INITIAL.
      mv_order = iv_value.
    ELSE.
      mv_order = mv_order && `>` && iv_value.
    ENDIF.
  ENDMETHOD.

  METHOD stop_with_message.
    io_session->message( VALUE #(
      type = zif_gg_session_types_v1=>message_type_warning
      text = iv_text ) ).
  ENDMETHOD.

  METHOD range_text.
    rv_text = |{ is_range-sign } { is_range-option } { is_range-low }|.
    IF is_range-high IS NOT INITIAL.
      rv_text = rv_text && | - { is_range-high }|.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    CASE mv_mode.
      WHEN '71'.
        io_builder->add_listbox( VALUE #(
          name         = 'P_CARRIER'
          text         = 'Carrier'
          default      = 'AA'
          data_type    = VALUE #( typ = 'C' length = 2 )
          fixed_values = VALUE #(
            ( key = 'AA' text = 'Alpha Air' )
            ( key = 'LH' text = 'Lufthansa' ) ) ) ).
        io_builder->add_listbox( VALUE #(
          name         = 'P_CONNECTION'
          text         = 'Connection'
          obligatory   = abap_true
          data_type    = VALUE #( typ = 'C' length = 5 )
          fixed_values = VALUE #(
            ( key = 'AA-1' text = 'AA-1' )
            ( key = 'AA-2' text = 'AA-2' ) ) ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_REQUIRED'
          text      = 'Required'
          obligatory = abap_true
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
      WHEN '72'.
        io_builder->add_select_option( VALUE #(
          name      = 'S_CARRIER'
          text      = 'Carrier range'
          data_type = VALUE #( typ = 'C' length = 3 )
          no_extension = abap_true ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_REQUIRED'
          text      = 'Required'
          obligatory = abap_true
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
      WHEN '73'.
        io_builder->add_select_option( VALUE #(
          name      = 'S_MULTI'
          text      = 'Multiple ranges'
          data_type = VALUE #( typ = 'C' length = 8 )
          default   = VALUE #( sign = 'I' option = 'EQ' low = 'AA' ) ) ).
        io_builder->add_pushbutton( VALUE #(
          name = 'PB_ADD' text = 'Add range' ucomm = 'RANGE_ADD' ) ).
        io_builder->add_pushbutton( VALUE #(
          name = 'PB_REMOVE' text = 'Remove range' ucomm = 'RANGE_REMOVE' ) ).
        io_builder->add_pushbutton( VALUE #(
          name = 'PB_UP' text = 'Move first up' ucomm = 'RANGE_UP' ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_REQUIRED'
          text      = 'Required'
          obligatory = abap_true
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
      WHEN '74'.
        io_builder->add_select_option( VALUE #(
          name         = 'S_MULTI'
          text         = 'Flight choices'
          data_type    = VALUE #( typ = 'C' length = 8 )
          value_help   = abap_true
          no_extension = abap_true ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_REQUIRED'
          text      = 'Required'
          obligatory = abap_true
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
      WHEN '75'.
        io_builder->begin_tabbed_block( VALUE #( name = 'TB' lines = 5 ) ).
        io_builder->add_tab( VALUE #(
          name = 'TAB_GENERAL' text = 'General' subscreen = '0100' ucomm = 'UT1' ) ).
        io_builder->add_tab( VALUE #(
          name = 'TAB_DETAILS' text = 'Details' subscreen = '0200' ucomm = 'UT2' ) ).
        io_builder->end_tabbed_block( ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_GENERAL'
          text      = 'General value'
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_DETAILS'
          text      = 'Detail value'
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_REQUIRED'
          text      = 'Required'
          obligatory = abap_true
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
      WHEN '76'.
        io_builder->add_parameter( VALUE #(
          name      = 'P_DERIVED'
          text      = 'Derived value'
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->add_pushbutton( VALUE #(
          name = 'PB_DERIVE' text = 'Derive' ucomm = 'DERIVE' ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_REQUIRED'
          text      = 'Required'
          obligatory = abap_true
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
      WHEN '77'.
        io_builder->add_function_key( VALUE #( number = 1 text = 'Alpha action' ucomm = 'FC01' ) ).
        io_builder->add_function_key( VALUE #( number = 2 text = 'Beta action' ucomm = 'FC02' ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_ACTION'
          text      = 'Action'
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_REQUIRED'
          text      = 'Required'
          obligatory = abap_true
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
      WHEN '78'.
        io_builder->add_parameter( VALUE #(
          name       = 'P_CARRIER'
          text       = 'Carrier'
          value_help = abap_true
          data_type = VALUE #( typ = 'C' length = 2 ) ) ).
        io_builder->add_select_option( VALUE #(
          name       = 'S_RANGE'
          text       = 'Range'
          value_help = abap_true
          data_type  = VALUE #( typ = 'C' length = 3 ) ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_REQUIRED'
          text      = 'Required'
          obligatory = abap_true
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
      WHEN '79'.
        io_builder->add_parameter( VALUE #(
          name        = 'P_HELP'
          text        = 'Field with help'
          search_help = 'ZGG_HELP'
          data_type   = VALUE #( typ = 'C' length = 30 ) ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_REQUIRED'
          text      = 'Required'
          obligatory = abap_true
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
      WHEN '80'.
        io_builder->add_parameter( VALUE #(
          name      = 'P_FIELD'
          text      = 'Field'
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->begin_block( VALUE #( name = 'B_VALIDATE' title = 'Validation' with_frame = abap_true ) ).
        io_builder->add_radiobutton( VALUE #(
          name = 'P_RADIO' text = 'Radio' radio_group = 'VG1' default = abap_true ) ).
        io_builder->end_block( ).
        io_builder->add_select_option( VALUE #(
          name      = 'S_END'
          text      = 'End range'
          data_type = VALUE #( typ = 'C' length = 5 )
          default   = VALUE #( sign = 'I' option = 'EQ' low = 'ok' ) ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_REQUIRED'
          text      = 'Required'
          obligatory = abap_true
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
      WHEN '81'.
        io_builder->add_parameter( VALUE #(
          name      = 'P_GOOD'
          text      = 'Good value'
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_BAD'
          text      = 'Failing value'
          obligatory = abap_true
          data_type = VALUE #( typ = 'C' length = 20 ) ) ).
      WHEN '82'.
        io_builder->add_parameter( VALUE #(
          name      = 'P_NAME'
          text      = 'Variant name'
          obligatory = abap_true
          data_type = VALUE #( typ = 'C' length = 14 ) ) ).
        io_builder->add_parameter( VALUE #(
          name      = 'P_VALUE'
          text      = 'Variant value'
          data_type = VALUE #( typ = 'C' length = 30 ) ) ).
        io_builder->add_pushbutton( VALUE #( name = 'PB_SAVE' text = 'Save' ucomm = 'VAR_SAVE' ) ).
        io_builder->add_pushbutton( VALUE #( name = 'PB_LOAD' text = 'Load' ucomm = 'VAR_LOAD' ) ).
        io_builder->add_pushbutton( VALUE #( name = 'PB_DELETE' text = 'Delete' ucomm = 'VAR_DELETE' ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    IF mv_mode = '80'.
      CLEAR mv_order.
    ENDIF.
    IF mv_mode = '71'.
      IF ct_values[ name = 'P_CARRIER' ]-value = 'LH'.
        ct_states[ name = 'P_CONNECTION' ]-fixed_values = VALUE #(
          ( key = 'LH-1' text = 'LH-1' )
          ( key = 'LH-2' text = 'LH-2' ) ).
      ELSE.
        ct_states[ name = 'P_CONNECTION' ]-fixed_values = VALUE #(
          ( key = 'AA-1' text = 'AA-1' )
          ( key = 'AA-2' text = 'AA-2' ) ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen.
    DATA lv_variant_name TYPE zif_gg_session_types_v1=>ty_variant.

    CASE mv_mode.
      WHEN '71'.
        IF ct_values[ name = 'P_CARRIER' ]-value = 'AA'
            AND ct_values[ name = 'P_CONNECTION' ]-value CP 'LH-*'.
          io_session->message( VALUE #(
            type = zif_gg_session_types_v1=>message_type_error
            text = 'Stale connection option' field = 'P_CONNECTION' ) ).
        ENDIF.
      WHEN '73'.
        CASE iv_ucomm.
          WHEN 'RANGE_ADD'.
            APPEND VALUE #( sign = 'I' option = 'EQ' ) TO ct_values[ name = 'S_MULTI' ]-ranges.
            stop_with_message( iv_text = 'Range row added' io_session = io_session ).
          WHEN 'RANGE_REMOVE'.
            IF lines( ct_values[ name = 'S_MULTI' ]-ranges ) > 1.
              DELETE ct_values[ name = 'S_MULTI' ]-ranges INDEX lines( ct_values[ name = 'S_MULTI' ]-ranges ).
            ENDIF.
            stop_with_message( iv_text = 'Range row removed' io_session = io_session ).
          WHEN 'RANGE_UP'.
            IF lines( ct_values[ name = 'S_MULTI' ]-ranges ) > 1.
              DATA(ls_first_range) = ct_values[ name = 'S_MULTI' ]-ranges[ 1 ].
              ct_values[ name = 'S_MULTI' ]-ranges[ 1 ] = ct_values[ name = 'S_MULTI' ]-ranges[ 2 ].
              ct_values[ name = 'S_MULTI' ]-ranges[ 2 ] = ls_first_range.
            ENDIF.
            stop_with_message( iv_text = 'Range rows reordered' io_session = io_session ).
        ENDCASE.
      WHEN '75'.
        IF iv_ucomm = 'UT1' OR iv_ucomm = 'UT2'.
          stop_with_message( iv_text = |Tab { iv_ucomm } selected| io_session = io_session ).
        ENDIF.
      WHEN '76'.
        IF iv_ucomm = 'DERIVE'.
          ct_values[ name = 'P_DERIVED' ]-value = 'derived by pushbutton'.
          stop_with_message( iv_text = 'Derived value updated' io_session = io_session ).
        ENDIF.
      WHEN '77'.
        CASE iv_ucomm.
          WHEN 'FC01'.
            ct_values[ name = 'P_ACTION' ]-value = 'alpha'.
            stop_with_message( iv_text = 'Alpha action selected' io_session = io_session ).
          WHEN 'FC02'.
            ct_values[ name = 'P_ACTION' ]-value = 'beta'.
            stop_with_message( iv_text = 'Beta action selected' io_session = io_session ).
        ENDCASE.
      WHEN '82'.
        lv_variant_name = CONV #( ct_values[ name = 'P_NAME' ]-value ).
        CASE iv_ucomm.
          WHEN 'VAR_SAVE'.
            zcl_gg_host_variant=>save(
              iv_name = lv_variant_name
              it_values = ct_values ).
            stop_with_message( iv_text = 'Variant saved' io_session = io_session ).
          WHEN 'VAR_LOAD'.
            DATA(lt_loaded) = zcl_gg_host_variant=>load( lv_variant_name ).
            IF lt_loaded IS INITIAL.
              stop_with_message( iv_text = 'Variant not found' io_session = io_session ).
            ENDIF.
            LOOP AT lt_loaded INTO DATA(ls_loaded).
              IF line_exists( ct_values[ name = ls_loaded-name ] ).
                ct_values[ name = ls_loaded-name ] = ls_loaded.
              ENDIF.
            ENDLOOP.
            stop_with_message( iv_text = 'Variant loaded' io_session = io_session ).
          WHEN 'VAR_DELETE'.
            zcl_gg_host_variant=>delete( lv_variant_name ).
            stop_with_message( iv_text = 'Variant deleted' io_session = io_session ).
        ENDCASE.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_field.
    IF mv_mode = '80' AND iv_name = 'P_FIELD'.
      add_order( 'FIELD' ).
      IF iv_name = 'P_FIELD'
          AND ct_values[ name = 'P_FIELD' ]-value = 'bad'.
        io_session->message( VALUE #(
          type = zif_gg_session_types_v1=>message_type_error
          text = 'Field validation failed' field = 'P_FIELD' ) ).
      ENDIF.
    ELSEIF mv_mode = '81' AND iv_name = 'P_BAD'
        AND ct_values[ name = 'P_BAD' ]-value = 'bad'.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'Failing value rejected' field = 'P_BAD' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_end_of.
    IF mv_mode = '80'.
      add_order( 'END' ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_block.
    IF mv_mode = '80'.
      add_order( 'BLOCK' ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_radio.
    IF mv_mode = '80'.
      add_order( 'RADIO' ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_value_req.
    IF mv_mode = '74' AND iv_name = 'S_MULTI'.
      rt_values = VALUE #(
        ( sign = 'I' option = 'EQ' low = 'AA' )
        ( sign = 'I' option = 'EQ' low = 'LH' )
        ( sign = 'E' option = 'EQ' low = 'SQ' ) ).
    ELSEIF mv_mode = '78'.
      rt_values = VALUE #(
        ( sign = 'I' option = 'EQ' low = 'AA' )
        ( sign = 'I' option = 'EQ' low = 'LH' )
        ( sign = 'I' option = 'EQ' low = 'SQ' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_help_req.
    IF mv_mode = '79' AND iv_name = 'P_HELP'.
      rv_text = 'Enter a business key. Help text is owned by the field and remains associated after a failed submit.'.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).
    DATA lv_range_text TYPE string.
    io_session->get_list( )->set_title( |ZCL_GG_EX_{ mv_mode }| ).
    CASE mv_mode.
      WHEN '71'.
        lo_writer->write_field( VALUE #( text = it_values[ name = 'P_CARRIER' ]-value ) ).
        lo_writer->write_field( VALUE #( text = it_values[ name = 'P_CONNECTION' ]-value placement = VALUE #( new_line = abap_true ) ) ).
      WHEN '72'.
        LOOP AT it_values[ name = 'S_CARRIER' ]-ranges INTO DATA(ls_72_range).
          lv_range_text = range_text( is_range = ls_72_range ).
          lo_writer->write_field( VALUE #( text = lv_range_text placement = VALUE #( new_line = xsdbool( sy-tabix > 1 ) ) ) ).
        ENDLOOP.
      WHEN '73' OR '74'.
        LOOP AT it_values[ name = 'S_MULTI' ]-ranges INTO DATA(ls_73_range).
          lv_range_text = range_text( is_range = ls_73_range ).
          lo_writer->write_field( VALUE #( text = lv_range_text placement = VALUE #( new_line = xsdbool( sy-tabix > 1 ) ) ) ).
        ENDLOOP.
      WHEN '75'.
        lo_writer->write_field( VALUE #( text = it_values[ name = 'P_GENERAL' ]-value ) ).
        lo_writer->write_field( VALUE #( text = it_values[ name = 'P_DETAILS' ]-value placement = VALUE #( new_line = abap_true ) ) ).
      WHEN '76'.
        lo_writer->write_field( VALUE #( text = it_values[ name = 'P_DERIVED' ]-value ) ).
      WHEN '77'.
        lo_writer->write_field( VALUE #( text = it_values[ name = 'P_ACTION' ]-value ) ).
      WHEN '78'.
        lo_writer->write_field( VALUE #( text = it_values[ name = 'P_CARRIER' ]-value ) ).
        lo_writer->write_field( VALUE #( text = it_values[ name = 'S_RANGE' ]-ranges[ 1 ]-low placement = VALUE #( new_line = abap_true ) ) ).
      WHEN '79'.
        lo_writer->write_field( VALUE #( text = it_values[ name = 'P_HELP' ]-value ) ).
      WHEN '80'.
        lo_writer->write_field( VALUE #( text = mv_order ) ).
      WHEN '81'.
        lo_writer->write_field( VALUE #( text = it_values[ name = 'P_GOOD' ]-value ) ).
        lo_writer->write_field( VALUE #( text = it_values[ name = 'P_BAD' ]-value placement = VALUE #( new_line = abap_true ) ) ).
      WHEN '82'.
        lo_writer->write_field( VALUE #( text = |{ it_values[ name = 'P_NAME' ]-value }={ it_values[ name = 'P_VALUE' ]-value }| ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_report_v1~load_of_program.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_logical_database.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~initialization.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get_late.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_exit.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~end_of_selection.
    RETURN.
  ENDMETHOD.

ENDCLASS.
