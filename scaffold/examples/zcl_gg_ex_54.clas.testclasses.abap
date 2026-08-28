CLASS ltcl_ex_54 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS submits_with_selection FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_54 IMPLEMENTATION.

  METHOD submits_with_selection.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report        = NEW zcl_gg_ex_54( )
      io_submit_report = NEW zcl_gg_ex_20( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `back` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-submit-program
      exp = 'ZGG_EX_20' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-submit-variant
      exp = 'STANDARD' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-submit-values[ name = 'S_CARR' ]-ranges[ 1 ]-low
      exp = 'LH' ).
  ENDMETHOD.

ENDCLASS.
