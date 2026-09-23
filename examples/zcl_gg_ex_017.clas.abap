CLASS zcl_gg_ex_017 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 17, PARAMETERS AS CHECKBOX. Counterpart of zgg_ex_017.prog.abap.
* Self contained: no superclass, every callback present.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.

ENDCLASS.

CLASS zcl_gg_ex_017 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_017' description = 'PARAMETERS AS CHECKBOX' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_checkbox( VALUE #(
      name    = 'P_TEST'
      text    = 'Test run'
      default = abap_true
      ucomm   = 'FLIP' ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_017' ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text = it_values[ name = 'P_TEST' ]-value ) ).
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
