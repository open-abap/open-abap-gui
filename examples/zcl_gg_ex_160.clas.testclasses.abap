CLASS ltcl_ex_160 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_sibling_blocks FOR TESTING.
    METHODS assigns_fields_to_blocks FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_160 IMPLEMENTATION.

  METHOD builds_sibling_blocks.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_160( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-blocks )
      exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-blocks[ 2 ]-block-name
      exp = 'BLOCK2' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-blocks[ 2 ]-depth
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_MAXRUN' ]-value
      exp = '20' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_BKDEF' ]-value
      exp = '4' ).
  ENDMETHOD.

  METHOD assigns_fields_to_blocks.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_160( ) ).
    DATA(lt_elements) = ls_result-screen_snapshot-elements.

    cl_abap_unit_assert=>assert_equals(
      act = lt_elements[ name = 'P_MAXRUN' ]-block
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_elements[ name = 'P_BKDEF' ]-block
      exp = 2 ).
  ENDMETHOD.

ENDCLASS.
