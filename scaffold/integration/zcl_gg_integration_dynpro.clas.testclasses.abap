CLASS ltcl_gg_integration_dyn DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS calls_next_screen FOR TESTING.
    METHODS asserts_screen_sequence FOR TESTING.
    METHODS runs_pbo_on_entry FOR TESTING.
    METHODS runs_pai_on_leave FOR TESTING.
    METHODS handles_back_navigation FOR TESTING.
    METHODS retains_back_state FOR TESTING.
    METHODS combines_list_navigation FOR TESTING.
    METHODS isolates_list_state FOR TESTING.
    METHODS returns_html_page FOR TESTING.
    METHODS skips_pai_when_not_submitted FOR TESTING.
    METHODS renders_control_families FOR TESTING.
    METHODS maps_module_context FOR TESTING.
    METHODS drives_pov_and_poh FOR TESTING.
    METHODS retains_builder_flow_ops FOR TESTING.
    METHODS renders_editable_input FOR TESTING.
    METHODS retains_entered_input FOR TESTING.
    METHODS reaches_terminal_state FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_integration_dyn IMPLEMENTATION.

  METHOD calls_next_screen.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_ucomm = 'NEXT' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-screen
      exp = '0200' ).
  ENDMETHOD.

  METHOD asserts_screen_sequence.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_ucomm = 'NEXT' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-terminal
      exp = 'LEAVE SCREEN' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_STATE' ]-value
      exp = 'SCREEN_0200' ).
  ENDMETHOD.

  METHOD runs_pbo_on_entry.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_ucomm = 'NEXT' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'PBO_0200' ]-value
      exp = 'X' ).
  ENDMETHOD.

  METHOD runs_pai_on_leave.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_ucomm = 'NEXT' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'PAI_0100' ]-value
      exp = 'X' ).
  ENDMETHOD.

  METHOD handles_back_navigation.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_ucomm = 'BACK' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-screen
      exp = '0000' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-terminal
      exp = 'LEAVE TO SCREEN 0000' ).
  ENDMETHOD.

  METHOD retains_back_state.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_ucomm = 'BACK' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_STATE' ]-value
      exp = 'SCREEN_0100' ).
    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'PBO_0200' ]-value ).
  ENDMETHOD.

  METHOD combines_list_navigation.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_ucomm = 'LIST' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `Dynpro list before navigation` )
        ( `Dynpro list after navigation` ) ) ).
  ENDMETHOD.

  METHOD isolates_list_state.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_ucomm = 'BACK' ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

  METHOD returns_html_page.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_ucomm = 'BACK' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-page_kind
      exp = zif_gg_host_html_v1=>page_dynpro ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '<!doctype html>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-page-kind="DYNPRO"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '<form method="post" action="/dispatch"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'name="action" value="SUBMIT"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'aria-label="Dynpro' ) ).
  ENDMETHOD.

  METHOD skips_pai_when_not_submitted.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_submitted = abap_false ).

    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'PAI_0100' ]-value ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '<!doctype html>' ) ).
  ENDMETHOD.

  METHOD renders_control_families.
    DATA ls_screen TYPE zif_gg_dynpro_types_v1=>ty_screen.
    DATA lt_controls TYPE zcl_gg_host_dynpro_builder=>ty_controls.
    DATA lt_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    DATA lt_states TYPE zif_gg_dynpro_types_v1=>ty_states.
    ls_screen-number = '0100'.
    ls_screen-title = 'Controls'.
    ls_screen-height = 120.
    APPEND VALUE #( screen = '0100' kind = 'CHECKBOX' name = 'C'
                    text = 'Check' position = VALUE #( column = 1 row = 1 ) ) TO lt_controls.
    APPEND VALUE #( screen = '0100' kind = 'RADIOBUTTON' name = 'R'
                    group = 'G' text = 'Radio' position = VALUE #( column = 1 row = 2 ) ) TO lt_controls.
    APPEND VALUE #( screen = '0100' kind = 'PUSHBUTTON' name = 'B'
                    ucomm = 'GO' text = 'Go' position = VALUE #( column = 1 row = 3 ) ) TO lt_controls.
    APPEND VALUE #( screen = '0100' kind = 'TABLE_CONTROL' name = 'TC'
                    visible_rows = 2 position = VALUE #( column = 1 row = 4 ) ) TO lt_controls.
    APPEND VALUE #( screen = '0100' kind = 'TABLE_COLUMN' name = 'COL'
                    parent = 'TC' column_title = 'Column' input = abap_true ) TO lt_controls.
    APPEND VALUE #( screen = '0100' kind = 'INPUT' name = 'IN'
                    text = 'Input' position = VALUE #( column = 1 row = 6 ) ) TO lt_controls.
    INSERT VALUE #( container = 'TC' name = 'COL' row = 1 value = '<cell>' ) INTO TABLE lt_values.
    INSERT VALUE #( name = 'IN' value = 'value' ) INTO TABLE lt_values.
    DATA(lv_html) = zcl_gg_host_renderer=>render_dynpro(
      iv_session_id = 'S'
      iv_page_id = 'P'
      is_screen = ls_screen
      it_controls = lt_controls
      it_values = lt_values
      it_states = lt_states
      is_cursor = VALUE #( field = 'IN' row = 0 ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'type="checkbox"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'name="gg-radio-G"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-table-control="gg-dynpro-control-n-TC"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;cell&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<section class="gg-dynpro"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'name="IN"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'autofocus' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '</form></section>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<form method="post"><section' ) ).
  ENDMETHOD.

  METHOD maps_module_context.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_ucomm = 'CONTEXT'
      iv_field = 'COL'
      iv_row = 2
      iv_cursor_field = 'COL'
      iv_cursor_row = 2
      it_values = VALUE #( ( container = 'TC' name = 'COL' row = 2 value = 'cell' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'PAI_FIELD' ]-value
      exp = 'COL' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'PAI_TABLE' ]-value
      exp = 'TC' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'PAI_ROW' ]-value
      exp = '2' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'PAI_LOOP' ]-value
      exp = '1' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'PAI_CURSOR' ]-value
      exp = 'COL' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'PAI_CURSOR_ROW' ]-value
      exp = '2' ).
  ENDMETHOD.

  METHOD drives_pov_and_poh.
    DATA(ls_value_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_submitted = abap_false
      iv_value_request = 'P_INPUT' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_value_result-help_values[ name = 'POV_VALUE' ]-value
      exp = 'Value from POV' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_value_result-html CS 'gg-value-help' ) ).

    DATA(ls_help_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_submitted = abap_false
      iv_help_request = 'P_INPUT' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_help_result-help_text
      exp = 'Help from POH' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_help_result-html CS 'Help from POH' ) ).
  ENDMETHOD.

  METHOD retains_builder_flow_ops.
    DATA(lo_builder) = NEW zcl_gg_host_dynpro_builder( ).
    lo_builder->zif_gg_dynpro_builder_v1~begin_screen( VALUE #( number = '0100' ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_input_field( VALUE #( control = VALUE #( name = 'I' ) ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_output_field( VALUE #( control = VALUE #( name = 'O' ) ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_text( VALUE #( control = VALUE #( name = 'T' ) text = 'Text' ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_pushbutton( VALUE #( control = VALUE #( name = 'B' ) ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_checkbox( VALUE #( control = VALUE #( name = 'C' ) ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_radiobutton( VALUE #( control = VALUE #( name = 'R' ) ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_listbox( VALUE #( control = VALUE #( name = 'L' ) ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_box( VALUE #( control = VALUE #( name = 'X' ) ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_subscreen_area( VALUE #( control = VALUE #( name = 'S' ) ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_custom_control( VALUE #( control = VALUE #( name = 'U' ) ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_tabstrip( VALUE #( control = VALUE #( name = 'TS' ) ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_tab( VALUE #( control = VALUE #( name = 'TAB' ) ) ).
    lo_builder->zif_gg_dynpro_builder_v1~begin_table_control( VALUE #( control = VALUE #( name = 'TC' ) ) ).
    lo_builder->zif_gg_dynpro_builder_v1~add_table_column( VALUE #( table_control = 'TC' name = 'COL' ) ).
    lo_builder->zif_gg_dynpro_builder_v1~end_table_control( ).
    lo_builder->zif_gg_dynpro_builder_v1~end_screen( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_builder->get_controls( ) ) exp = 14 ).

    DATA(lo_flow) = NEW zcl_gg_host_dynpro_flow( ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~begin_screen( '0100' ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~begin_pbo( ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~add_field( 'I' ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~add_module( VALUE #( name = 'PBO' ) ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~end_processing( ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~begin_pai( ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~begin_chain( ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~begin_table_loop( VALUE #( table_control = 'TC' ) ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~add_field( 'COL' ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~end_table_loop( ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~end_chain( ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~add_module( VALUE #( name = 'PAI' ) ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~end_processing( ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~begin_value_request( 'I' ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~add_module( VALUE #( name = 'POV' ) ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~end_processing( ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~begin_help_request( 'I' ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~add_module( VALUE #( name = 'POH' ) ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~end_processing( ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~call_subscreen( VALUE #( area = 'S' screen = '0200' ) ).
    lo_flow->zif_gg_dynpro_flow_builder_v1~end_screen( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lines( lo_flow->get_steps( ) ) >= 18 ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lo_flow->get_modules( ) ) exp = 4 ).
  ENDMETHOD.

  METHOD renders_editable_input.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_submitted = abap_false ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'name="P_INPUT"' ) ).
    cl_abap_unit_assert=>assert_true( ls_result-controls[ name = 'P_INPUT' ]-value_help ).
    cl_abap_unit_assert=>assert_true( ls_result-states[ name = 'P_INPUT' ]-enabled ).
  ENDMETHOD.

  METHOD retains_entered_input.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_ucomm = 'NEXT'
      it_values = VALUE #( ( name = 'P_INPUT' value = 'entered flight' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_INPUT' ]-value
      exp = 'entered flight' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen exp = '0200' ).
  ENDMETHOD.

  METHOD reaches_terminal_state.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_integration_dynpro( )
      iv_ucomm = 'EXIT' ).

    cl_abap_unit_assert=>assert_true( ls_result-terminal_state ).
  ENDMETHOD.

ENDCLASS.
