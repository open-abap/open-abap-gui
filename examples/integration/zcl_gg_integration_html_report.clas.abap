CLASS zcl_gg_integration_html_report DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_list_processing_v1.

ENDCLASS.

CLASS zcl_gg_integration_html_report IMPLEMENTATION.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_parameter( VALUE #(
      name        = 'P_CARR'
      text        = 'Carrier'
      data_type   = VALUE #( typ = 'C' length = 3 )
      search_help = 'P_CARR'
      value_help  = abap_true ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen.
    IF ct_values[ name = 'P_CARR' ]-value = 'ZZZ'.
      io_session->message( VALUE #(
        type  = zif_gg_session_types_v1=>message_type_error
        text  = 'Unknown carrier'
        field = 'P_CARR' ) ).
    ELSEIF ct_values[ name = 'P_CARR' ]-value IS INITIAL.
      io_session->message( VALUE #(
        type  = zif_gg_session_types_v1=>message_type_error
        text  = 'Enter a carrier'
        field = 'P_CARR' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    DATA lt_flights TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.
    DATA lv_carrid TYPE zsflight-carrid.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).

    lv_carrid = it_values[ name = 'P_CARR' ]-value.
    SELECT * FROM zsflight
      INTO TABLE @lt_flights
      WHERE carrid = @lv_carrid
      ORDER BY carrid, connid, fldate.

    LOOP AT lt_flights INTO DATA(ls_flight).
      lo_writer->write_field( VALUE #(
        text      = |{ ls_flight-carrid }/{ ls_flight-connid } { ls_flight-fldate }|
        placement = VALUE #( new_line = abap_true )
        hide      = VALUE #(
          ( name = 'CARRID' value = ls_flight-carrid )
          ( name = 'CONNID' value = ls_flight-connid )
          ( name = 'FLDATE' value = ls_flight-fldate ) ) ) ).
    ENDLOOP.

    IF lt_flights IS INITIAL.
      lo_writer->write_field( VALUE #( text = 'No flights found' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_value_req.
    IF iv_name = 'P_CARR'.
      rt_values = VALUE #(
        ( sign = 'I' option = 'EQ' low = 'AA' )
        ( sign = 'I' option = 'EQ' low = 'LH' )
        ( sign = 'I' option = 'EQ' low = 'SQ' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_help_req.
    IF iv_name = 'P_CARR'.
      rv_text = 'Enter a carrier from the integration fixture.'.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_line_selection.
    DATA(ls_cursor) = io_session->get_list( )->get_cursor( ).
    DATA(lv_carrid) = is_line-fields[ name = 'CARRID' ]-value.
    DATA(lv_connid) = is_line-fields[ name = 'CONNID' ]-value.
    DATA(lv_fldate) = is_line-fields[ name = 'FLDATE' ]-value.
    DATA(lo_detail) = io_session->get_list( )->get_writer( ).

    lo_detail->write_field( VALUE #(
      text      = |Selected flight: { lv_carrid }/{ lv_connid } { lv_fldate }|
      placement = VALUE #( new_line = abap_true ) ) ).
    lo_detail->write_field( VALUE #(
      text      = |Cursor: { ls_cursor-field }={ ls_cursor-value } line={ ls_cursor-line }|
      placement = VALUE #( new_line = abap_true ) ) ).
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page_during_line_sel.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_user_command.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~get_settings.
    rs_settings-status = 'FLIGHTS'.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~end_of_page.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~load_of_program.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_logical_database.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    ro_list_processing = me.
  ENDMETHOD.

  METHOD zif_gg_report_v1~initialization.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_field.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_end_of.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_block.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_radio.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_exit.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get_late.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~end_of_selection.
    RETURN.
  ENDMETHOD.

ENDCLASS.