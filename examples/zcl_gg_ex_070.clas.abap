CLASS zcl_gg_ex_070 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 70, radio-driven blocks and branch validation.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.
ENDCLASS.

CLASS zcl_gg_ex_070 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #(
      tcode       = 'ZGG_EX_070'
      description = 'Radio-driven blocks and validation' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_radiobutton( VALUE #(
      name        = 'P_ALL'
      text        = 'All flights'
      radio_group = 'G1'
      default     = abap_true ) ).
    io_builder->add_radiobutton( VALUE #(
      name        = 'P_ONE'
      text        = 'One flight'
      radio_group = 'G1' ) ).
    io_builder->begin_block( VALUE #( name = 'B_ALL' title = 'All branch' with_frame = abap_true ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_ALL_VALUE'
      text      = 'All value'
      data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->end_block( ).
    io_builder->begin_block( VALUE #( name = 'B_ONE' title = 'One branch' with_frame = abap_true ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_ONE_VALUE'
      text      = 'One value'
      data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->end_block( ).
    io_builder->add_parameter( VALUE #(
      name       = 'P_REQUIRED'
      text       = 'Required value'
      data_type  = VALUE #( typ = 'C' length = 20 )
      obligatory = abap_true ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    DATA(lv_one) = xsdbool( ct_values[ name = 'P_ONE' ]-value = 'X' ).
    ct_states[ name = 'P_ALL_VALUE' ]-visible = xsdbool( lv_one = abap_false ).
    ct_states[ name = 'P_ALL_VALUE' ]-input = xsdbool( lv_one = abap_false ).
    ct_states[ name = 'P_ALL_VALUE' ]-obligatory = xsdbool( lv_one = abap_false ).
    ct_states[ name = 'P_ONE_VALUE' ]-visible = lv_one.
    ct_states[ name = 'P_ONE_VALUE' ]-input = lv_one.
    ct_states[ name = 'P_ONE_VALUE' ]-obligatory = lv_one.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_070' ).
    IF it_values[ name = 'P_ONE' ]-value = 'X'.
      io_session->get_list( )->get_writer( )->write_field( VALUE #(
        text = it_values[ name = 'P_ONE_VALUE' ]-value ) ).
    ELSE.
      io_session->get_list( )->get_writer( )->write_field( VALUE #(
        text = it_values[ name = 'P_ALL_VALUE' ]-value ) ).
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
ENDCLASS.
