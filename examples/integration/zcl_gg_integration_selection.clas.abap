CLASS zcl_gg_integration_selection DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string DEFAULT 'DEFAULT'.

  PRIVATE SECTION.
    TYPES ty_flights TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.

    DATA mv_mode TYPE string.

    METHODS write_flights
      IMPORTING
        it_flights TYPE ty_flights
        io_session TYPE REF TO zif_gg_session_v1.

ENDCLASS.

CLASS zcl_gg_integration_selection IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
  ENDMETHOD.

  METHOD write_flights.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).

    LOOP AT it_flights INTO DATA(ls_flight).
      lo_writer->write_field( VALUE #(
        text      = |{ ls_flight-carrid }/{ ls_flight-connid }|
        placement = VALUE #( new_line = abap_true ) ) ).
    ENDLOOP.

    IF it_flights IS INITIAL.
      lo_writer->write_field( VALUE #( text = 'No flights found' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    CASE mv_mode.
      WHEN 'DEFAULT'.
        io_builder->add_parameter( VALUE #(
          name      = 'P_CARR'
          text      = 'Carrier'
          data_type = VALUE #( typ = 'C' length = 3 )
          default   = 'LH' ) ).
      WHEN 'REQUIRED'.
        io_builder->add_parameter( VALUE #(
          name       = 'P_CARR'
          text       = 'Carrier'
          data_type  = VALUE #( typ = 'C' length = 3 )
          obligatory = abap_true ) ).
      WHEN 'INVALID'.
        io_builder->add_parameter( VALUE #(
          name      = 'P_CARR'
          text      = 'Carrier'
          data_type = VALUE #( typ = 'C' length = 3 ) ) ).
      WHEN 'RANGE' OR 'MULTI' OR 'VALUE_REQUEST' OR 'CANCEL_VALUE'.
        io_builder->add_select_option( VALUE #(
          name       = 'S_CARR'
          text       = 'Carrier'
          data_type  = VALUE #( typ = 'C' length = 3 )
          default    = VALUE #(
            sign   = zif_gg_selection_screen_types=>sign_include
            option = zif_gg_selection_screen_types=>option_eq
            low    = 'AA' )
          value_help = xsdbool( mv_mode = 'VALUE_REQUEST' OR mv_mode = 'CANCEL_VALUE' ) ) ).
      WHEN 'DATE_REQUEST'.
        io_builder->add_select_option( VALUE #(
          name       = 'S_DATE'
          text       = 'Flight date'
          data_type  = VALUE #( typ = 'D' length = 8 )
          value_help = abap_true ) ).
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen.
    IF mv_mode = 'INVALID'
        AND ct_values[ name = 'P_CARR' ]-value = 'ZZZ'.
      io_session->message( VALUE #(
        type  = zif_gg_session_types_v1=>message_type_error
        text  = 'Unknown carrier'
        field = 'P_CARR' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    DATA lt_flights TYPE ty_flights.
    DATA lv_carrid TYPE zsflight-carrid.
    DATA lv_low TYPE zsflight-carrid.
    DATA lv_high TYPE zsflight-carrid.
    DATA lv_first TYPE zsflight-carrid.
    DATA lv_second TYPE zsflight-carrid.
    DATA lr_carr TYPE RANGE OF zsflight-carrid.
    DATA ls_range TYPE zif_gg_selection_screen_types=>ty_range.
    DATA ls_carr_range LIKE LINE OF lr_carr.

    CASE mv_mode.
      WHEN 'DEFAULT' OR 'REQUIRED' OR 'INVALID'.
        lv_carrid = it_values[ name = 'P_CARR' ]-value.
      WHEN 'RANGE' OR 'MULTI' OR 'VALUE_REQUEST'.
        LOOP AT it_values[ name = 'S_CARR' ]-ranges INTO ls_range.
          APPEND VALUE #(
            sign   = ls_range-sign
            option = ls_range-option
            low    = ls_range-low
            high   = ls_range-high ) TO lr_carr.
        ENDLOOP.
        READ TABLE lr_carr INTO ls_carr_range INDEX 1.
        lv_low = ls_carr_range-low.
        lv_high = ls_carr_range-high.
        lv_first = ls_carr_range-low.
        READ TABLE lr_carr INTO ls_carr_range INDEX 2.
        lv_second = ls_carr_range-low.
    ENDCASE.

    CASE mv_mode.
      WHEN 'DEFAULT' OR 'REQUIRED' OR 'INVALID'.
        SELECT * FROM zsflight
          INTO TABLE @lt_flights
          WHERE carrid = @lv_carrid
          ORDER BY carrid, connid, fldate.
      WHEN 'RANGE' OR 'MULTI' OR 'VALUE_REQUEST'.
        CASE mv_mode.
          WHEN 'RANGE'.
            SELECT * FROM zsflight
              INTO TABLE @lt_flights
              WHERE carrid BETWEEN @lv_low AND @lv_high
              ORDER BY carrid, connid, fldate.
          WHEN 'MULTI'.
            SELECT * FROM zsflight
              INTO TABLE @lt_flights
              WHERE carrid = @lv_first OR carrid = @lv_second
              ORDER BY carrid, connid, fldate.
          WHEN OTHERS.
            SELECT * FROM zsflight
              INTO TABLE @lt_flights
              ORDER BY carrid, connid, fldate.
        ENDCASE.
      WHEN OTHERS.
        RETURN.
    ENDCASE.

    write_flights(
      it_flights = lt_flights
      io_session = io_session ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_value_req.
    DATA lt_carriers TYPE STANDARD TABLE OF zsflight-carrid WITH DEFAULT KEY.

    IF mv_mode = 'CANCEL_VALUE'.
      RETURN.
    ENDIF.

    IF iv_name = 'S_CARR'.
      SELECT DISTINCT carrid FROM zsflight
        INTO TABLE @lt_carriers
        ORDER BY carrid.

      LOOP AT lt_carriers INTO DATA(lv_carrier).
        APPEND VALUE #(
          sign   = zif_gg_selection_screen_types=>sign_include
          option = zif_gg_selection_screen_types=>option_eq
          low    = lv_carrier ) TO rt_values.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_help_req.
    RETURN.
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
