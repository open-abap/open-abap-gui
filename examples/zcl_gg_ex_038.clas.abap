CLASS zcl_gg_ex_038 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 38, sscrfields-ucomm driven suppression. Counterpart of
* zgg_ex_038.prog.abap. The host drives output with batch context.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.

ENDCLASS.

CLASS zcl_gg_ex_038 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_038' description = 'SSCRFIELDS-UCOMM driven suppression' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_parameter( VALUE #(
      name      = 'P_A'
      text      = 'A'
      data_type = VALUE #( typ = 'C' length = 1 )
      default   = 'X' ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    IF io_session->get_context( )-program-batch = abap_true.
      io_session->get_dialog( )->suppress_dialog( ).
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

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_038' ).
    RETURN.
  ENDMETHOD.

ENDCLASS.
