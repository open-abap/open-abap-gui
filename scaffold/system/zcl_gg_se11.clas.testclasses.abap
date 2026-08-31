CLASS ltcl_gg_se11 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS metadata FOR TESTING.
    METHODS displays_dictionary_table FOR TESTING.
    METHODS rejects_unsupported_object FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_se11 IMPLEMENTATION.

  METHOD metadata.
    DATA(ls_transaction) = NEW zcl_gg_se11( )->zif_gg_transaction_v1~get_transaction( ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode
                                        exp = 'SE11' ).
  ENDMETHOD.

  METHOD displays_dictionary_table.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se11( )
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_OBJECT_TYPE' value = 'TABLE' ) ( name = 'P_OBJECT_NAME' value = 'ZSFLIGHT' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0200' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_NAME' ]-value
                                        exp = 'ZSFLIGHT' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_FIELDS' name = 'FIELD_NAME' row = 1 ]-value
                                        exp = 'CARRID' ).
  ENDMETHOD.

  METHOD rejects_unsupported_object.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se11( )
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_OBJECT_TYPE' value = 'DOMAIN' ) ( name = 'P_OBJECT_NAME' value = 'ZSFLIGHT' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_OBJECT_TYPE' ]-value
                                        exp = 'DOMAIN' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0100' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-text
                                        exp = 'Dictionary object type is not supported.' ).
  ENDMETHOD.

ENDCLASS.
