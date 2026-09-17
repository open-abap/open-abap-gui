CLASS ltcl_abap_browser DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    METHODS renders_html_in_container FOR TESTING.
    METHODS renders_xml_string_and_xstring FOR TESTING.

ENDCLASS.

CLASS ltcl_abap_browser IMPLEMENTATION.

  METHOD renders_html_in_container.
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'ABAP_BROWSER_HTML' ).

    cl_abap_browser=>show_html(
      html_string = '<h2>Browser HTML fixture</h2>'
      title       = 'Browser fixture'
      container   = lo_container ).

    DATA(lv_html) = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'ABAP_BROWSER_HTML' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Browser HTML fixture' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'title="HTML viewer"' ) ).
  ENDMETHOD.

  METHOD renders_xml_string_and_xstring.
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'ABAP_BROWSER_XML' ).
    DATA lv_xml TYPE string.
    lv_xml = '<catalog><sample>XML string fixture</sample></catalog>'.
    DATA(lv_xxml) = cl_abap_codepage=>convert_to( '<catalog><sample>XML xstring fixture</sample></catalog>' ).

    cl_abap_browser=>show_xml(
      xml_string = lv_xml
      container  = lo_container ).
    DATA(lv_html) = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'ABAP_BROWSER_XML' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'XML string fixture' ) ).

    cl_abap_browser=>show_xml(
      xml_xstring = lv_xxml
      container   = lo_container ).
    lv_html = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'ABAP_BROWSER_XML' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'XML xstring fixture' ) ).
  ENDMETHOD.

ENDCLASS.
