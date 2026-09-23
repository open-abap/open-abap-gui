CLASS ltcl_gg_transaction_registry DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS contract_is_independent FOR TESTING.
    METHODS normalizes_and_looks_up FOR TESTING.
    METHODS parses_supported_commands FOR TESTING.
    METHODS replaces_a_host_session FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_transaction_registry IMPLEMENTATION.

  METHOD contract_is_independent.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    DATA lo_report TYPE REF TO zif_gg_report_v1.
    DATA lo_example TYPE REF TO zcl_gg_ex_001.

    lo_example = NEW zcl_gg_ex_001( ).
    lo_metadata ?= lo_example.
    lo_report ?= lo_example.
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode
                                        exp = 'ZGG_EX_001' ).
    cl_abap_unit_assert=>assert_bound( act = lo_report ).
  ENDMETHOD.

  METHOD normalizes_and_looks_up.
    DATA ls_transaction TYPE zcl_gg_transaction_registry=>ty_transaction.
    DATA lt_invalid_tcodes TYPE string_table.
    DATA lv_invalid_tcode TYPE string.

    zcl_gg_transaction_registry=>clear( ).
    ls_transaction = zcl_gg_transaction_registry=>lookup( iv_tcode = `  zgg_ex_001  ` ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode
                                        exp = 'ZGG_EX_001' ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-class_name
                                        exp = 'ZCL_GG_EX_001' ).
    LOOP AT VALUE string_table( ( `se01` ) ( `SE09` ) ( `Se11` ) ( `se16` ) ( `Se38` ) ) INTO DATA(lv_system_tcode).
      cl_abap_unit_assert=>assert_equals(
        act = zcl_gg_transaction_registry=>lookup( iv_tcode = lv_system_tcode )-tcode
        exp = to_upper( lv_system_tcode ) ).
    ENDLOOP.
    cl_abap_unit_assert=>assert_initial(
      act = zcl_gg_transaction_registry=>lookup( iv_tcode = `ZGG_EX_UNKNOWN` )-tcode ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_transaction_registry=>normalize_tcode( iv_tcode = `/abc/def` )
      exp = `/ABC/DEF` ).
    lt_invalid_tcodes = VALUE #(
      ( `` )
      ( `ZGG EX 001` )
      ( `123456789012345678901` )
      ( `/NZGG_EX_001` )
      ( `/OZGG_EX_001` )
      ( `/ABC/` )
      ( `/ABC//DEF` ) ).
    LOOP AT lt_invalid_tcodes INTO lv_invalid_tcode.
      cl_abap_unit_assert=>assert_initial(
        act = zcl_gg_transaction_registry=>normalize_tcode( iv_tcode = lv_invalid_tcode ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD parses_supported_commands.
    DATA ls_result TYPE zcl_gg_transaction_command=>ty_result.

    zcl_gg_transaction_registry=>clear( ).
    ls_result = zcl_gg_transaction_command=>parse( iv_command = ` /nzgg_ex_058 ` ).
    cl_abap_unit_assert=>assert_true( act = ls_result-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-tcode
                                        exp = 'ZGG_EX_058' ).
    ls_result = zcl_gg_transaction_command=>parse( iv_command = `/nzgg_ex_999` ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-error
      exp = 'Unknown transaction code: zgg_ex_999' ).
    LOOP AT VALUE string_table( ( `ZGG_EX_001` ) ( `/oZGG_EX_001` ) ( `/n` ) ( `/nUNKNOWN` ) ( `/nZGG_EX_001 extra` ) ) INTO DATA(lv_command).
      ls_result = zcl_gg_transaction_command=>parse( iv_command = lv_command ).
      cl_abap_unit_assert=>assert_false( act = ls_result-valid ).
      cl_abap_unit_assert=>assert_not_initial( act = ls_result-error ).
    ENDLOOP.
  ENDMETHOD.

  METHOD replaces_a_host_session.
    DATA ls_old TYPE zif_gg_host_html_v1=>ty_response.
    DATA ls_new TYPE zif_gg_host_html_v1=>ty_response.
    DATA ls_stale TYPE zif_gg_host_html_v1=>ty_response.
    DATA ls_request TYPE zif_gg_host_html_v1=>ty_request.

    zcl_gg_host_runtime=>clear( ).
    ls_old = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_001( ) ).
    cl_abap_unit_assert=>assert_initial(
      act = zcl_gg_host_runtime=>close_current(
        iv_session_id = ls_old-session_id
        iv_page_id    = ls_old-page_id ) ).
    ls_new = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_002( ) ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_new-session_id ).
    ls_request-session_id = ls_old-session_id.
    ls_request-page_id = ls_old-page_id.
    ls_request-action = zif_gg_host_html_v1=>action_submit.
    ls_stale = zcl_gg_host_runtime=>dispatch( ls_request ).
    cl_abap_unit_assert=>assert_false( act = ls_stale-valid ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
