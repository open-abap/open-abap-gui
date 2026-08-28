CLASS ltcl_ex_30 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS rejects_negative_input FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_30 IMPLEMENTATION.

  METHOD rejects_negative_input.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_30( )
      it_input  = VALUE #( ( name = 'P_N' value = '-1' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-messages )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'must not be negative' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_N' ]-value
      exp = '-1' ).
  ENDMETHOD.

ENDCLASS.
