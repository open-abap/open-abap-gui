CLASS ltcl_ex_33 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS validates_block FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_33 IMPLEMENTATION.

  METHOD validates_block.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_033( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-messages )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'fill one of the two' ).
  ENDMETHOD.

ENDCLASS.
