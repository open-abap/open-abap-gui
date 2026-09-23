CLASS zcl_gg_ex_030 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 30, AT SELECTION-SCREEN. Counterpart of zgg_ex_030.prog.abap.
* The host drives the selection-screen PAI event with supplied input values.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.

ENDCLASS.

CLASS zcl_gg_ex_030 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_030' description = 'AT SELECTION-SCREEN' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_parameter( VALUE #(
      name      = 'P_N'
      text      = 'Number'
      data_type = VALUE #( typ = 'I' ) ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen.
    IF ct_values[ name = 'P_N' ]-value < 0.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'must not be negative' ) ).
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

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_030' ).
    RETURN.
  ENDMETHOD.

ENDCLASS.
