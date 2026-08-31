CLASS ltcl_ex_61 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS separates_command_states FOR TESTING.
ENDCLASS.
CLASS ltcl_ex_61 IMPLEMENTATION.
  METHOD separates_command_states.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_61( ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-ucomm="ENABLE"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-ucomm="INACTIVE"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-ucomm="EXCLUDED"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-ucomm="INACTIVE" disabled' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS 'value="COMMAND:EXCLUDED" form=' ) ).
  ENDMETHOD.
ENDCLASS.
