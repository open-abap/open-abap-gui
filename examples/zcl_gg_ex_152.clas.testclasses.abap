CLASS ltcl_ex_152 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS publishes_and_renders FOR TESTING.
    METHODS closes_timer_lifecycle FOR TESTING.
ENDCLASS.

CLASS ltcl_ex_152 IMPLEMENTATION.
  METHOD publishes_and_renders.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_152( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_152( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode
                                        exp = 'ZGG_EX_152' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'Timer lifecycle' ) ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_result-status-active_ucomm ).
  ENDMETHOD.

  METHOD closes_timer_lifecycle.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_152( ) ).
    DATA(ls_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_start-page_id
      action     = zif_gg_host_html_v1=>action_command
      ucomm      = 'START_TIMER' ) ).
    cl_abap_unit_assert=>assert_true( act = ls_next-valid ).
    zcl_gg_host_runtime=>close( ls_start-session_id ).
    DATA(ls_closed) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id    = ls_next-page_id
      action     = zif_gg_host_html_v1=>action_command
      ucomm      = 'TICK_TIMER' ) ).
    cl_abap_unit_assert=>assert_false( act = ls_closed-valid ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.
ENDCLASS.
