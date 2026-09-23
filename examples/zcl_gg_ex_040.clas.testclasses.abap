CLASS ltcl_ex_40 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS records_message_class_call FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_40 IMPLEMENTATION.

  METHOD records_message_class_call.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_040( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-id
      exp = 'ZGG_EX' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-number
      exp = '001' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-v1
      exp = 'alpha' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-v2
      exp = 'beta' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'alpha beta' ).
  ENDMETHOD.

ENDCLASS.
