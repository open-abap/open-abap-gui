CLASS ltcl_gg_transaction_registry DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

* Lookups of registered transactions are tested next to the transactions, in
* the examples; these tests hold without any application installed.

  PRIVATE SECTION.
    METHODS normalizes_and_looks_up FOR TESTING.
    METHODS rejects_unsupported_commands FOR TESTING.
    METHODS returns_to_menu FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_transaction_registry IMPLEMENTATION.

  METHOD normalizes_and_looks_up.
    DATA lt_invalid_tcodes TYPE string_table.
    DATA lv_invalid_tcode TYPE string.

    zcl_gg_transaction_registry=>clear( ).
    cl_abap_unit_assert=>assert_initial(
      act = zcl_gg_transaction_registry=>lookup( iv_tcode = `ZGG_EX_UNKNOWN` )-tcode ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_transaction_registry=>normalize_tcode( iv_tcode = `  zgg_ex_001  ` )
      exp = `ZGG_EX_001` ).
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

  METHOD rejects_unsupported_commands.
    DATA ls_result TYPE zcl_gg_transaction_command=>ty_result.

    zcl_gg_transaction_registry=>clear( ).
    ls_result = zcl_gg_transaction_command=>parse( iv_command = `/nzgg_ex_999` ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-error
      exp = 'Unknown transaction code: zgg_ex_999' ).
    LOOP AT VALUE string_table( ( `ZGG_EX_001` ) ( `/oZGG_EX_001` ) ( `/nUNKNOWN` ) ( `/nZGG_EX_001 extra` ) ) INTO DATA(lv_command).
      ls_result = zcl_gg_transaction_command=>parse( iv_command = lv_command ).
      cl_abap_unit_assert=>assert_false( act = ls_result-valid ).
      cl_abap_unit_assert=>assert_not_initial( act = ls_result-error ).
    ENDLOOP.
  ENDMETHOD.

  METHOD returns_to_menu.
    DATA ls_result TYPE zcl_gg_transaction_command=>ty_result.

    LOOP AT VALUE string_table( ( `/n` ) ( `/N` ) ( ` /n ` ) ) INTO DATA(lv_command).
      ls_result = zcl_gg_transaction_command=>parse( iv_command = lv_command ).
      cl_abap_unit_assert=>assert_true( act = ls_result-valid ).
      cl_abap_unit_assert=>assert_true( act = ls_result-menu ).
      cl_abap_unit_assert=>assert_initial( act = ls_result-tcode ).
      cl_abap_unit_assert=>assert_initial( act = ls_result-error ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
