CLASS zcl_gg_ex_03 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 03, SKIP / ULINE / NEW-LINE / SET LEFT COLUMN. Counterpart of
* zgg_ex_03.prog.abap. Self contained: no superclass, every callback present.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.

ENDCLASS.

CLASS zcl_gg_ex_03 IMPLEMENTATION.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_03' ).
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).

    lo_writer->write_field( VALUE #( text = 'first' ) ).
    lo_writer->skip( 2 ).
    lo_writer->uline( VALUE #( position = 1 length = 20 ) ).
    lo_writer->new_line( ).
    lo_writer->set_position( 5 ).
    lo_writer->write_field( VALUE #( text = 'second' ) ).
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
