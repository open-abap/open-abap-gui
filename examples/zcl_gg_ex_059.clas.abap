CLASS zcl_gg_ex_059 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 59, example-owned application icon bar.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.
    INTERFACES zif_gg_list_processing_v1.
ENDCLASS.

CLASS zcl_gg_ex_059 IMPLEMENTATION.
  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_059' description = 'Example-owned Refresh and Print icon bar' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_059' ).
    io_session->get_list( )->set_status( VALUE #(
      status       = 'SHELL59'
      active_ucomm = VALUE #( ( 'REFR' ) ( 'PRI' ) )
      icon_bar     = VALUE #( ( ucomm = 'REFR' label = 'Refresh' icon = 'refresh' )
                          ( ucomm = 'PRI' label = 'Print' icon = 'printer' separator = abap_true ) ) ) ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'body' ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    ro_list_processing = me.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_user_command.
    CASE iv_ucomm.
      WHEN 'REFR'.
        io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'refreshed' placement = VALUE #( new_line = abap_true ) ) ).
      WHEN 'PRI'.
        io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'printed' placement = VALUE #( new_line = abap_true ) ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~get_settings.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~end_of_page.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page_during_line_sel.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_line_selection.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
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
