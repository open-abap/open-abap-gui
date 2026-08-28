CLASS zcl_gg_integration_interactive DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_list_processing_v1.

ENDCLASS.

CLASS zcl_gg_integration_interactive IMPLEMENTATION.

  METHOD zif_gg_report_v1~start_of_selection.
    DATA lt_flights TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).

    SELECT * FROM zsflight
      INTO TABLE @lt_flights
      ORDER BY carrid, connid, fldate.

    lo_writer->set_format( VALUE #(
      color       = zif_gg_list_processing_types_v1=>color_positive
      intensified = abap_true ) ).

    LOOP AT lt_flights INTO DATA(ls_flight).
      lo_writer->write_field( VALUE #(
        text = |{ ls_flight-carrid }/{ ls_flight-connid } { ls_flight-fldate }|
        placement = VALUE #( new_line = abap_true )
        hide = VALUE #(
          ( name = 'CARRID' value = ls_flight-carrid )
          ( name = 'CONNID' value = ls_flight-connid )
          ( name = 'FLDATE' value = ls_flight-fldate ) ) ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    ro_list_processing = me.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page_during_line_sel.
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text = |DETAIL HEADER { iv_level }|
      placement = VALUE #( new_line = abap_true ) ) ).
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_line_selection.
    DATA(ls_cursor) = io_session->get_list( )->get_cursor( ).
    DATA(lv_carrid) = is_line-fields[ name = 'CARRID' ]-value.
    DATA(lv_connid) = is_line-fields[ name = 'CONNID' ]-value.
    DATA(lv_fldate) = is_line-fields[ name = 'FLDATE' ]-value.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).

    io_session->get_list( )->enter_list_processing( ).
    DATA(ls_context) = io_session->get_list( )->get_context( ).
    lo_writer->write_field( VALUE #(
      text = |Selected line: { is_line-text }|
      placement = VALUE #( new_line = abap_true ) ) ).
    lo_writer->write_field( VALUE #(
      text = |Hidden: { lv_carrid }/{ lv_connid } { lv_fldate }|
      placement = VALUE #( new_line = abap_true ) ) ).
    lo_writer->write_field( VALUE #(
      text = |Cursor: { ls_cursor-field }={ ls_cursor-value } line={ ls_cursor-line }|
      placement = VALUE #( new_line = abap_true ) ) ).
    lo_writer->write_field( VALUE #(
      text = |Detail flight: { lv_carrid }/{ lv_connid } { lv_fldate }|
      placement = VALUE #( new_line = abap_true ) ) ).
    lo_writer->write_field( VALUE #(
      text = |List level: { ls_context-level }|
      placement = VALUE #( new_line = abap_true ) ) ).
    io_session->get_list( )->leave_list_processing( ).
    ls_context = io_session->get_list( )->get_context( ).
    lo_writer->write_field( VALUE #(
      text = |Restored level: { ls_context-level }|
      placement = VALUE #( new_line = abap_true ) ) ).
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_user_command.
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text = |Function code: { iv_ucomm }|
      placement = VALUE #( new_line = abap_true ) ) ).
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text = |PF key: { iv_key }|
      placement = VALUE #( new_line = abap_true ) ) ).
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

  METHOD zif_gg_report_v1~build_screen.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~initialization.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen.
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

  METHOD zif_gg_report_v1~at_selection_screen_value_req.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_help_req.
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
