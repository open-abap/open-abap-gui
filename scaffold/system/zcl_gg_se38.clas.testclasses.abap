CLASS ltcl_gg_se38 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS metadata FOR TESTING.
    METHODS displays_escaped_source FOR TESTING.
    METHODS rejects_missing_program FOR TESTING.
    METHODS executes_report_runtime FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_se38 IMPLEMENTATION.

  METHOD metadata.
    DATA(ls_transaction) = NEW zcl_gg_se38( )->zif_gg_transaction_v1~get_transaction( ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode exp = 'SE38' ).
  ENDMETHOD.

  METHOD displays_escaped_source.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se38( )
      iv_ucomm = 'DISPLAY'
      it_values = VALUE #( ( name = 'P_PROGRAM' value = 'ZGG_EX_015' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen exp = '0200' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'REPORT zgg_ex_015.' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'line numbers' ) ).
  ENDMETHOD.

  METHOD rejects_missing_program.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se38( )
      iv_ucomm = 'DISPLAY'
      it_values = VALUE #( ( name = 'P_PROGRAM' value = 'ZUNKNOWN' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen exp = '0100' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-text exp = 'Program is missing, inactive, non-executable, or not authorized.' ).
  ENDMETHOD.

  METHOD executes_report_runtime.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_dynpro_program = NEW zcl_gg_se38( ) ).
    DATA(ls_result) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id
      page_id = ls_start-page_id
      action = zif_gg_host_html_v1=>action_submit
      ucomm = 'EXECUTE'
      dynpro_values = VALUE #( ( name = 'P_PROGRAM' value = 'ZGG_EX_015' ) ( name = 'P_VARIANT' value = 'DEFAULT' ) ) ) ).
    cl_abap_unit_assert=>assert_true( act = ls_result-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-page_kind exp = zif_gg_host_html_v1=>page_selection ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
