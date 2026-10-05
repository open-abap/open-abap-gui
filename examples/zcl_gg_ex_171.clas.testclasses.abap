CLASS ltcl_ex_171 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS counts_entries_in_status_bar FOR TESTING.
    METHODS empty_log_keeps_the_grid FOR TESTING.
    METHODS display_like_colours_the_bar FOR TESTING.
    METHODS quiet_run_has_no_message FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_171 IMPLEMENTATION.

  METHOD counts_entries_in_status_bar.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_171( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages
      exp = VALUE zcl_gg_host_session=>ty_messages(
        ( type = zif_gg_session_types_v1=>message_type_success text = `3 entries listed` ) ) ).
* The count is the status bar's, not a banner above the grid.
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS
      '<span id="wb-status-message" class="wb-status-feedback wb-status-success" role="status" aria-live="polite" title="3 entries listed" aria-haspopup="dialog" aria-controls="wb-message-details">' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = count( val = ls_result-html
                   sub = `>3 entries listed<` )
      exp = 1 ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS 'class="gg-message' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'Log entry 3' ) ).
  ENDMETHOD.

  METHOD empty_log_keeps_the_grid.
* An empty log is still a log: the grid shows, the count says 0.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_171( )
      it_input  = VALUE #( ( name = 'P_COUNT' value = '0' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-page_kind
      exp = zif_gg_host_html_v1=>page_list ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS
      '<span class="wb-status-text">0 entries listed</span>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS 'class="gg-message' ) ).
  ENDMETHOD.

  METHOD display_like_colours_the_bar.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_171( )
      it_input  = VALUE #( ( name = 'P_LIKE' value = 'W' ) ) ).

* DISPLAY LIKE changes the colour, not the type: the run went on to the list.
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-type
      exp = zif_gg_session_types_v1=>message_type_success ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'class="wb-status-feedback wb-status-warning"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'Log entry 1' ) ).
  ENDMETHOD.

  METHOD quiet_run_has_no_message.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_171( )
      it_input  = VALUE #( ( name = 'P_QUIET' value = 'X' ) ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-messages ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS
      '<span id="wb-status-message" class="wb-status-feedback" aria-live="polite"></span>' ) ).
  ENDMETHOD.

ENDCLASS.
