CLASS zcl_gg_ex_026 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 26, selection-screen tabbed block and tabs. Counterpart of
* zgg_ex_026.prog.abap. Each tab shows its own selection subscreen.
* Self contained: no superclass, every callback present.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.

ENDCLASS.

CLASS zcl_gg_ex_026 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_026' description = 'Selection-screen tabbed block and tabs' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->begin_tabbed_block( VALUE #( name = 'TB' lines = 10 ) ).
    io_builder->add_tab( VALUE #(
      name      = 'TAB1'
      text      = 'General'
      subscreen = '0100'
      ucomm     = 'UT1' ) ).
    io_builder->add_tab( VALUE #(
      name      = 'TAB2'
      text      = 'Details'
      subscreen = '0200'
      ucomm     = 'UT2' ) ).
    io_builder->end_tabbed_block( ).

    io_builder->begin_screen( VALUE #( number = '0100' as_subscreen = abap_true ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_NAME'
      text      = 'Name'
      data_type = VALUE #( typ = 'C' length = 20 )
      default   = 'Ada Lovelace' ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_CITY'
      text      = 'City'
      data_type = VALUE #( typ = 'C' length = 20 )
      default   = 'London' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = '0200' as_subscreen = abap_true ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_COUNT'
      text      = 'Count'
      data_type = VALUE #( typ = 'I' )
      default   = '3' ) ).
    io_builder->add_checkbox( VALUE #(
      name    = 'P_ACTIVE'
      text    = 'Active'
      default = abap_true ) ).
    io_builder->end_screen( ).
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
* The report sets the tab fields tab1 and tab2, their values are the labels.
    ct_values[ name = 'TAB1' ]-value = 'General'.
    ct_values[ name = 'TAB2' ]-value = 'Details'.
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
    io_session->get_list( )->set_title( 'ZCL_GG_EX_026' ).
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).
    lo_writer->write_field( VALUE #( text = 'Name:' placement = VALUE #( new_line = abap_true ) ) ).
    lo_writer->write_field( VALUE #( text = it_values[ name = 'P_NAME' ]-value ) ).
    lo_writer->write_field( VALUE #( text = 'City:' placement = VALUE #( new_line = abap_true ) ) ).
    lo_writer->write_field( VALUE #( text = it_values[ name = 'P_CITY' ]-value ) ).
    lo_writer->write_field( VALUE #( text = 'Count:' placement = VALUE #( new_line = abap_true ) ) ).
    lo_writer->write_field( VALUE #( text = it_values[ name = 'P_COUNT' ]-value ) ).
    IF it_values[ name = 'P_ACTIVE' ]-value = abap_true.
      lo_writer->write_field( VALUE #( text = 'Active' placement = VALUE #( new_line = abap_true ) ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
