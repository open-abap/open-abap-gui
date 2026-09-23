CLASS ltcl_ex_02 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS places_and_keeps_gap FOR TESTING.
    METHODS renders_placed_fragments FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_02 IMPLEMENTATION.

  METHOD places_and_keeps_gap.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_002( ) ).

* abcde starts at column 10 and is truncated to the stated length, x follows
* after the usual single blank, and y sits against x because of NO-GAP.
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `         abcde xy` ) ) ).
  ENDMETHOD.

  METHOD renders_placed_fragments.
    DATA(ls_placement) = zcl_gg_host=>run( NEW zcl_gg_ex_002( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_placement-render_lines[ 1 ]-fragments[ 1 ]-position
      exp = 10 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_placement-render_lines[ 1 ]-fragments[ 1 ]-length
      exp = 5 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lines( ls_placement-render_lines[ 1 ]-fragments ) >= 3 ) ).
  ENDMETHOD.

ENDCLASS.
