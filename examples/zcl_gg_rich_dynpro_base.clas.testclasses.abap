CLASS ltcl_gg_rich_dynpro_base DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS controls FOR TESTING.
    METHODS pbo_pai_transport FOR TESTING.
    METHODS cursor_error FOR TESTING.
    METHODS pov_poh FOR TESTING.
    METHODS dynamic_states FOR TESTING.
    METHODS chain_validation FOR TESTING.
    METHODS table_control FOR TESTING.
    METHODS editable_table FOR TESTING.
    METHODS table_scroll FOR TESTING.
    METHODS subscreen FOR TESTING.
    METHODS tabs FOR TESTING.
    METHODS modal FOR TESTING.
    METHODS nested FOR TESTING.
    METHODS screen_transfer FOR TESTING.
    METHODS command_semantics FOR TESTING.
    METHODS messages FOR TESTING.
    METHODS status_by_screen FOR TESTING.
    METHODS flight_editor FOR TESTING.
    METHODS rejects_undeclared_command FOR TESTING.
ENDCLASS.

CLASS ltcl_gg_rich_dynpro_base IMPLEMENTATION.

  METHOD controls.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program   = NEW zcl_gg_ex_099( )
                                               iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-controls[ kind = 'INPUT' ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-controls[ kind = 'OUTPUT' ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-controls[ kind = 'CHECKBOX' ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-controls[ kind = 'RADIOBUTTON' ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-controls[ kind = 'LISTBOX' ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-controls[ kind = 'BOX' ] ) ) ).
  ENDMETHOD.

  METHOD pbo_pai_transport.
    DATA lo_program TYPE REF TO zif_gg_dynpro_v1.
    lo_program = NEW zcl_gg_ex_100( ).
    DATA(ls_initial) = zcl_gg_host_dynpro=>run( io_program   = lo_program
                                                iv_submitted = abap_false ).
    ls_initial-values[ name = 'P_INPUT' ]-value = 'edited'.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = lo_program
      iv_ucomm   = 'APPLY'
      it_values  = ls_initial-values ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_OUTPUT' ]-value
                                        exp = 'accepted: edited' ).
  ENDMETHOD.

  METHOD cursor_error.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program = NEW zcl_gg_ex_101( )
                                               iv_ucomm   = 'VALIDATE' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-cursor-field
                                        exp = 'P_BAD' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-field
                                        exp = 'P_BAD' ).
  ENDMETHOD.

  METHOD pov_poh.
    DATA(lo_program) = NEW zcl_gg_ex_102( ).
    DATA(ls_value) = zcl_gg_host_dynpro=>run( io_program       = lo_program
                                              iv_submitted     = abap_false
                                              iv_value_request = 'P_VALUE' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_value-help_values ).
    DATA(ls_help) = zcl_gg_host_dynpro=>run( io_program      = lo_program
                                             iv_submitted    = abap_false
                                             iv_help_request = 'P_VALUE' ).
    cl_abap_unit_assert=>assert_equals( act = ls_help-help_text
                                        exp = 'Typed dynpro help for P_VALUE' ).
  ENDMETHOD.

  METHOD dynamic_states.
    DATA lo_program TYPE REF TO zif_gg_dynpro_v1.
    lo_program = NEW zcl_gg_ex_103( ).
    DATA(ls_hidden) = zcl_gg_host_dynpro=>run( io_program   = lo_program
                                               iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_false( act = ls_hidden-states[ name = 'P_DEP' ]-visible ).
    ls_hidden-values[ name = 'P_ENABLE' ]-value = 'X'.
    DATA(ls_visible) = zcl_gg_host_dynpro=>run( io_program   = lo_program
                                                iv_submitted = abap_false
                                                it_values    = ls_hidden-values ).
    cl_abap_unit_assert=>assert_true( act = ls_visible-states[ name = 'P_DEP' ]-visible ).
    cl_abap_unit_assert=>assert_true( act = ls_visible-states[ name = 'P_DEP' ]-required ).
  ENDMETHOD.

  METHOD chain_validation.
    DATA(ls_error) = zcl_gg_host_dynpro=>run( io_program = NEW zcl_gg_ex_104( )
                                              iv_ucomm   = 'CHECK' ).
    cl_abap_unit_assert=>assert_equals( act = ls_error-messages[ 1 ]-field
                                        exp = 'P_RIGHT' ).
    DATA(ls_values) = ls_error-values.
    ls_values[ name = 'P_RIGHT' ]-value = ls_values[ name = 'P_LEFT' ]-value.
    DATA(ls_ok) = zcl_gg_host_dynpro=>run( io_program = NEW zcl_gg_ex_104( )
                                           iv_ucomm   = 'CHECK'
                                           it_values  = ls_values ).
    cl_abap_unit_assert=>assert_initial( act = ls_ok-messages ).
  ENDMETHOD.

  METHOD table_control.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program   = NEW zcl_gg_ex_105( )
                                               iv_submitted = abap_false ).
    DATA lv_cells TYPE i.
    LOOP AT ls_result-values INTO DATA(ls_cell) WHERE container = 'TC_FLIGHTS'.
      lv_cells = lv_cells + 1.
    ENDLOOP.
    cl_abap_unit_assert=>assert_equals( act = ls_result-controls[ kind = 'TABLE_CONTROL' ]-visible_rows
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lv_cells
                                        exp = 4 ).
  ENDMETHOD.

  METHOD editable_table.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program   = NEW zcl_gg_ex_106( )
                                               iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_true( act = ls_result-controls[ kind = 'TABLE_COLUMN' name = 'CARRID' ]-input ).
  ENDMETHOD.

  METHOD table_scroll.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program   = NEW zcl_gg_ex_107( )
                                               iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_true( act = ls_result-controls[ kind = 'TABLE_CONTROL' ]-with_vscroll ).
  ENDMETHOD.

  METHOD subscreen.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program   = NEW zcl_gg_ex_108( )
                                               iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-flow[ kind = 'SUBSCREEN' ] ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-controls[ kind = 'SUBSCREEN_AREA' ]-name
                                        exp = 'SUB_AREA' ).
  ENDMETHOD.

  METHOD tabs.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program   = NEW zcl_gg_ex_109( )
                                               iv_submitted = abap_false ).
    DATA lv_tabs TYPE i.
    LOOP AT ls_result-controls INTO DATA(ls_tab) WHERE kind = 'TAB'.
      lv_tabs = lv_tabs + 1.
    ENDLOOP.
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-controls[ kind = 'TABSTRIP' ] ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lv_tabs
                                        exp = 2 ).
  ENDMETHOD.

  METHOD modal.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program   = NEW zcl_gg_ex_110( )
                                               iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_true( act = ls_result-screens[ number = '0200' ]-modal ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screens[ number = '0100' ]-title
                                        exp = 'Parent modal 110' ).
  ENDMETHOD.

  METHOD nested.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program   = NEW zcl_gg_ex_111( )
                                               iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-screens )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-flow[ screen = '0300' ] ) ) ).
  ENDMETHOD.

  METHOD screen_transfer.
    DATA lo_program TYPE REF TO zif_gg_dynpro_v1.
    lo_program = NEW zcl_gg_ex_112( ).
    DATA(ls_next) = zcl_gg_host_dynpro=>run( io_program = lo_program
                                             iv_ucomm   = 'NEXT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_next-screen
                                        exp = '0100' ).
    DATA(ls_jump) = zcl_gg_host_dynpro=>run( io_program = lo_program
                                             iv_ucomm   = 'JUMP' ).
    cl_abap_unit_assert=>assert_equals( act = ls_jump-screen
                                        exp = '0200' ).
  ENDMETHOD.

  METHOD command_semantics.
    DATA(ls_cancel) = zcl_gg_host_dynpro=>run( io_program = NEW zcl_gg_ex_113( )
                                               iv_ucomm   = 'CANCEL' ).
    cl_abap_unit_assert=>assert_equals( act = ls_cancel-messages[ 1 ]-text
                                        exp = 'Cancelled' ).
    DATA(ls_exit) = zcl_gg_host_dynpro=>run( io_program = NEW zcl_gg_ex_113( )
                                             iv_ucomm   = 'EXIT' ).
    cl_abap_unit_assert=>assert_true( act = ls_exit-terminal_state ).
  ENDMETHOD.

  METHOD messages.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program = NEW zcl_gg_ex_114( )
                                               iv_ucomm   = 'ACTION' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-field
                                        exp = 'P_MESSAGE' ).
    DATA(ls_values) = ls_result-values.
    ls_values[ name = 'P_MESSAGE' ]-value = 'ok'.
    DATA(ls_warning) = zcl_gg_host_dynpro=>run( io_program = NEW zcl_gg_ex_114( )
                                                iv_ucomm   = 'ACTION'
                                                it_values  = ls_values ).
    cl_abap_unit_assert=>assert_equals( act = ls_warning-messages[ 1 ]-type
                                        exp = zif_gg_session_types_v1=>message_type_warning ).
  ENDMETHOD.

  METHOD status_by_screen.
    DATA lo_program TYPE REF TO zif_gg_dynpro_v1.
    lo_program = NEW zcl_gg_ex_115( ).
    DATA(ls_initial) = zcl_gg_host_dynpro=>run( io_program   = lo_program
                                                iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_equals( act = ls_initial-status-status
                                        exp = 'STATUS 0100' ).
    DATA(ls_second) = zcl_gg_host_dynpro=>run( io_program = lo_program
                                               iv_ucomm   = 'NEXT'
                                               it_values  = ls_initial-values ).
    cl_abap_unit_assert=>assert_equals( act = ls_second-screen
                                        exp = '0200' ).
    cl_abap_unit_assert=>assert_equals( act = ls_second-status-status
                                        exp = 'STATUS-0200' ).
  ENDMETHOD.

  METHOD flight_editor.
    DATA lo_program TYPE REF TO zif_gg_dynpro_v1.
    lo_program = NEW zcl_gg_ex_116( ).
    DATA(ls_initial) = zcl_gg_host_dynpro=>run( io_program   = lo_program
                                                iv_submitted = abap_false ).
    DATA(ls_editor) = zcl_gg_host_dynpro=>run( io_program = lo_program
                                               iv_ucomm   = 'EDIT'
                                               it_values  = ls_initial-values ).
    cl_abap_unit_assert=>assert_equals( act = ls_editor-screen
                                        exp = '0200' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_editor-controls[ kind = 'TABLE_CONTROL' name = 'TC_ROWS' ] ) ) ).
  ENDMETHOD.

  METHOD rejects_undeclared_command.
    DATA lt_programs TYPE STANDARD TABLE OF REF TO zif_gg_dynpro_v1 WITH DEFAULT KEY.
    APPEND NEW zcl_gg_ex_099( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_100( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_101( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_103( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_104( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_105( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_106( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_107( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_108( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_109( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_110( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_111( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_112( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_113( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_114( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_115( ) TO lt_programs.
    APPEND NEW zcl_gg_ex_116( ) TO lt_programs.
    LOOP AT lt_programs INTO DATA(lo_program).
      DATA(ls_result) = zcl_gg_host_dynpro=>run(
        io_program = lo_program
        iv_ucomm   = 'FORGED' ).
      cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( ls_result-messages[
          text = 'Command FORGED is not available on dynpro screen 0100' ] ) ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
