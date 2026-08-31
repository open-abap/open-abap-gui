CLASS ltcl_gg_host_html DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS escapes_text FOR TESTING.
    METHODS builds_attributes FOR TESTING.
    METHODS builds_document FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_host_html IMPLEMENTATION.

  METHOD escapes_text.
    DATA lv_unicode TYPE string.
    DATA(lv_utf8) = CONV xstring( '4772C3BCC39F6520E697A5E69CACE8AA9E' ).
    DATA(lo_converter) = cl_abap_conv_in_ce=>create( input    = lv_utf8
                                                     encoding = 'UTF-8' ).
    lo_converter->read( IMPORTING data = lv_unicode ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_html=>escape_text( `` )
      exp = ``
      msg = 'empty' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_html=>escape_text( lv_unicode )
      exp = lv_unicode
      msg = 'unicode' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_html=>escape_text( `"'` )
      exp = `&quot;&#39;`
      msg = 'quotes' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_html=>escape_text( `&` )
      exp = `&amp;`
      msg = 'ampersand' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_html=>escape_text( `<tag>` )
      exp = `&lt;tag&gt;`
      msg = 'angles' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_html=>escape_text( |line1{ cl_abap_char_utilities=>newline }line2| )
      exp = |line1{ cl_abap_char_utilities=>newline }line2|
      msg = 'newline' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_html=>escape_text( repeat( val = `x` occ = 512 ) )
      exp = repeat( val = `x` occ = 512 )
      msg = 'long' ).
  ENDMETHOD.

  METHOD builds_attributes.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_html=>identifier(
        iv_scope   = 'field'
        iv_program = 'Z/UNICODE'
        iv_name    = 'A B'
        iv_index   = 2 )
      exp = 'gg-field-p-Z-UNICODE-n-A-B-r-2' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_html=>attribute(
        iv_name     = 'title'
        iv_value    = ``
        iv_optional = abap_true )
      exp = `` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_html=>attributes( VALUE #(
        ( name = 'z' value = '2' )
        ( name = 'a' value = '1' ) ) )
      exp = ` a="1" z="2"` ).
  ENDMETHOD.

  METHOD builds_document.
    DATA(lv_document) = zcl_gg_host_html=>document(
      iv_session_id = 'S'
      iv_page_id    = 'P'
      iv_kind       = 'LIST'
      iv_title      = '<title>'
      iv_body       = '<main>body</main>'
      iv_csp_nonce  = 'nonce' ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_document CS '<!doctype html>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_document CS '<meta charset="utf-8">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_document CS '&lt;title&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_document CS 'data-page-id="P"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_document CS 'nonce="nonce"' ) ).
  ENDMETHOD.

ENDCLASS.