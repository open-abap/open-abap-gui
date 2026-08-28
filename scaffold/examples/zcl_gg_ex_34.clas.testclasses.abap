CLASS ltcl_ex_34 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS validates_radio_group FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_34 IMPLEMENTATION.

  METHOD validates_radio_group.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_34( )
      it_input  = VALUE #( ( name = 'P_ONE' value = 'X' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-messages )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'key required for single mode' ).
  ENDMETHOD.

ENDCLASS.
