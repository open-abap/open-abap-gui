CLASS ltcl_ex_28 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS hides_modification_group FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_28 IMPLEMENTATION.

  METHOD hides_modification_group.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_28( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-states[ name = 'P_B' ]-modif_id
      exp = 'HID' ).
    cl_abap_unit_assert=>assert_false( ls_result-states[ name = 'P_B' ]-visible ).
    cl_abap_unit_assert=>assert_true( ls_result-states[ name = 'P_B' ]-input ).
    cl_abap_unit_assert=>assert_true( ls_result-states[ name = 'P_B' ]-output ).
    cl_abap_unit_assert=>assert_true( ls_result-states[ name = 'P_A' ]-visible ).
  ENDMETHOD.

ENDCLASS.
