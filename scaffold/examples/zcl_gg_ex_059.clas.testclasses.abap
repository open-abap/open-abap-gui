CLASS ltcl_ex_59 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS owns_refresh_and_print FOR TESTING.
    METHODS command_authorization FOR TESTING.
ENDCLASS.
CLASS ltcl_ex_59 IMPLEMENTATION.
  METHOD owns_refresh_and_print.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_059( ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-status-icon_bar ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-status-icon_bar[ 1 ]-label exp = 'Refresh' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-status-icon_bar[ 2 ]-ucomm exp = 'PRI' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'class="wb-toolbar-button' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS 'Create' ) ).
  ENDMETHOD.

  METHOD command_authorization.
    TYPES: BEGIN OF ty_case,
             report TYPE REF TO zif_gg_report_v1,
             ucomm  TYPE string,
           END OF ty_case.
    DATA lt_cases TYPE STANDARD TABLE OF ty_case WITH DEFAULT KEY.
    APPEND VALUE #( report = NEW zcl_gg_ex_059( ) ucomm = 'REFR' ) TO lt_cases.
    APPEND VALUE #( report = NEW zcl_gg_ex_060( ) ucomm = 'FIRST' ) TO lt_cases.
    APPEND VALUE #( report = NEW zcl_gg_ex_061( ) ucomm = 'ENABLE' ) TO lt_cases.
    APPEND VALUE #( report = NEW zcl_gg_ex_062( ) ucomm = 'NEXT' ) TO lt_cases.
    APPEND VALUE #( report = NEW zcl_gg_ex_066( ) ucomm = 'RUN66' ) TO lt_cases.
    LOOP AT lt_cases INTO DATA(ls_case).
      zcl_gg_host_runtime=>clear( ).
      DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = ls_case-report ).
      DATA(ls_bad) = zcl_gg_host_runtime=>dispatch( VALUE #(
        session_id = ls_start-session_id
        page_id    = ls_start-page_id
        action     = zif_gg_host_html_v1=>action_command
        ucomm      = 'FORGED' ) ).
      cl_abap_unit_assert=>assert_false( act = ls_bad-valid ).
      DATA(ls_good) = zcl_gg_host_runtime=>dispatch( VALUE #(
        session_id = ls_start-session_id
        page_id    = ls_start-page_id
        action     = zif_gg_host_html_v1=>action_command
        ucomm      = ls_case-ucomm ) ).
      cl_abap_unit_assert=>assert_true( act = ls_good-valid ).
    ENDLOOP.
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.
ENDCLASS.
