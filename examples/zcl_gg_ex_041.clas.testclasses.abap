CLASS ltcl_ex_41 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS terminal_message_stops FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_41 IMPLEMENTATION.

  METHOD terminal_message_stops.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_041( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-messages )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-type
      exp = zif_gg_session_types_v1=>message_type_abort ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'giving up' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 0 ).
  ENDMETHOD.

ENDCLASS.
