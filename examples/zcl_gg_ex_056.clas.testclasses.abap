CLASS ltcl_ex_56 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS resumes_after_transaction FOR TESTING.
    METHODS pauses_at_call_transaction FOR TESTING.
    METHODS roundtrips_call_transaction FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_56 IMPLEMENTATION.

  METHOD resumes_after_transaction.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_056( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `back` ) ) ).
  ENDMETHOD.

  METHOD pauses_at_call_transaction.
    DATA(ls_transaction) = zcl_gg_host=>run( NEW zcl_gg_ex_056( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-navigation-kind
      exp = zcx_gg_control_flow=>kind_call_transaction ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-navigation-target
                                        exp = 'SE38' ).
  ENDMETHOD.

  METHOD roundtrips_call_transaction.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_transaction) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_056( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-page_kind
      exp = zif_gg_host_html_v1=>page_navigation ).
    DATA(ls_transaction_next) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_transaction-session_id
      page_id    = ls_transaction-page_id
      action     = zif_gg_host_html_v1=>action_submit ) ).
    cl_abap_unit_assert=>assert_true( ls_transaction_next-valid ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_transaction_next-compatibility-lines[ table_line = 'back' ] ) ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
