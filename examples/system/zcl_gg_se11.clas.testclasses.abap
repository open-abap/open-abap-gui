CLASS ltcl_gg_se11 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS metadata FOR TESTING.
    METHODS displays_dictionary_table FOR TESTING.
    METHODS displays_structure FOR TESTING.
    METHODS displays_data_element FOR TESTING.
    METHODS displays_domain FOR TESTING.
    METHODS displays_view FOR TESTING.
    METHODS displays_search_help FOR TESTING.
    METHODS displays_lock_object FOR TESTING.
    METHODS displays_table_type FOR TESTING.
    METHODS displays_type_group FOR TESTING.
    METHODS rejects_unsupported_type FOR TESTING.
    METHODS rejects_unknown_name FOR TESTING.
    METHODS rejects_contents_off_table FOR TESTING.
    METHODS offers_names_of_chosen_kind FOR TESTING.

    METHODS display
      IMPORTING
        iv_object_type   TYPE string
        iv_name          TYPE string
      RETURNING
        VALUE(rs_result) TYPE zcl_gg_host_dynpro=>ty_result.

ENDCLASS.

CLASS ltcl_gg_se11 IMPLEMENTATION.

  METHOD display.
    rs_result = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se11( )
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_OBJECT_TYPE' value = iv_object_type )
                            ( name = 'P_OBJECT_NAME' value = iv_name ) ) ).
  ENDMETHOD.

  METHOD metadata.
    DATA(ls_transaction) = NEW zcl_gg_se11( )->zif_gg_transaction_v1~get_transaction( ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode
                                        exp = 'SE11' ).
  ENDMETHOD.

  METHOD displays_dictionary_table.
    DATA(ls_result) = display( iv_object_type = 'TABLE'
                               iv_name        = 'ZSFLIGHT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0200' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_TAB_NAME' ]-value
                                        exp = 'ZSFLIGHT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_FIELDS' name = 'FIELD_NAME' row = 1 ]-value
                                        exp = 'CARRID' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_FIELDS' name = 'FIELD_ELEMENT' row = 1 ]-value
                                        exp = 'ZGG_CARRID' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_CHECKS' name = 'CHECK_HELP' row = 1 ]-value
                                        exp = 'ZGG_CARRID_SH' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-values[ name = 'O_TAB_TECHNICAL' ]-value CS 'APPL0' ) ).
  ENDMETHOD.

  METHOD displays_structure.
    DATA(ls_result) = display( iv_object_type = 'STRUCTURE'
                               iv_name        = 'ZSFLIGHT_KEY' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0210' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_STR_FIELDS' name = 'FIELD_NAME' row = 3 ]-value
                                        exp = 'FLDATE' ).
    cl_abap_unit_assert=>assert_false( act = line_exists( ls_result-values[ name = 'O_TAB_DELIVERY' ] ) ).
  ENDMETHOD.

  METHOD displays_data_element.
    DATA(ls_result) = display( iv_object_type = 'DATA_ELEMENT'
                               iv_name        = 'ZGG_CARRID' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0220' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_DTE_DOMAIN' ]-value
                                        exp = 'ZGG_CARRID' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_DTE_MEDIUM' ]-value
                                        exp = 'Airline' ).
  ENDMETHOD.

  METHOD displays_domain.
    DATA(ls_result) = display( iv_object_type = 'DOMAIN'
                               iv_name        = 'ZGG_CARRID' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0230' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_DOM_VALUE_TABLE' ]-value
                                        exp = 'ZSFLIGHT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_DOM_FIXED' name = 'FIXED_TEXT' row = 2 ]-value
                                        exp = 'Lufthansa' ).
  ENDMETHOD.

  METHOD displays_view.
    DATA(ls_result) = display( iv_object_type = 'VIEW'
                               iv_name        = 'ZSFLIGHT_V' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0240' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_VIE_TABLES' ]-value
                                        exp = 'ZSFLIGHT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_VIE_FIELDS' name = 'FIELD_NAME' row = 4 ]-value
                                        exp = 'PRICE' ).
  ENDMETHOD.

  METHOD displays_search_help.
    DATA(ls_result) = display( iv_object_type = 'SEARCH_HELP'
                               iv_name        = 'ZGG_CARRID_SH' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0250' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_SHL_METHOD' ]-value
                                        exp = 'ZSFLIGHT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_SHL_PARAMS' name = 'PARAM_NAME' row = 1 ]-value
                                        exp = 'CARRID' ).
  ENDMETHOD.

  METHOD displays_lock_object.
    DATA(ls_result) = display( iv_object_type = 'LOCK_OBJECT'
                               iv_name        = 'EZGG_SFLIGHT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0260' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_ENQ_TABLE' ]-value
                                        exp = 'ZSFLIGHT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_ENQ_PARAMS' name = 'LOCK_FIELD' row = 2 ]-value
                                        exp = 'CONNID' ).
  ENDMETHOD.

  METHOD displays_table_type.
    DATA(ls_result) = display( iv_object_type = 'TABLE_TYPE'
                               iv_name        = 'ZGG_SFLIGHT_TT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0270' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_TTY_LINE' ]-value
                                        exp = 'ZSFLIGHT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_TTY_KEY_FIELDS' ]-value
                                        exp = 'CARRID; CONNID; FLDATE' ).
  ENDMETHOD.

  METHOD displays_type_group.
    DATA(ls_result) = display( iv_object_type = 'TYPE_GROUP'
                               iv_name        = 'ZGGT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0280' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_TYP_LINE_1' ]-value
                                        exp = '001 TYPE-POOL zggt.' ).
  ENDMETHOD.

  METHOD rejects_unsupported_type.
    DATA(ls_result) = display( iv_object_type = 'MESSAGE_CLASS'
                               iv_name        = 'ZSFLIGHT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0100' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-text
                                        exp = 'Dictionary object type is not supported.' ).
  ENDMETHOD.

  METHOD rejects_unknown_name.
    DATA(ls_result) = display( iv_object_type = 'DOMAIN'
                               iv_name        = 'ZSFLIGHT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_OBJECT_TYPE' ]-value
                                        exp = 'DOMAIN' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0100' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-text
                                        exp = 'Dictionary object is unknown or not permitted.' ).
  ENDMETHOD.

  METHOD offers_names_of_chosen_kind.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program       = NEW zcl_gg_se11( )
      iv_submitted     = abap_false
      iv_value_request = 'P_OBJECT_NAME'
      it_values        = VALUE #( ( name = 'P_OBJECT_TYPE' value = 'LOCK_OBJECT' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-help_values )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-help_values[ 1 ]-value
                                        exp = 'EZGG_SFLIGHT' ).
  ENDMETHOD.

  METHOD rejects_contents_off_table.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se11( )
      iv_screen  = '0230'
      iv_ucomm   = 'CONTENTS' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-text
                                        exp = 'Table contents are only available for tables and views.' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-navigation-target
                                        exp = `` ).
  ENDMETHOD.

ENDCLASS.
