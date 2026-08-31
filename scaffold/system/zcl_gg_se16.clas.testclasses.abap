CLASS ltcl_gg_se16 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS displays_bounded_rows FOR TESTING.
    METHODS rejects_unknown_table FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_se16 IMPLEMENTATION.

  METHOD class_setup.
    zcl_gg_db_helper=>create( ).
    zcl_gg_db_helper=>reset( ).
  ENDMETHOD.

  METHOD class_teardown.
    zcl_gg_db_helper=>destroy( ).
  ENDMETHOD.

  METHOD displays_bounded_rows.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se16( )
      iv_ucomm   = 'EXECUTE'
      it_values  = VALUE #(
        ( name = 'P_TABLE' value = 'ZSFLIGHT' )
        ( name = 'P_MAX_ROWS' value = '2' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0200' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_RESULT_COUNT' ]-value
                                        exp = '2' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_RESULT' name = 'CARRID' row = 1 ]-value
                                        exp = 'AA' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'hard maximum reached' ) ).
  ENDMETHOD.

  METHOD rejects_unknown_table.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se16( )
      iv_ucomm   = 'EXECUTE'
      it_values  = VALUE #( ( name = 'P_TABLE' value = 'ZUNKNOWN' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0100' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-text
                                        exp = 'Table is unknown or not permitted by the data-access policy.' ).
  ENDMETHOD.

ENDCLASS.
