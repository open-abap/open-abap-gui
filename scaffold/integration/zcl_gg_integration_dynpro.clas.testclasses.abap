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

ENDCLASS.
