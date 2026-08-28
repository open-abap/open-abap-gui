CLASS ltcl_ex_35 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS applies_value_request FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_35 IMPLEMENTATION.

  METHOD applies_value_request.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report        = NEW zcl_gg_ex_35( )
      iv_value_request = 'P_CARR' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_CARR' ]-ranges
      exp = VALUE zif_gg_selection_screen_types=>ty_ranges( (
        sign   = zif_gg_selection_screen_types=>sign_include
        option = zif_gg_selection_screen_types=>option_eq
        low    = 'LH' ) ) ).
  ENDMETHOD.

ENDCLASS.
