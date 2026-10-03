CLASS ltcl_ex_19 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_fixed_listbox FOR TESTING.
    METHODS lists_domain_values FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_19 IMPLEMENTATION.

  METHOD builds_fixed_listbox.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_019( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_MODE' ]-value
      exp = 'A' ).
  ENDMETHOD.

  METHOD lists_domain_values.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_019( ) ).
    DATA(lt_fixed_values) = ls_result-states[ name = 'P_MODE' ]-fixed_values.

    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_fixed_values )
      exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_fixed_values[ 1 ]
      exp = VALUE zif_gg_selection_screen_types=>ty_fixed_value( key = 'A' text = 'Add' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_fixed_values[ 2 ]
      exp = VALUE zif_gg_selection_screen_types=>ty_fixed_value( key = 'D' text = 'Delete' ) ).
  ENDMETHOD.

ENDCLASS.
