CLASS ltcl_ex_53 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS submits_terminally FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_53 IMPLEMENTATION.

  METHOD submits_terminally.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_53( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-terminal
      exp = 'SUBMIT ZGG_EX_01' ).
    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

ENDCLASS.
