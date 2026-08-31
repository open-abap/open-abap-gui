CLASS ltcl_ex_39 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS records_free_text_message FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_39 IMPLEMENTATION.

  METHOD records_free_text_message.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_039( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-messages )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-type
      exp = zif_gg_session_types_v1=>message_type_info ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'free text' ).
  ENDMETHOD.

ENDCLASS.
