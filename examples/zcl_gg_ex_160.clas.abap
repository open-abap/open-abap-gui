CLASS zcl_gg_ex_160 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 160, two sibling selection-screen blocks with frame and title.
* Counterpart of zgg_ex_160.prog.abap. Both blocks sit at depth 1, and each
* renders as its own frame with its own title.
* Self contained: no superclass, every callback present.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.

ENDCLASS.

CLASS zcl_gg_ex_160 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_160' description = 'Sibling selection-screen blocks' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->begin_block( VALUE #(
      name       = 'BLOCK1'
      title      = 'Run limits'
      with_frame = abap_true ) ).
    io_builder->add_parameter( VALUE #(
      name       = 'P_MAXRUN'
      text       = 'Maximum runs'
      data_type  = VALUE #( typ = 'I' )
      default    = '20'
      obligatory = abap_true ) ).
    io_builder->end_block( ).
    io_builder->begin_block( VALUE #(
      name       = 'BLOCK2'
      title      = 'Background defaults'
      with_frame = abap_true ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_BKDEF'
      text      = 'Default jobs'
      data_type = VALUE #( typ = 'I' )
      default   = '4' ) ).
    io_builder->end_block( ).
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

    io_session->get_list( )->set_title( 'ZCL_GG_EX_160' ).
    lo_writer->write_field( VALUE #( text = it_values[ name = 'P_MAXRUN' ]-value ) ).
    lo_writer->new_line( ).
    lo_writer->write_field( VALUE #( text = it_values[ name = 'P_BKDEF' ]-value ) ).
  ENDMETHOD.

ENDCLASS.
