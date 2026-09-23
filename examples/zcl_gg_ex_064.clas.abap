CLASS zcl_gg_ex_064 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 64, title, status, cursor, and command feedback.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_transaction_v1.
ENDCLASS.

CLASS zcl_gg_ex_064 IMPLEMENTATION.
  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_064' description = 'Title status cursor and command feedback' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' title = 'Feedback 64' height = 180 ) ).
    io_builder->add_input_field( VALUE #(
      control   = VALUE #( name = 'P_ACTION' position = VALUE #( row = 2 column = 2 width = 30 height = 1 ) )
      data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_flow_logic.
    io_builder->begin_screen( '0100' ).
    io_builder->begin_pbo( ).
    io_builder->add_module( VALUE #( name = 'STATUS_0100' ) ).
    io_builder->end_processing( ).
    io_builder->begin_pai( ).
    io_builder->add_module( VALUE #( name = 'COMMAND_0100' on_input = abap_true ) ).
    io_builder->end_processing( ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    IF is_context-module = 'STATUS_0100'.
      io_session->get_dialog( )->set_title( 'Feedback 64 - next action' ).
      io_session->get_dialog( )->set_status( VALUE #(
        status       = 'SHELL64'
        active_ucomm = VALUE #( ( 'NEXT64' ) )
        icon_bar     = VALUE #( ( ucomm = 'NEXT64' label = 'Next action' icon = 'arrow-right' ) ) ) ).
      io_session->get_dialog( )->set_cursor( VALUE #( field = 'P_ACTION' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    IF is_context-ucomm = 'NEXT64' AND line_exists( ct_values[ name = 'P_ACTION' ] ).
      ct_values[ name = 'P_ACTION' ]-value = 'accepted'.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    RETURN.
  ENDMETHOD.
ENDCLASS.
