CLASS ltcl_ex_15 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS applies_character_default FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_15 IMPLEMENTATION.

  METHOD applies_character_default.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_15( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `LH` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_CARR' ]-value
      exp = 'LH' ).
  ENDMETHOD.

ENDCLASS.
