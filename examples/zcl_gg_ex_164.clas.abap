CLASS zcl_gg_ex_164 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 164, a radio group whose USER-COMMAND switches which select-options
* LOOP AT SCREEN shows, as a queue cleanup report does. Counterpart of
* zgg_ex_164.prog.abap. USER-COMMAND is declared on the first button only and
* belongs to the whole group; the select-options carry MODIF IDs.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.

ENDCLASS.

CLASS zcl_gg_ex_164 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_164' description = 'Radio USER-COMMAND with MODIF ID select-options' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_radiobutton( VALUE #(
      name        = 'P_IN'
      text        = 'Inbound'
      radio_group = 'DIR'
      default     = abap_true
      ucomm       = 'DIR' ) ).
    io_builder->add_radiobutton( VALUE #(
      name        = 'P_OUT'
      text        = 'Outbound'
      radio_group = 'DIR' ) ).
    io_builder->add_select_option( VALUE #(
      name      = 'S_INQ'
      text      = 'Inbound queue'
      data_type = VALUE #( typ = 'C' length = 24 )
      modif_id  = 'IN' ) ).
    io_builder->add_select_option( VALUE #(
      name      = 'S_OUTQ'
      text      = 'Outbound queue'
      data_type = VALUE #( typ = 'C' length = 24 )
      modif_id  = 'OUT' ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    DATA(lv_in) = ct_values[ name = 'P_IN' ]-value.
    DATA(lv_out) = ct_values[ name = 'P_OUT' ]-value.
    LOOP AT ct_states ASSIGNING FIELD-SYMBOL(<ls_state>).
      CASE <ls_state>-modif_id.
        WHEN 'IN'.
          <ls_state>-visible = xsdbool( lv_in = abap_true ).
        WHEN 'OUT'.
          <ls_state>-visible = xsdbool( lv_out = abap_true ).
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).
    io_session->get_list( )->set_title( 'ZCL_GG_EX_164' ).
    IF it_values[ name = 'P_IN' ]-value = abap_true.
      lo_writer->write_field( VALUE #( text = 'Cleaning inbound queues' placement = VALUE #( new_line = abap_true ) ) ).
    ELSE.
      lo_writer->write_field( VALUE #( text = 'Cleaning outbound queues' placement = VALUE #( new_line = abap_true ) ) ).
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
