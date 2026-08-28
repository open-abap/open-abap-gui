CLASS ltcl_ex_42 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS records_display_like FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_42 IMPLEMENTATION.

  METHOD records_display_like.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_42( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-messages )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-type
      exp = zif_gg_session_types_v1=>message_type_success ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-display_like
      exp = zif_gg_session_types_v1=>message_type_error ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'looks like an error' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'class="gg-message gg-error"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'role="alert" aria-live="polite"' ) ).
  ENDMETHOD.

ENDCLASS.
