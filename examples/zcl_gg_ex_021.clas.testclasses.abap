CLASS ltcl_ex_21 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_comment_layout FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_21 IMPLEMENTATION.

  METHOD builds_comment_layout.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_021( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ kind = 'COMMENT' ]-text
      exp = 'Selection criteria' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ kind = 'COMMENT' ]-length
      exp = 30 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ kind = 'ULINE' ]-length
      exp = 40 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-elements[ kind = 'PARAMETER' ]-line
      exp = 1 ).
  ENDMETHOD.

ENDCLASS.
