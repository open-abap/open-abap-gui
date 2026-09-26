CLASS zcl_gg_ex_161 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 161, two checkbox parameters declared in one chained PARAMETERS
* statement after a SKIP. Counterpart of zgg_ex_161.prog.abap. Neither sits
* inside BEGIN OF LINE, so each checkbox renders on a line of its own.
* Self contained: no superclass, every callback present.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.

ENDCLASS.

CLASS zcl_gg_ex_161 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_161' description = 'Stacked checkbox parameters' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_skip( 1 ).
    io_builder->add_checkbox( VALUE #(
      name    = 'P_CLEAN'
      text    = 'Clean up'
      default = abap_true ) ).
    io_builder->add_checkbox( VALUE #(
      name    = 'P_TSAVE'
      text    = 'Test save'
      default = abap_false ) ).
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

  METHOD zif_gg_report_v1~start_of_selection.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).

    io_session->get_list( )->set_title( 'ZCL_GG_EX_161' ).
    lo_writer->write_field( VALUE #( text = |P_CLEAN={ it_values[ name = 'P_CLEAN' ]-value }| ) ).
    lo_writer->new_line( ).
    lo_writer->write_field( VALUE #( text = |P_TSAVE={ it_values[ name = 'P_TSAVE' ]-value }| ) ).
  ENDMETHOD.

ENDCLASS.
