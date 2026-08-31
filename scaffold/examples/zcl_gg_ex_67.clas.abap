CLASS zcl_gg_ex_67 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 67, typed selection-screen parameters.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.
ENDCLASS.

CLASS zcl_gg_ex_67 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #(
      tcode = 'ZGG_EX_67'
      description = 'Typed date time integer decimal and character parameters' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_parameter( VALUE #(
      name      = 'P_DATE'
      text      = 'Date'
      data_type = VALUE #( typ = 'D' length = 8 )
      default   = '20260830' ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_TIME'
      text      = 'Time'
      data_type = VALUE #( typ = 'T' length = 6 )
      default   = '123456' ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_INT'
      text      = 'Integer'
      data_type = VALUE #( typ = 'I' )
      default   = '42' ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_DEC'
      text      = 'Decimal'
      data_type = VALUE #( typ = 'P' decimals = 2 )
      default   = '123.45' ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_CHAR'
      text      = 'Character'
      data_type = VALUE #( typ = 'C' length = 12 )
      obligatory = abap_true ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_67' ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text = it_values[ name = 'P_DATE' ]-value ) ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text = it_values[ name = 'P_TIME' ]-value
      placement = VALUE #( new_line = abap_true ) ) ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text = it_values[ name = 'P_INT' ]-value
      placement = VALUE #( new_line = abap_true ) ) ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text = it_values[ name = 'P_DEC' ]-value
      write_format = VALUE #( decimals = 2 )
      placement = VALUE #( new_line = abap_true ) ) ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text = it_values[ name = 'P_CHAR' ]-value
      placement = VALUE #( new_line = abap_true ) ) ).
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
