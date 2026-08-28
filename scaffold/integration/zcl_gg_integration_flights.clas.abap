CLASS zcl_gg_integration_flights DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string DEFAULT 'ALL'.

  PRIVATE SECTION.
    TYPES ty_flights TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.

    DATA mv_mode TYPE string.

    METHODS write_flights
      IMPORTING
        it_flights TYPE ty_flights
        io_session TYPE REF TO zif_gg_session_v1.

ENDCLASS.

CLASS zcl_gg_integration_flights IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
  ENDMETHOD.

  METHOD write_flights.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).

    LOOP AT it_flights INTO DATA(ls_flight).
      lo_writer->write_field( VALUE #( text = |{ ls_flight-carrid }/{ ls_flight-connid } { ls_flight-fldate } { ls_flight-price DECIMALS = 2 } { ls_flight-currency } { ls_flight-cityfrom }->{ ls_flight-cityto }| placement = VALUE #( new_line = abap_true ) ) ).
    ENDLOOP.

    IF it_flights IS INITIAL.
      lo_writer->write_field( VALUE #( text = 'No flights found' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    DATA lt_flights TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.

    CASE mv_mode.
      WHEN 'ALL'.
        SELECT * FROM zsflight
          INTO TABLE @lt_flights
          ORDER BY carrid, connid, fldate.
      WHEN 'LH'.
        SELECT * FROM zsflight
          INTO TABLE @lt_flights
          WHERE carrid = 'LH'
          ORDER BY carrid, connid, fldate.
      WHEN 'DATE'.
        SELECT * FROM zsflight
          INTO TABLE @lt_flights
          WHERE fldate = '20260115'
          ORDER BY carrid, connid, fldate.
      WHEN 'RANGE'.
        SELECT * FROM zsflight
          INTO TABLE @lt_flights
          WHERE fldate BETWEEN '20260101' AND '20260115'
          ORDER BY carrid, connid, fldate.
      WHEN 'REVERSE'.
        SELECT * FROM zsflight
          INTO TABLE @lt_flights
          WHERE fldate BETWEEN '20260115' AND '20260101'
          ORDER BY carrid, connid, fldate.
      WHEN 'MULTI'.
        SELECT * FROM zsflight
          INTO TABLE @lt_flights
          WHERE carrid = 'AA' OR carrid = 'LH'
          ORDER BY carrid, connid, fldate.
      WHEN 'NONE'.
        SELECT * FROM zsflight
          INTO TABLE @lt_flights
          WHERE carrid = 'ZZZ'
          ORDER BY carrid, connid, fldate.
      WHEN 'ROUND'.
        SELECT * FROM zsflight
          INTO TABLE @lt_flights
          WHERE carrid = 'SQ'
          ORDER BY carrid, connid, fldate.
      WHEN OTHERS.
        RETURN.
    ENDCASE.

    write_flights(
      it_flights = lt_flights
      io_session = io_session ).
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
