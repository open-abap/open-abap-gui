CLASS zcl_gg_ex_034 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 34, AT SELECTION-SCREEN ON RADIOBUTTON GROUP. Counterpart of
* zgg_ex_034.prog.abap. The host drives radio-group PAI before general PAI.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.

ENDCLASS.

CLASS zcl_gg_ex_034 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_034' description = 'AT SELECTION-SCREEN ON RADIOBUTTON GROUP' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_radiobutton( VALUE #(
      name        = 'P_ALL'
      text        = 'All'
      radio_group = 'G1'
      default     = abap_true ) ).
    io_builder->add_radiobutton( VALUE #(
      name        = 'P_ONE'
      text        = 'Single'
      radio_group = 'G1' ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_KEY'
      text      = 'Key'
      data_type = VALUE #( typ = 'C' length = 3 ) ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_radio.
    IF iv_group = 'G1'
        AND ct_values[ name = 'P_ONE' ]-value = abap_true
        AND ct_values[ name = 'P_KEY' ]-value IS INITIAL.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'key required for single mode' ) ).
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

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_034' ).
    RETURN.
  ENDMETHOD.

ENDCLASS.
