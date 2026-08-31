CLASS ltcl_ex_66 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS escapes_unicode_shell_text FOR TESTING.
    METHODS unicode_text
      IMPORTING
        iv_hex         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.
CLASS ltcl_ex_66 IMPLEMENTATION.
  METHOD escapes_unicode_shell_text.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_66( ) ).
    DATA(lv_title) = unicode_text( `52544C20D7A9D79CD795D79D20F09F9A802026203C7469746C653E` ).
    DATA(lv_label) = unicode_text( `52756E20226E6F77222026203C676F3E20F09F9A80` ).
    DATA(lv_body) = unicode_text( `D985D8B1D8ADD8A8D8A72065CC8120F09F9A80203C7368656C6C3E2026202271756F74657322` ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_result-html CS zcl_gg_host_html=>escape_text( lv_title ) ) ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_result-html CS zcl_gg_host_html=>escape_text( lv_label ) ) ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( ls_result-html CS zcl_gg_host_html=>escape_text( lv_body ) ) ).
  ENDMETHOD.

  METHOD unicode_text.
    DATA(lv_utf8) = CONV xstring( iv_hex ).
    DATA(lo_converter) = cl_abap_conv_in_ce=>create( input = lv_utf8 encoding = 'UTF-8' ).
    lo_converter->read( IMPORTING data = rv_text ).
  ENDMETHOD.
ENDCLASS.
