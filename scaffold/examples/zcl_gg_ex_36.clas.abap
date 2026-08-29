CLASS zcl_gg_ex_36 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 36, AT SELECTION-SCREEN ON HELP-REQUEST. Counterpart of
* zgg_ex_36.prog.abap. The host exposes an optional help-request probe.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.

ENDCLASS.

CLASS zcl_gg_ex_36 IMPLEMENTATION.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_parameter( VALUE #(
      name      = 'P_CARR'
      text      = 'Carrier'
      data_type = VALUE #( typ = 'C' length = 3 ) ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_help_req.
    IF iv_name = 'P_CARR'.
      rv_text = 'Two character IATA code'.
    ENDIF.
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

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_36' ).
    RETURN.
  ENDMETHOD.

ENDCLASS.
