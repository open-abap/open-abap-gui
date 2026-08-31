CLASS zcl_gg_ex_049 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 49, AT PF5. Counterpart of zgg_ex_049.prog.abap.
* The host drives the requested PF event. Self contained: no superclass, every
* callback present.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.
    INTERFACES zif_gg_list_processing_v1.

ENDCLASS.

CLASS zcl_gg_ex_049 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_049' description = 'AT PF5' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_049' ).
    io_session->get_list( )->set_status( VALUE #(
      status         = 'LIST'
      active_pf_keys = VALUE #( ( 5 ) ) ) ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'body' ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    ro_list_processing = me.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    IF iv_key = 5.
      io_session->get_list( )->get_writer( )->write_field( VALUE #(
        text      = 'pf5'
        placement = VALUE #( new_line = abap_true ) ) ).
    ENDIF.
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

  METHOD zif_gg_list_processing_v1~at_user_command.
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
