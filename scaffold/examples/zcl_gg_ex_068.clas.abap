CLASS zcl_gg_ex_068 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 68, dynamic visible, input, and required state.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.
ENDCLASS.

CLASS zcl_gg_ex_068 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #(
      tcode       = 'ZGG_EX_068'
      description = 'Dynamic visible input and required state' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_checkbox( VALUE #(
      name  = 'P_SHOW'
      text  = 'Show detail'
      ucomm = 'TOGGLE' ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_DETAIL'
      text      = 'Detail'
      data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->add_parameter( VALUE #(
      name       = 'P_REQUIRED'
      text       = 'Required value'
      data_type  = VALUE #( typ = 'C' length = 20 )
      obligatory = abap_true ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    DATA(lv_show) = xsdbool( ct_values[ name = 'P_SHOW' ]-value = 'X' ).
    ct_states[ name = 'P_DETAIL' ]-visible = lv_show.
    ct_states[ name = 'P_DETAIL' ]-input = lv_show.
    ct_states[ name = 'P_DETAIL' ]-obligatory = lv_show.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_068' ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text = it_values[ name = 'P_REQUIRED' ]-value ) ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text      = it_values[ name = 'P_DETAIL' ]-value
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
