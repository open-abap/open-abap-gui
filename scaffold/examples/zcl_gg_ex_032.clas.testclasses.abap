CLASS ltcl_ex_32 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS rejects_too_many_ranges FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_32 IMPLEMENTATION.

  METHOD rejects_too_many_ranges.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_032( )
      it_input  = VALUE #( ( name   = 'S_CARR'
                             ranges = VALUE #(
                               ( sign = 'I' option = 'EQ' low = 'AA' )
                               ( sign = 'I' option = 'EQ' low = 'BB' )
                               ( sign = 'I' option = 'EQ' low = 'CC' )
                               ( sign = 'I' option = 'EQ' low = 'DD' )
                               ( sign = 'I' option = 'EQ' low = 'EE' )
                               ( sign = 'I' option = 'EQ' low = 'FF' ) ) ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-messages )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'at most five entries' ).
  ENDMETHOD.

ENDCLASS.
