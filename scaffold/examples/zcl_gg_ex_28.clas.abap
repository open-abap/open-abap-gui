CLASS zcl_gg_ex_28 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 28, AT SELECTION-SCREEN OUTPUT with LOOP AT SCREEN. Counterpart of
* zgg_ex_28.prog.abap. The host drives selection-screen output and retains state
* groups plus input/output flags.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.

ENDCLASS.

CLASS zcl_gg_ex_28 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_28' description = 'AT SELECTION-SCREEN OUTPUT with LOOP AT SCREEN' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_parameter( VALUE #(
      name      = 'P_A'
      text      = 'A'
      data_type = VALUE #( typ = 'C' length = 1 ) ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_B'
      text      = 'B'
      data_type = VALUE #( typ = 'C' length = 1 )
      modif_id  = 'HID' ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    LOOP AT ct_states ASSIGNING FIELD-SYMBOL(<ls_state>) WHERE name = 'P_B'.
      <ls_state>-visible = abap_false.
    ENDLOOP.
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
    io_session->get_list( )->set_title( 'ZCL_GG_EX_28' ).
    RETURN.
  ENDMETHOD.

ENDCLASS.
