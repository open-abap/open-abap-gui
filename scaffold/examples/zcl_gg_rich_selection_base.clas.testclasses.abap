CLASS ltcl_gg_rich_selection DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS dependent_listbox FOR TESTING.
    METHODS range_signs FOR TESTING.
    METHODS multiple_rows FOR TESTING.
    METHODS multiple_choice FOR TESTING.
    METHODS tab_retains_values FOR TESTING.
    METHODS pushbutton_derives FOR TESTING.
    METHODS function_keys FOR TESTING.
    METHODS value_help FOR TESTING.
    METHODS contextual_help FOR TESTING.
    METHODS validation_order FOR TESTING.
    METHODS error_focus FOR TESTING.
    METHODS variants FOR TESTING.
    METHODS rejects_undeclared_command FOR TESTING.
ENDCLASS.

CLASS ltcl_gg_rich_selection IMPLEMENTATION.

  METHOD dependent_listbox.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_071( )
      it_input = VALUE #( ( name = 'P_CARRIER' value = 'LH' )
                          ( name = 'P_REQUIRED' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-states[ name = 'P_CONNECTION' ]-fixed_values[ 1 ]-key
      exp = 'LH-1' ).
  ENDMETHOD.

  METHOD range_signs.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_072( )
      it_input = VALUE #(
        ( name = 'S_CARRIER' ranges = VALUE #(
          ( sign = 'I' option = 'EQ' low = 'AA' )
          ( sign = 'E' option = 'BT' low = 'LH' high = 'SQ' )
          ( sign = 'I' option = 'CP' low = 'A*' ) ) )
        ( name = 'P_REQUIRED' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-values[ name = 'S_CARRIER' ]-ranges )
      exp = 3 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'S_CARRIER' ]-ranges[ 2 ]-sign
      exp = 'E' ).
  ENDMETHOD.

  METHOD multiple_rows.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_073( )
      it_input = VALUE #(
        ( name = 'S_MULTI' ranges = VALUE #(
          ( sign = 'I' option = 'EQ' low = 'AA' )
          ( sign = 'I' option = 'EQ' low = 'LH' ) ) )
        ( name = 'P_REQUIRED' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-values[ name = 'S_MULTI' ]-ranges )
      exp = 2 ).
  ENDMETHOD.

  METHOD multiple_choice.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_074( )
      iv_value_request = 'S_MULTI' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-values[ name = 'S_MULTI' ]-ranges )
      exp = 3 ).
  ENDMETHOD.

  METHOD tab_retains_values.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_075( )
      iv_ucomm = 'UT2'
      it_input = VALUE #( ( name = 'P_GENERAL' value = 'general' )
                          ( name = 'P_DETAILS' value = 'details' )
                          ( name = 'P_REQUIRED' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_true( ls_result-screen_snapshot-tabs[ name = 'TAB_DETAILS' ]-selected ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_GENERAL' ]-value
      exp = 'general' ).
  ENDMETHOD.

  METHOD pushbutton_derives.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_076( )
      iv_ucomm = 'DERIVE'
      it_input = VALUE #( ( name = 'P_REQUIRED' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_DERIVED' ]-value
      exp = 'derived by pushbutton' ).
  ENDMETHOD.

  METHOD function_keys.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_077( )
      iv_ucomm = 'FC02'
      it_input = VALUE #( ( name = 'P_REQUIRED' value = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_ACTION' ]-value
      exp = 'beta' ).
  ENDMETHOD.

  METHOD value_help.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_078( )
      iv_value_request = 'P_CARRIER' ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-values[ name = 'P_CARRIER' ]-ranges ) exp = 3 ).
  ENDMETHOD.

  METHOD contextual_help.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_079( )
      iv_help_name = 'P_HELP' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-help_text CS 'business key' ) ).
  ENDMETHOD.

  METHOD validation_order.
    DATA(lo_report) = NEW zcl_gg_ex_080( ).
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = lo_report
      it_input = VALUE #(
        ( name = 'P_FIELD' value = 'good' )
        ( name = 'P_REQUIRED' value = 'ok' )
        ( name = 'S_END' ranges = VALUE #( ( sign = 'I' option = 'EQ' low = 'ok' ) ) ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-lines[ 1 ] exp = 'FIELD>BLOCK>RADIO>END' ).
  ENDMETHOD.

  METHOD error_focus.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_081( )
      it_input = VALUE #( ( name = 'P_GOOD' value = 'kept' )
                          ( name = 'P_BAD' value = 'bad' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-field exp = 'P_BAD' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_GOOD' ]-value exp = 'kept' ).
  ENDMETHOD.

  METHOD variants.
    zcl_gg_host_variant=>clear( ).
    zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_082( )
      iv_ucomm = 'VAR_SAVE'
      it_input = VALUE #( ( name = 'P_NAME' value = 'UNIT' )
                          ( name = 'P_VALUE' value = 'saved' ) ) ).
    DATA(ls_loaded) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_082( )
      iv_ucomm = 'VAR_LOAD'
      it_input = VALUE #( ( name = 'P_NAME' value = 'UNIT' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_loaded-values[ name = 'P_VALUE' ]-value exp = 'saved' ).
  ENDMETHOD.

  METHOD rejects_undeclared_command.
    DATA lt_reports TYPE STANDARD TABLE OF REF TO zif_gg_report_v1 WITH DEFAULT KEY.
    APPEND NEW zcl_gg_ex_067( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_068( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_069( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_070( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_071( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_072( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_073( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_074( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_075( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_076( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_077( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_078( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_079( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_080( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_081( ) TO lt_reports.
    APPEND NEW zcl_gg_ex_082( ) TO lt_reports.
    LOOP AT lt_reports INTO DATA(lo_report).
      DATA(ls_result) = zcl_gg_host=>run(
        io_report = lo_report
        iv_ucomm  = 'FORGED' ).
      cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( ls_result-messages[
          text = 'Undeclared selection command FORGED' ] ) ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
