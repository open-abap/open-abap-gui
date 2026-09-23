CLASS zcl_gg_integration_failure DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string DEFAULT 'VALID'.

  PRIVATE SECTION.
    DATA mv_mode TYPE string.

ENDCLASS.

CLASS zcl_gg_integration_failure IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    CASE mv_mode.
      WHEN 'DB_FAIL'.
        io_session->message( VALUE #(
          type = zif_gg_session_types_v1=>message_type_error
          text = 'Database unavailable' ) ).
      WHEN 'AUTH_FAIL'.
        io_session->message( VALUE #(
          type = zif_gg_session_types_v1=>message_type_error
          text = 'Authorization denied' ) ).
      WHEN 'VALID'.
        io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'Recovered execution' ) ).
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
