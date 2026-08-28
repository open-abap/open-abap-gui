CLASS zcl_gg_integration_dynpro DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.

ENDCLASS.

CLASS zcl_gg_integration_dynpro IMPLEMENTATION.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' ) ).
    io_builder->end_screen( ).
    io_builder->begin_screen( VALUE #( number = '0200' ) ).
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
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    INSERT VALUE #( name = 'PBO_0100' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'PBO_0200' ) INTO TABLE ct_values.
    INSERT VALUE #( name = 'PAI_0100' ) INTO TABLE ct_values.
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
      WHEN '0200'.
        ct_values[ name = 'PBO_0200' ]-value = 'X'.
        ct_values[ name = 'P_STATE' ]-value = 'SCREEN_0200'.
        io_session->get_list( )->get_writer( )->write_field(
          VALUE #( text = 'Dynpro list after navigation'
                   placement = VALUE #( new_line = abap_true ) ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    ct_values[ name = 'PAI_0100' ]-value = 'X'.
    ct_values[ name = 'PAI_FIELD' ]-value = is_context-field.
    ct_values[ name = 'PAI_TABLE' ]-value = is_context-table_control.
    ct_values[ name = 'PAI_ROW' ]-value = |{ is_context-row }|.
    ct_values[ name = 'PAI_LOOP' ]-value = |{ is_context-loop_lines }|.
    ct_values[ name = 'PAI_CURSOR' ]-value = is_context-cursor_field.
    ct_values[ name = 'PAI_CURSOR_ROW' ]-value = |{ is_context-cursor_row }|.
    CASE is_context-ucomm.
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
