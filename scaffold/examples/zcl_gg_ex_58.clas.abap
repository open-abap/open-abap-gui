CLASS zcl_gg_ex_58 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 58, SET SCREEN, LEAVE SCREEN and LEAVE TO SCREEN. Counterpart of
* zgg_ex_58.prog.abap. The HTML host drives this as the /ZCL_GG_EX_58 route.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_transaction_v1.

ENDCLASS.

CLASS zcl_gg_ex_58 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_58' description = 'SET SCREEN, LEAVE SCREEN and LEAVE TO SCREEN' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' title = 'ZCL_GG_EX_58' ) ).
    io_builder->end_screen( ).
    io_builder->begin_screen( VALUE #( number = '0200' title = 'ZCL_GG_EX_58' ) ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_flow_logic.
    io_builder->begin_screen( '0100' ).
    io_builder->begin_pbo( ).
    io_builder->add_module( VALUE #( name = 'STATUS_0100' ) ).
    io_builder->end_processing( ).
    io_builder->begin_pai( ).
    io_builder->add_module( VALUE #( name = 'USER_COMMAND_0100' on_input = abap_true ) ).
    io_builder->end_processing( ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA(lo_dialog) = io_session->get_dialog( ).

    CASE is_context-ucomm.
      WHEN 'NEXT'.
        lo_dialog->set_next_screen( '0200' ).
        lo_dialog->leave_screen( ).
      WHEN 'BACK'.
        lo_dialog->leave_to_screen( '0000' ).
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    IF is_context-screen = '0100'.
      io_session->get_dialog( )->set_status( VALUE #(
        status = 'SCREEN FLOW'
        active_ucomm = VALUE #( ( 'NEXT' ) ) ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    RETURN.
  ENDMETHOD.

ENDCLASS.
