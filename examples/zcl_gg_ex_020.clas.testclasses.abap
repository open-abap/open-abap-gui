CLASS ltcl_ex_20 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_default_range FOR TESTING.
    METHODS lists_flights_of_selection FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_20 IMPLEMENTATION.

  METHOD builds_default_range.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_020( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'S_CARR' ]-ranges
      exp = VALUE zif_gg_selection_screen_types=>ty_ranges( (
        sign   = zif_gg_selection_screen_types=>sign_include
        option = zif_gg_selection_screen_types=>option_eq
        low    = 'LH' ) ) ).
  ENDMETHOD.

  METHOD lists_flights_of_selection.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_020( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 2 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-lines[ 1 ] CP 'LH*0400' ) ).
  ENDMETHOD.

ENDCLASS.
