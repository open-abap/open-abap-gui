CLASS ltcl_ex_16 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_attribute_parameter FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_16 IMPLEMENTATION.

  METHOD builds_attribute_parameter.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_16( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'P_NAME' ]-value ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-states[ name = 'P_NAME' ]-modif_id
      exp = 'ABC' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-states[ name = 'P_NAME' ]-memory_id
      exp = 'ZGG' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-states[ name = 'P_NAME' ]-search_help
      exp = 'ZGG_SH' ).
    cl_abap_unit_assert=>assert_true( ls_result-states[ name = 'P_NAME' ]-obligatory ).
    cl_abap_unit_assert=>assert_true( ls_result-states[ name = 'P_NAME' ]-lower_case ).
  ENDMETHOD.

ENDCLASS.
