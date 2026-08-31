CLASS zcl_gg_ex_66 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 66, Unicode and hostile text at the shell boundary.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.
    INTERFACES zif_gg_list_processing_v1.
  PRIVATE SECTION.
    CLASS-METHODS unicode_text
      IMPORTING
        iv_hex         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_gg_ex_66 IMPLEMENTATION.
  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_66' description = 'Unicode and hostile shell text' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    DATA(lv_title) = unicode_text( `52544C20D7A9D79CD795D79D20F09F9A802026203C7469746C653E` ).
    DATA(lv_label) = unicode_text( `52756E20226E6F77222026203C676F3E20F09F9A80` ).
    DATA(lv_body) = unicode_text( `D985D8B1D8ADD8A8D8A72065CC8120F09F9A80203C7368656C6C3E2026202271756F74657322` ).
    io_session->get_list( )->set_title( lv_title ).
    io_session->get_list( )->set_status( VALUE #(
      status = 'SHELL66'
      active_ucomm = VALUE #( ( 'RUN66' ) )
      icon_bar = VALUE #( ( ucomm = 'RUN66' label = lv_label icon = 'execute' ) ) ) ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #( text = lv_body ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    ro_list_processing = me.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_user_command.
    IF iv_ucomm = 'RUN66'.
      io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'accepted <command> & "quotes"' placement = VALUE #( new_line = abap_true ) ) ).
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

  METHOD unicode_text.
    DATA(lv_utf8) = CONV xstring( iv_hex ).
    DATA(lo_converter) = cl_abap_conv_in_ce=>create( input = lv_utf8 encoding = 'UTF-8' ).
    lo_converter->read( IMPORTING data = rv_text ).
  ENDMETHOD.
ENDCLASS.
