CLASS ltcl_ex_67 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_typed_parameters FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_67 IMPLEMENTATION.

  METHOD publishes_typed_parameters.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_67( ) ).

    cl_abap_unit_assert=>assert_true( ls_result-selection_active ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'P_DATE' ]-data_type-typ
      exp = 'D' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'P_TIME' ]-data_type-typ
      exp = 'T' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'P_INT' ]-data_type-typ
      exp = 'I' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ name = 'P_DEC' ]-data_type-decimals
      exp = 2 ).
    cl_abap_unit_assert=>assert_true( ls_result-states[ name = 'P_CHAR' ]-obligatory ).
  ENDMETHOD.

ENDCLASS.
