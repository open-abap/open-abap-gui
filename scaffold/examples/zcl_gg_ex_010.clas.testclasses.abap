CLASS ltcl_ex_10 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS writes_page_footers FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_10 IMPLEMENTATION.

  METHOD writes_page_footers.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_010( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-lines )
      exp = 33 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 9 ]
      exp = `footer` ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 18 ]
      exp = `footer` ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 33 ]
      exp = `30` ).
  ENDMETHOD.

ENDCLASS.
