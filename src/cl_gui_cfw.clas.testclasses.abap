CLASS ltcl_test DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    METHODS test1 FOR TESTING.
    METHODS html_control_snapshot FOR TESTING.
    METHODS html_control_registry FOR TESTING.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD test1.

    DATA lv_xpixel TYPE i.

    lv_xpixel = cl_gui_cfw=>compute_pixel_from_metric( x_or_y = 'X'
                                                       in = 1 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_xpixel
      exp = 1 ).

  ENDMETHOD.

  METHOD html_control_snapshot.
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'ROOT' ).
    DATA(lo_textedit) = NEW cl_gui_textedit(
      parent = lo_container
      wordwrap_to_linebreak_mode = 0 ).
    lo_textedit->set_textstream( '<unsafe>' ).
    lo_textedit->set_position( left = 4 top = 5 width = 120 height = 30 ).
    DATA(lv_html) = cl_gui_control=>render_html( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<textarea' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;unsafe&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'left:4px;top:5px' ) ).
  ENDMETHOD.

  METHOD html_control_registry.
    DATA lv_node TYPE lvc_nkey.
    DATA lt_rows TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lt_fcat TYPE lvc_t_fcat.
    DATA lt_html TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lt_salv_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'REGISTRY' ).
    DATA(lo_calendar) = NEW cl_gui_calendar( parent = lo_container focus_date = '20260828' ).
    lo_calendar->set_selection( date_begin = '20260828' date_end = '20260829' ).
    DATA(lo_tree) = NEW cl_gui_alv_tree( parent = lo_container ).
    lo_tree->add_node(
      EXPORTING
        i_relat_node_key = ''
        i_relationship   = cl_tree_control_base=>relat_first_child
        i_node_text      = '<root>'
      IMPORTING
        e_new_node_key   = lv_node ).
    DATA(lo_grid) = NEW cl_gui_alv_grid( i_parent = lo_container ).
    DATA(lo_viewer) = NEW cl_gui_html_viewer( parent = lo_container ).
    DATA(lo_picture) = NEW cl_gui_picture( parent = lo_container ).
    APPEND '<row>' TO lt_rows.
    APPEND VALUE #( fieldname = 'VALUE' coltext = 'Value' ) TO lt_fcat.
    lo_grid->set_table_for_first_display(
      CHANGING
        it_outtab = lt_rows
        it_fieldcatalog = lt_fcat ).
    APPEND '<script>alert(1)</script>' TO lt_html.
    lo_viewer->load_data( CHANGING data_table = lt_html ).
    lo_picture->load_picture_from_url( url = 'javascript:alert(1)' ).
    APPEND 1 TO lt_salv_rows.
    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table = lt_salv_rows ).
    lo_salv->set_list_header( 'SALV & table' ).
    lo_salv->display( ).
    DATA(lv_html) = cl_gui_control=>render_html( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'type="date"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'role="tree"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-alv' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'sandbox=""' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'javascript:' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lo_salv->get_html( ) CS 'SALV &amp; table' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-salv-table' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<root>' ) ).
    cl_gui_control=>clear_external_html( ).
  ENDMETHOD.

ENDCLASS.
