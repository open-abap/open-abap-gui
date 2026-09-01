CLASS ltcl_gg_se16 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS generates_criteria_screen FOR TESTING.
    METHODS displays_bounded_rows FOR TESTING.
    METHODS applies_range_criterion FOR TESTING.
    METHODS applies_exclude_criterion FOR TESTING.
    METHODS limits_output_fields FOR TESTING.
    METHODS rejects_untyped_value FOR TESTING.
    METHODS rejects_open_range FOR TESTING.
    METHODS rejects_unknown_table FOR TESTING.
    METHODS returns_to_same_criteria FOR TESTING.
    METHODS offers_domain_value_help FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_se16 IMPLEMENTATION.

  METHOD class_setup.
    zcl_gg_db_helper=>create( ).
    zcl_gg_db_helper=>reset( ).
  ENDMETHOD.

  METHOD class_teardown.
    zcl_gg_db_helper=>destroy( ).
  ENDMETHOD.

  METHOD generates_criteria_screen.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se16( )
      iv_ucomm   = 'SELECTION'
      it_values  = VALUE #( ( name = 'P_TABLE' value = 'ZSFLIGHT' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0150' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'CARRID - Airline carrier ID' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'CITYTO - Arrival city' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'Between (range)' ) ).
    cl_abap_unit_assert=>assert_true( act = line_exists(
      ls_result-controls[ screen = '0150' name = 'P_T1_LOW1' ] ) ).
    cl_abap_unit_assert=>assert_true( act = line_exists(
      ls_result-controls[ screen = '0150' name = 'P_T1_OUT8' ] ) ).
  ENDMETHOD.

  METHOD displays_bounded_rows.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se16( )
      iv_screen  = '0150'
      iv_ucomm   = 'EXECUTE'
      it_values  = VALUE #(
        ( name = 'P_TABLE' value = 'ZSFLIGHT' )
        ( name = 'P_T1_MAX' value = '2' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0200' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_T1_OCNT' ]-value
                                        exp = '2' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'P_T1_TC' name = 'P_T1_C1' row = 1 ]-value
                                        exp = 'AA' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'P_T1_TC' name = 'P_T1_C3' row = 1 ]-value
                                        exp = '2026-01-01' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'hard maximum reached' ) ).
  ENDMETHOD.

  METHOD applies_range_criterion.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se16( )
      iv_screen  = '0150'
      iv_ucomm   = 'EXECUTE'
      it_values  = VALUE #(
        ( name = 'P_TABLE' value = 'ZSFLIGHT' )
        ( name = 'P_T1_OP1' value = 'BT' )
        ( name = 'P_T1_LOW1' value = 'AA' )
        ( name = 'P_T1_HIGH1' value = 'LH' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0200' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_T1_OCNT' ]-value
                                        exp = '4' ).
  ENDMETHOD.

  METHOD applies_exclude_criterion.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se16( )
      iv_screen  = '0150'
      iv_ucomm   = 'EXECUTE'
      it_values  = VALUE #(
        ( name = 'P_TABLE' value = 'ZSFLIGHT' )
        ( name = 'P_T1_OP1' value = 'NE' )
        ( name = 'P_T1_LOW1' value = 'AA' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_T1_OCNT' ]-value
                                        exp = '3' ).
  ENDMETHOD.

  METHOD limits_output_fields.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se16( )
      iv_screen  = '0150'
      iv_ucomm   = 'EXECUTE'
      it_values  = VALUE #(
        ( name = 'P_TABLE' value = 'ZSFLIGHT' )
        ( name = 'P_T1_OUT1' value = 'X' )
        ( name = 'P_T1_OUT2' value = 'X' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_T1_OFLD' ]-value
                                        exp = 'Output fields: CARRID, CONNID' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'P_T1_TC' name = 'P_T1_C2' row = 1 ]-value
                                        exp = '0017' ).
    cl_abap_unit_assert=>assert_false( act = line_exists(
      ls_result-values[ container = 'P_T1_TC' name = 'P_T1_C7' row = 1 ] ) ).
  ENDMETHOD.

  METHOD rejects_untyped_value.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se16( )
      iv_screen  = '0150'
      iv_ucomm   = 'EXECUTE'
      it_values  = VALUE #(
        ( name = 'P_TABLE' value = 'ZSFLIGHT' )
        ( name = 'P_T1_LOW2' value = 'AB' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0150' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-text
                                        exp = 'CONNID is a NUMC field and only accepts digits.' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_T1_LOW2' ]-value
                                        exp = 'AB' ).
  ENDMETHOD.

  METHOD rejects_open_range.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se16( )
      iv_screen  = '0150'
      iv_ucomm   = 'EXECUTE'
      it_values  = VALUE #(
        ( name = 'P_TABLE' value = 'ZSFLIGHT' )
        ( name = 'P_T1_OP1' value = 'BT' )
        ( name = 'P_T1_LOW1' value = 'AA' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0150' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'A range on CARRID needs both a low and a high value.' ).
  ENDMETHOD.

  METHOD rejects_unknown_table.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se16( )
      iv_ucomm   = 'SELECTION'
      it_values  = VALUE #( ( name = 'P_TABLE' value = 'ZUNKNOWN' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0100' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-text
                                        exp = 'Table is unknown or not permitted by the data-access policy.' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_TABLE' ]-value
                                        exp = 'ZUNKNOWN' ).
  ENDMETHOD.

  METHOD offers_domain_value_help.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program       = NEW zcl_gg_se16( )
      iv_screen        = '0150'
      iv_submitted     = abap_false
      iv_value_request = 'P_T1_LOW1'
      it_values        = VALUE #( ( name = 'P_TABLE' value = 'ZSFLIGHT' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-help_values )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_true( act = line_exists( ls_result-help_values[ name = 'P_T1_LOW1' value = 'LH' ] ) ).
  ENDMETHOD.

  METHOD returns_to_same_criteria.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se16( )
      iv_screen  = '0200'
      iv_ucomm   = 'BACK'
      it_values  = VALUE #(
        ( name = 'P_TABLE' value = 'ZSFLIGHT' )
        ( name = 'P_T1_LOW1' value = 'LH' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0150' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_T1_LOW1' ]-value
                                        exp = 'LH' ).
  ENDMETHOD.

ENDCLASS.
