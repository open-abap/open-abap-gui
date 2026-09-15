CLASS ltcl_html_viewer_history DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    METHODS keeps_document_history FOR TESTING.

ENDCLASS.

CLASS ltcl_html_viewer_history IMPLEMENTATION.

  METHOD keeps_document_history.
    DATA lt_document TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lv_url TYPE c LENGTH 255.
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'HTML_HISTORY' ).
    DATA(lo_viewer) = NEW cl_gui_html_viewer( parent = lo_container ).

    APPEND '<h1>First</h1>' TO lt_document.
    lo_viewer->load_data(
      EXPORTING
        url        = 'about:first'
      CHANGING
        data_table = lt_document ).
    CLEAR lt_document.
    APPEND '<h1>Second</h1>' TO lt_document.
    lo_viewer->load_data(
      EXPORTING
        url        = 'about:second'
      CHANGING
        data_table = lt_document ).
    lo_viewer->go_back( ).
    lo_viewer->get_current_url( IMPORTING url = lv_url ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_url
      exp = 'about:first' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( cl_gui_control=>render_html( ) CS 'First' ) ).

    lo_viewer->go_forward( ).
    lo_viewer->get_current_url( IMPORTING url = lv_url ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_url
      exp = 'about:second' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( cl_gui_control=>render_html( ) CS 'Second' ) ).

    lo_viewer->close_document( ).
    lo_viewer->get_current_url( IMPORTING url = lv_url ).
    cl_abap_unit_assert=>assert_initial( lv_url ).
  ENDMETHOD.

ENDCLASS.
