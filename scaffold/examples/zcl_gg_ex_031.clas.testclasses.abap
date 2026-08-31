CLASS ltcl_ex_31 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS normalizes_field_before_pai FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_31 IMPLEMENTATION.

  METHOD normalizes_field_before_pai.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_031( )
      it_input  = VALUE #( ( name = 'P_CARR' value = 'lh' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_CARR' ]-value
      exp = 'LH' ).
  ENDMETHOD.

ENDCLASS.
