CLASS ltcl_ex_161 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS keeps_checkbox_defaults FOR TESTING.
    METHODS keeps_checkboxes_off_line FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_161 IMPLEMENTATION.

  METHOD keeps_checkbox_defaults.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_161( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_CLEAN' ]-value
      exp = 'X' ).
    cl_abap_unit_assert=>assert_initial( ls_result-values[ name = 'P_TSAVE' ]-value ).
  ENDMETHOD.

  METHOD keeps_checkboxes_off_line.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_161( ) ).
    DATA(lt_elements) = ls_result-screen_snapshot-elements.

*   Outside BEGIN OF LINE neither checkbox shares a selection line.
    cl_abap_unit_assert=>assert_equals(
      act = lt_elements[ name = 'P_CLEAN' ]-line
      exp = 0 ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_elements[ name = 'P_TSAVE' ]-line
      exp = 0 ).
  ENDMETHOD.

ENDCLASS.
