CLASS zcl_gg_ex_62 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 62, a command changes the status shown by the next page.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.
    INTERFACES zif_gg_list_processing_v1.
  PRIVATE SECTION.
    DATA mv_advanced TYPE abap_bool.
ENDCLASS.

CLASS zcl_gg_ex_62 IMPLEMENTATION.
  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_62' description = 'Status changes after a command' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_62' ).
    IF mv_advanced = abap_true.
      io_session->get_list( )->set_status( VALUE #(
        status = 'SHELL62-DONE'
        active_ucomm = VALUE #( ( 'DONE' ) )
        excluded_ucomm = VALUE #( ( 'NEXT' ) )
        icon_bar = VALUE #( ( ucomm = 'NEXT' label = 'Next' icon = 'arrow-right' )
                            ( ucomm = 'DONE' label = 'Done' icon = 'circle-check' separator = abap_true ) ) ) ).
      io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'ready' ) ).
    ELSE.
      io_session->get_list( )->set_status( VALUE #(
        status = 'SHELL62'
        active_ucomm = VALUE #( ( 'NEXT' ) )
        icon_bar = VALUE #( ( ucomm = 'NEXT' label = 'Next' icon = 'arrow-right' )
                            ( ucomm = 'DONE' label = 'Done' icon = 'circle-check' separator = abap_true ) ) ) ).
      io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'initial' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    ro_list_processing = me.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_user_command.
    CASE iv_ucomm.
      WHEN 'NEXT'.
        mv_advanced = abap_true.
        io_session->get_list( )->set_status( VALUE #(
          status = 'SHELL62-DONE'
          active_ucomm = VALUE #( ( 'DONE' ) )
          excluded_ucomm = VALUE #( ( 'NEXT' ) )
          icon_bar = VALUE #( ( ucomm = 'NEXT' label = 'Next' icon = 'arrow-right' )
                              ( ucomm = 'DONE' label = 'Done' icon = 'circle-check' separator = abap_true ) ) ) ).
        io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'advanced' placement = VALUE #( new_line = abap_true ) ) ).
      WHEN 'DONE'.
        io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'done' placement = VALUE #( new_line = abap_true ) ) ).
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
