* A report that opens its own screen 2000 with CALL SCREEN, as a converted
* maintenance report does. Back on the screen runs LEAVE TO SCREEN 0. With a
* selection screen, the CALL SCREEN runs on Execute, not when it starts.
CLASS lcl_called_screen DEFINITION CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_screen_provider_v1.
    INTERFACES zif_gg_resumable_v1.

    METHODS constructor
      IMPORTING
        iv_write_after TYPE abap_bool
        iv_selection   TYPE abap_bool DEFAULT abap_false.

  PROTECTED SECTION.
    DATA mv_write_after TYPE abap_bool.
    DATA mv_selection TYPE abap_bool.

ENDCLASS.

CLASS lcl_called_screen IMPLEMENTATION.

  METHOD constructor.
    mv_write_after = iv_write_after.
    mv_selection = iv_selection.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_dialog( )->call_screen(
      is_call         = VALUE #( screen = '2000' )
      is_continuation = VALUE #( id = 'AFTER_2000' ) ).
  ENDMETHOD.

  METHOD zif_gg_resumable_v1~resume.
    IF is_resume-continuation-id = 'AFTER_2000' AND mv_write_after = abap_true.
      io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'after 2000' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~get_initial_screen.
    rv_screen = '2000'.
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '2000' title = 'Maintain' ) ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~build_flow_logic.
    io_builder->begin_screen( '2000' ).
    io_builder->begin_pbo( ).
    io_builder->add_module( VALUE #( name = 'STATUS_2000' ) ).
    io_builder->end_processing( ).
    io_builder->begin_pai( ).
    io_builder->add_module( VALUE #( name = 'USER_COMMAND_2000' on_input = abap_true ) ).
    io_builder->end_processing( ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~initialization.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~process_output_module.
    io_session->get_dialog( )->set_title( 'Maintain' ).
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~process_input_module.
    IF is_context-ucomm = 'BACK'.
      io_session->get_dialog( )->leave_to_screen( '0000' ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~process_on_value_request.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_screen_provider_v1~process_on_help_request.
    RETURN.
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
    IF mv_selection = abap_true.
      io_builder->add_parameter( VALUE #(
        name      = 'P_LOG'
        text      = 'Log'
        data_type = VALUE #( typ = 'C' length = 10 ) ) ).
    ENDIF.
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

* A report whose START-OF-SELECTION calls transaction ZGG_EX_058, which
* leaves to screen 0 on Back, and writes once it has returned.
CLASS lcl_calling_report DEFINITION INHERITING FROM lcl_called_screen FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS zif_gg_report_v1~start_of_selection REDEFINITION.
    METHODS zif_gg_resumable_v1~resume REDEFINITION.

ENDCLASS.

CLASS lcl_calling_report IMPLEMENTATION.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_navigation( )->call_transaction(
      is_call         = VALUE #( tcode = 'ZGG_EX_058' )
      is_continuation = VALUE #( id = 'AFTER_TCODE' ) ).
  ENDMETHOD.

  METHOD zif_gg_resumable_v1~resume.
    IF is_resume-continuation-id = 'AFTER_TCODE'.
      io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'returned from ZGG_EX_058' ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

* A dialog transaction whose GO calls ZGG_EX_058 and counts the returns, as a
* cockpit dispatching to its tools does. Back leaves the program.
CLASS lcl_cockpit DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_resumable_v1.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_row,
             tool TYPE c LENGTH 20,
           END OF ty_row.

    DATA mv_returns TYPE i.
    DATA mo_grid TYPE REF TO cl_gui_alv_grid.
    DATA mt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.

ENDCLASS.

CLASS lcl_cockpit IMPLEMENTATION.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' title = 'Cockpit' ) ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_flow_logic.
    io_builder->begin_screen( '0100' ).
    io_builder->begin_pbo( ).
    io_builder->add_module( VALUE #( name = 'STATUS_0100' ) ).
    io_builder->end_processing( ).
    io_builder->begin_pai( ).
    io_builder->add_module( VALUE #( name = 'USER_COMMAND_0100' ) ).
    io_builder->end_processing( ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    io_session->get_dialog( )->set_title( |Cockpit, { mv_returns } returns| ).
    io_session->get_dialog( )->set_status( VALUE #( status = 'COCKPIT' active_ucomm = VALUE #( ( 'GO' ) ( 'MISSING' ) ) ) ).
* The grid is created once, as a cockpit's PBO does.
    IF mo_grid IS BOUND.
      RETURN.
    ENDIF.
    DATA(lt_fcat) = VALUE lvc_t_fcat( ( fieldname = 'TOOL' coltext = 'Tool' inttype = 'C' ) ).
    mt_rows = VALUE #( ( tool = 'ZCOCKPIT_TOOL' ) ).
    mo_grid = NEW cl_gui_alv_grid( i_parent = cl_gui_container=>default_screen ).
    mo_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = mt_rows
        it_fieldcatalog = lt_fcat ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    CASE is_context-ucomm.
      WHEN 'GO'.
        io_session->get_navigation( )->call_transaction(
          is_call         = VALUE #( tcode = 'ZGG_EX_058' )
          is_continuation = VALUE #( id = 'AFTER_TCODE' ) ).
      WHEN 'MISSING'.
        io_session->get_navigation( )->call_transaction(
          is_call         = VALUE #( tcode = 'ZGG_NO_SUCH_TCODE' )
          is_continuation = VALUE #( id = 'AFTER_MISSING' ) ).
      WHEN 'BACK'.
        io_session->get_navigation( )->leave_program( ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_resumable_v1~resume.
    IF is_resume-continuation-id = 'AFTER_TCODE'.
      mv_returns = mv_returns + 1.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    RETURN.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_runtime DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    METHODS opens_called_screen FOR TESTING.
    METHODS screen_0_continues_report FOR TESTING.
    METHODS screen_0_ends_empty_report FOR TESTING.
    METHODS execute_opens_called_screen FOR TESTING.
    METHODS called_transaction_returns FOR TESTING.
    METHODS report_resumes_after_call FOR TESTING.
    METHODS unknown_transaction_is_named FOR TESTING.
    METHODS back_leaves_first_list FOR TESTING.

    METHODS back
      IMPORTING
        is_page            TYPE zif_gg_host_html_v1=>ty_response
      RETURNING
        VALUE(rs_response) TYPE zif_gg_host_html_v1=>ty_response.

    METHODS command
      IMPORTING
        is_page            TYPE zif_gg_host_html_v1=>ty_response
        iv_ucomm           TYPE string
      RETURNING
        VALUE(rs_response) TYPE zif_gg_host_html_v1=>ty_response.

ENDCLASS.

CLASS ltcl_runtime IMPLEMENTATION.

  METHOD teardown.
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD back.
    rs_response = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = is_page-session_id
      page_id    = is_page-page_id
      action     = zif_gg_host_html_v1=>action_back
      ucomm      = 'BACK' ) ).
  ENDMETHOD.

  METHOD command.
    rs_response = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = is_page-session_id
      page_id    = is_page-page_id
      action     = zif_gg_host_html_v1=>action_submit
      ucomm      = iv_ucomm ) ).
  ENDMETHOD.

  METHOD opens_called_screen.
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW lcl_called_screen( abap_true ) ).

    cl_abap_unit_assert=>assert_equals( act = ls_start-page_kind
                                        exp = zif_gg_host_html_v1=>page_dynpro ).
    cl_abap_unit_assert=>assert_equals( act = ls_start-current_page-screen
                                        exp = '2000' ).
  ENDMETHOD.

  METHOD screen_0_continues_report.
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW lcl_called_screen( abap_true ) ).

    DATA(ls_back) = back( ls_start ).

    cl_abap_unit_assert=>assert_true( ls_back-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_back-page_kind
                                        exp = zif_gg_host_html_v1=>page_list ).
    cl_abap_unit_assert=>assert_true( act = xsdbool(
      line_exists( ls_back-compatibility-lines[ table_line = 'after 2000' ] ) ) ).
  ENDMETHOD.

  METHOD screen_0_ends_empty_report.
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW lcl_called_screen( abap_false ) ).

    DATA(ls_back) = back( ls_start ).

    cl_abap_unit_assert=>assert_true( ls_back-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_back-page_kind
                                        exp = zif_gg_host_html_v1=>page_terminal ).
    cl_abap_unit_assert=>assert_true( ls_back-current_page-terminal ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_back-html CS 'Maintain' ) ).
* Nothing called the report, so the client returns to where it started it.
    cl_abap_unit_assert=>assert_true( ls_back-ended ).

    DATA(ls_after) = back( ls_back ).
    cl_abap_unit_assert=>assert_false( ls_after-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_after-error
                                        exp = 'Host session is terminal' ).
  ENDMETHOD.

  METHOD execute_opens_called_screen.
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW lcl_called_screen(
      iv_write_after = abap_false
      iv_selection   = abap_true ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_start-page_kind
                                        exp = zif_gg_host_html_v1=>page_selection ).

    DATA(ls_execute) = command( is_page  = ls_start
                                iv_ucomm = 'ONLI' ).

* Execute runs START-OF-SELECTION, whose CALL SCREEN opens screen 2000 with
* its PBO, not a pause page or the report's list.
    cl_abap_unit_assert=>assert_true( ls_execute-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_execute-page_kind
                                        exp = zif_gg_host_html_v1=>page_dynpro ).
    cl_abap_unit_assert=>assert_equals( act = ls_execute-current_page-screen
                                        exp = '2000' ).
    cl_abap_unit_assert=>assert_equals( act = ls_execute-current_page-title
                                        exp = 'Maintain' ).

* Screen 0 resumes the report, which ends without a list and shows its
* selection screen again; Back there leaves the program.
    DATA(ls_back) = back( ls_execute ).
    cl_abap_unit_assert=>assert_equals( act = ls_back-page_kind
                                        exp = zif_gg_host_html_v1=>page_selection ).
    cl_abap_unit_assert=>assert_false( ls_back-ended ).
    DATA(ls_leave) = back( ls_back ).
    cl_abap_unit_assert=>assert_true( ls_leave-valid ).
    cl_abap_unit_assert=>assert_true( ls_leave-ended ).
  ENDMETHOD.

  METHOD called_transaction_returns.
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_dynpro_program = NEW lcl_cockpit( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_start-current_page-title
                                        exp = 'Cockpit, 0 returns' ).

    DATA(ls_called) = command( is_page  = ls_start
                               iv_ucomm = 'GO' ).
    cl_abap_unit_assert=>assert_true( ls_called-valid ).
    cl_abap_unit_assert=>assert_differs( act = ls_called-session_id
                                         exp = ls_start-session_id ).
    cl_abap_unit_assert=>assert_equals( act = ls_called-current_page-title
                                        exp = 'Order 4711' ).

* The called transaction leaves to screen 0, which ends it: the cockpit
* resumes after its CALL TRANSACTION and shows its screen again.
    DATA(ls_returned) = back( ls_called ).
    cl_abap_unit_assert=>assert_true( ls_returned-valid ).
    cl_abap_unit_assert=>assert_false( ls_returned-ended ).
    cl_abap_unit_assert=>assert_equals( act = ls_returned-session_id
                                        exp = ls_start-session_id ).
    cl_abap_unit_assert=>assert_equals( act = ls_returned-current_page-title
                                        exp = 'Cockpit, 1 returns' ).
* Its grid, created before the call, is still on the screen.
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_start-html CS 'ZCOCKPIT_TOOL' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_called-html CS 'ZCOCKPIT_TOOL' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_returned-html CS 'ZCOCKPIT_TOOL' ) ).

* A second call returns the same way; Back then ends the cockpit itself.
    DATA(ls_again) = back( command( is_page  = ls_returned
                                    iv_ucomm = 'GO' ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_again-current_page-title
                                        exp = 'Cockpit, 2 returns' ).
    DATA(ls_leave) = back( ls_again ).
    cl_abap_unit_assert=>assert_true( ls_leave-ended ).
  ENDMETHOD.

  METHOD report_resumes_after_call.
    DATA(ls_called) = zcl_gg_host_runtime=>start( io_report = NEW lcl_calling_report( abap_false ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_called-current_page-title
                                        exp = 'Order 4711' ).

    DATA(ls_returned) = back( ls_called ).

    cl_abap_unit_assert=>assert_equals( act = ls_returned-page_kind
                                        exp = zif_gg_host_html_v1=>page_list ).
    cl_abap_unit_assert=>assert_true( act = xsdbool(
      line_exists( ls_returned-compatibility-lines[ table_line = 'returned from ZGG_EX_058' ] ) ) ).
    cl_abap_unit_assert=>assert_false( ls_returned-ended ).
  ENDMETHOD.

  METHOD unknown_transaction_is_named.
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_dynpro_program = NEW lcl_cockpit( ) ).

    DATA(ls_missing) = command( is_page  = ls_start
                                iv_ucomm = 'MISSING' ).

    cl_abap_unit_assert=>assert_false( ls_missing-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_missing-error
      exp = 'Transaction ZGG_NO_SUCH_TCODE does not exist or is not available in this runtime.' ).
  ENDMETHOD.

  METHOD back_leaves_first_list.
    DATA(ls_list) = zcl_gg_host_runtime=>start( io_report = NEW lcl_called_screen( abap_true ) ).
    DATA(ls_back) = back( back( ls_list ) ).

    cl_abap_unit_assert=>assert_true( ls_back-valid ).
    cl_abap_unit_assert=>assert_true( ls_back-ended ).
  ENDMETHOD.

ENDCLASS.
