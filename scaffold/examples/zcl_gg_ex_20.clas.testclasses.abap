CLASS ltcl_ex_20 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_default_range FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_20 IMPLEMENTATION.

  METHOD builds_default_range.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_20( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'S_CARR' ]-ranges[ 1 ]-sign
      exp = zif_gg_selection_screen_types=>sign_include ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'S_CARR' ]-ranges[ 1 ]-option
      exp = zif_gg_selection_screen_types=>option_bt ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'S_CARR' ]-ranges[ 1 ]-low
      exp = 'AA' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'S_CARR' ]-ranges[ 1 ]-high
      exp = 'LH' ).
  ENDMETHOD.

ENDCLASS.
