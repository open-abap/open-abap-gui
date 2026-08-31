CLASS ltcl_ex_65 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS renders_typed_breadcrumbs FOR TESTING.
ENDCLASS.
CLASS ltcl_ex_65 IMPLEMENTATION.
  METHOD renders_typed_breadcrumbs.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_065( ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-page-breadcrumbs ) exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-page-breadcrumbs[ 2 ]-target exp = 'SHELL/65' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'Shell &amp; &lt;context&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'data-breadcrumb-target="SHELL/65"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS 'href="SHELL/65"' ) ).
  ENDMETHOD.
ENDCLASS.
