CLASS zcl_gg_integration_dynpro DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.

ENDCLASS.

CLASS zcl_gg_integration_dynpro IMPLEMENTATION.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' title = 'Flight input' ) ).
    io_builder->add_input_field( VALUE #(
      control = VALUE #( name = 'P_INPUT' position = VALUE #( row = 1 column = 1 width = 20 ) )
      data_type = VALUE #( typ = 'C' length = 20 )
      search_help = 'P_INPUT'
      value_help = abap_true
      required = abap_true ) ).
    io_builder->add_pushbutton( VALUE #(
      control = VALUE #( name = 'NEXT_BUTTON' position = VALUE #( row = 2 column = 1 width = 10 ) )
      text = 'Next'
      ucomm = 'NEXT' ) ).
    io_builder->end_screen( ).
    io_builder->begin_screen( VALUE #( number = '0200' title = 'Flight result' ) ).
    io_builder->add_output_field( VALUE #(
      control = VALUE #( name = 'P_INPUT' position = VALUE #( row = 1 column = 1 width = 20 ) )
      data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->add_pushbutton( VALUE #(
      control = VALUE #( name = 'EXIT_BUTTON' position = VALUE #( row = 2 column = 1 width = 10 ) )
      text = 'Exit'
      ucomm = 'EXIT' ) ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_flow_logic.
    io_builder->begin_screen( '0100' ).
    io_builder->begin_pbo( ).
    io_builder->add_module( VALUE #( name = 'PBO_0100' ) ).
    io_builder->end_processing( ).
    io_builder->begin_pai( ).
    io_builder->add_module( VALUE #( name = 'PAI_0100' on_input = abap_true ) ).
    io_builder->end_processing( ).
    io_builder->begin_value_request( 'P_INPUT' ).
    io_builder->add_module( VALUE #( name = 'POV_0100' ) ).
    io_builder->end_processing( ).
    io_builder->begin_help_request( 'P_INPUT' ).
    io_builder->add_module( VALUE #( name = 'POH_0100' ) ).
    io_builder->end_processing( ).
    io_builder->end_screen( ).

    io_builder->begin_screen( '0200' ).
    io_builder->begin_pbo( ).
    io_builder->add_module( VALUE #( name = 'PBO_0200' ) ).
    io_builder->end_processing( ).
    io_builder->begin_pai( ).
    io_builder->add_module( VALUE #( name = 'PAI_0200' on_input = abap_true ) ).
    io_builder->end_processing( ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    INSERT VALUE #( name = 'PBO_0100' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'PBO_0200' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'PAI_0100' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'PAI_0200' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'P_INPUT' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'PAI_FIELD' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'PAI_TABLE' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'PAI_ROW' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'PAI_LOOP' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'PAI_CURSOR' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'PAI_CURSOR_ROW' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'P_STATE' value = 'INITIAL' ) INTO TABLE ct_values.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    CASE is_context-screen.
      WHEN '0100'.
        ct_values[ name = 'PBO_0100' ]-value = 'X'.
        ct_values[ name = 'P_STATE' ]-value = 'SCREEN_0100'.
        io_session->get_dialog( )->set_status( VALUE #(
          status = 'FLIGHT INPUT'
          active_ucomm = VALUE #( ( 'NEXT' ) ( 'LIST' ) ( 'CONTEXT' ) ( 'EXIT' ) ) ) ).
      WHEN '0200'.
        ct_values[ name = 'PBO_0200' ]-value = 'X'.
        ct_values[ name = 'P_STATE' ]-value = 'SCREEN_0200'.
        io_session->get_dialog( )->set_status( VALUE #(
          status = 'FLIGHT RESULT'
          active_ucomm = VALUE #( ( 'EXIT' ) ) ) ).
        io_session->get_list( )->get_writer( )->write_field(
          VALUE #( text = 'Dynpro list after navigation'
                   placement = VALUE #( new_line = abap_true ) ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    IF is_context-screen = '0200'.
      ct_values[ name = 'PAI_0200' ]-value = 'X'.
      IF is_context-ucomm = 'EXIT'.
        io_session->get_navigation( )->leave_program( ).
      ENDIF.
      RETURN.
    ENDIF.

    ct_values[ name = 'PAI_0100' ]-value = 'X'.
    ct_values[ name = 'PAI_FIELD' ]-value = is_context-field.
    ct_values[ name = 'PAI_TABLE' ]-value = is_context-table_control.
    ct_values[ name = 'PAI_ROW' ]-value = |{ is_context-row }|.
    ct_values[ name = 'PAI_LOOP' ]-value = |{ is_context-loop_lines }|.
    ct_values[ name = 'PAI_CURSOR' ]-value = is_context-cursor_field.
    ct_values[ name = 'PAI_CURSOR_ROW' ]-value = |{ is_context-cursor_row }|.
    CASE is_context-ucomm.
      WHEN 'EXIT'.
        io_session->get_navigation( )->leave_program( ).
      WHEN 'NEXT' OR 'LIST'.
        io_session->get_dialog( )->set_next_screen( '0200' ).
        IF is_context-ucomm = 'LIST'.
          io_session->get_list( )->get_writer( )->write_field(
            VALUE #( text = 'Dynpro list before navigation'
                     placement = VALUE #( new_line = abap_true ) ) ).
        ENDIF.
        io_session->get_dialog( )->leave_screen( ).
      WHEN 'BACK'.
        io_session->get_dialog( )->leave_to_screen( '0000' ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    IF is_context-module = 'POV_0100'.
      rt_values = VALUE #( ( name = 'POV_VALUE' value = 'Value from POV' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    IF is_context-module = 'POH_0100'.
      rv_text = 'Help from POH'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
