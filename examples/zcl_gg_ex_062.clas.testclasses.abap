CLASS ltcl_ex_62 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS changes_status_after_next FOR TESTING.
ENDCLASS.
CLASS ltcl_ex_62 IMPLEMENTATION.
  METHOD changes_status_after_next.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_062( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_start-current_page-status-status
                                        exp = 'SHELL62' ).
    DATA(ls_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id page_id = ls_start-page_id
      action = zif_gg_host_html_v1=>action_command ucomm = 'NEXT' ) ).
    cl_abap_unit_assert=>assert_true( ls_next-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_next-current_page-status-status
                                        exp = 'SHELL62-DONE' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_next-html CS 'data-ucomm="NEXT" disabled' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_next-html CS 'data-ucomm="DONE"' ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.
ENDCLASS.
