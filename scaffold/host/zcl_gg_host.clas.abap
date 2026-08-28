CLASS zcl_gg_host DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Drives one run of an executable program written against zif_gg_report_v1 and
* returns what came out of it.
*
* Covered so far: LOAD-OF-PROGRAM, the screen definition and its defaults,
* INITIALIZATION, START-OF-SELECTION, END-OF-SELECTION, STOP, MESSAGE and the
* classic list. A selection screen is described but never displayed, and the
* interactive, navigating and logical database paths are not driven yet; see
* examples/PLAN.md for which phase brings each of them.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_result,
             lines       TYPE zcl_gg_host_list=>ty_text_lines,
             messages    TYPE zcl_gg_host_session=>ty_messages,
             values      TYPE zif_gg_selection_screen_types=>ty_values,
             blocks      TYPE zcl_gg_host_screen=>ty_blocks,
             title       TYPE string,
             unsupported TYPE string,
           END OF ty_result.

    CLASS-METHODS run
      IMPORTING
        io_report        TYPE REF TO zif_gg_report_v1
        iv_program       TYPE zif_gg_session_types_v1=>ty_program OPTIONAL
        iv_batch         TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rs_result) TYPE ty_result.

ENDCLASS.

CLASS zcl_gg_host IMPLEMENTATION.

  METHOD run.
    DATA lt_values  TYPE zif_gg_selection_screen_types=>ty_values.
    DATA lv_ended   TYPE abap_bool.
    DATA lo_handler TYPE REF TO zif_gg_list_processing_v1.
    DATA lo_list    TYPE REF TO zcl_gg_host_list.
    DATA lo_screen  TYPE REF TO zcl_gg_host_screen.
    DATA lo_session TYPE REF TO zcl_gg_host_session.
    DATA lx_flow    TYPE REF TO zcx_gg_control_flow.

    lo_list   = NEW zcl_gg_host_list( ).
    lo_screen = NEW zcl_gg_host_screen( ).
    lo_session = NEW zcl_gg_host_session(
      io_list    = lo_list
      iv_program = iv_program
      iv_batch   = iv_batch ).

    TRY.
        lo_session->set_event( 'LOAD-OF-PROGRAM' ).
        io_report->load_of_program( lo_session ).

        io_report->build_screen( lo_screen ).
        lt_values = lo_screen->get_values( ).

        lo_handler = io_report->get_list_processing( lo_session ).
        lo_list->set_handler(
          io_session = lo_session
          io_handler = lo_handler ).
        IF lo_handler IS BOUND.
          lo_list->apply_settings( lo_handler->get_settings( lo_session ) ).
        ENDIF.

        lo_session->set_event( 'INITIALIZATION' ).
        io_report->initialization(
          EXPORTING
            io_session = lo_session
          CHANGING
            ct_values  = lt_values ).

        lo_session->set_event( 'START-OF-SELECTION' ).
        io_report->start_of_selection(
          it_values  = lt_values
          io_session = lo_session ).
      CATCH zcx_gg_control_flow INTO lx_flow.
        lv_ended = xsdbool( lx_flow->mv_kind <> zcx_gg_control_flow=>kind_stop ).
        IF lx_flow->mv_kind = zcx_gg_control_flow=>kind_unsupported.
          rs_result-unsupported = lx_flow->mv_operation.
        ENDIF.
    ENDTRY.

    IF lv_ended = abap_false.
      TRY.
          lo_session->set_event( 'END-OF-SELECTION' ).
          io_report->end_of_selection(
            it_values  = lt_values
            io_session = lo_session ).
        CATCH zcx_gg_control_flow INTO lx_flow.
          IF lx_flow->mv_kind = zcx_gg_control_flow=>kind_unsupported.
            rs_result-unsupported = lx_flow->mv_operation.
          ENDIF.
      ENDTRY.
    ENDIF.

    rs_result-lines    = lo_list->finish_output( ).
    rs_result-messages = lo_session->get_messages( ).
    rs_result-values   = lt_values.
    rs_result-blocks   = lo_screen->get_blocks( ).
    rs_result-title    = lo_list->get_title( ).
  ENDMETHOD.

ENDCLASS.
