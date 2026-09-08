CLASS ltcl_test DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    METHODS test1 FOR TESTING.
    METHODS html_control_snapshot FOR TESTING.
    METHODS html_control_registry FOR TESTING.
    METHODS html_alv_structured_rows FOR TESTING.
    METHODS html_typed_surface FOR TESTING.
    METHODS html_viewer_sapevent FOR TESTING.
    METHODS html_viewer_without_sapevent FOR TESTING.

    METHODS viewer_html
      IMPORTING
        iv_document    TYPE string
        iv_register    TYPE abap_bool
        iv_transport   TYPE abap_bool
      RETURNING
        VALUE(rv_html) TYPE string.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD test1.

    DATA lv_xpixel TYPE i.

    lv_xpixel = cl_gui_cfw=>compute_pixel_from_metric( x_or_y = 'X'
                                                       in     = 1 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_xpixel
      exp = 1 ).

  ENDMETHOD.

  METHOD html_control_snapshot.
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'ROOT' ).
    DATA(lo_textedit) = NEW cl_gui_textedit(
      parent                     = lo_container
      wordwrap_to_linebreak_mode = 0 ).
    lo_textedit->set_textstream( '<unsafe>' ).
    lo_textedit->set_position( left   = 4
                               top    = 5
                               width  = 120
                               height = 30 ).
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
    DATA(lo_calendar) = NEW cl_gui_calendar( parent     = lo_container
                                             focus_date = '20260828' ).
    lo_calendar->set_selection( date_begin = '20260828'
                                date_end   = '20260829' ).
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
        it_outtab       = lt_rows
        it_fieldcatalog = lt_fcat ).
    APPEND '<script>alert(1)</script>' TO lt_html.
    lo_viewer->load_data( CHANGING data_table = lt_html ).
    lo_picture->load_picture_from_url( url = 'javascript:alert(1)' ).
    APPEND 1 TO lt_salv_rows.
    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_salv_rows ).
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

  METHOD html_alv_structured_rows.
    TYPES: BEGIN OF ty_row,
             carrier    TYPE c LENGTH 3,
             connection TYPE i,
             note       TYPE string,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lt_fcat TYPE lvc_t_fcat.
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'STRUCTURED_ALV' ).
    DATA(lo_grid) = NEW cl_gui_alv_grid( i_parent = lo_container ).

    APPEND VALUE #( carrier = 'AA' connection = 17 note = '<unsafe>' ) TO lt_rows.
    APPEND VALUE #( fieldname = 'CARRIER' coltext = 'Carrier' ) TO lt_fcat.
    APPEND VALUE #( fieldname = 'CONNECTION' coltext = 'Connection' ) TO lt_fcat.
    APPEND VALUE #( fieldname = 'NOTE' coltext = 'Note' ) TO lt_fcat.
    lo_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = lt_rows
        it_fieldcatalog = lt_fcat ).
    DATA(lv_html) = cl_gui_control=>render_html( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-fieldname="CARRIER">AA</td>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-fieldname="CONNECTION">17</td>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-fieldname="NOTE">&lt;unsafe&gt;</td>' ) ).
  ENDMETHOD.

  METHOD html_typed_surface.
    cl_gui_control=>clear( ).
    zcl_gg_host_surface=>clear( ).
    zcl_gg_host_surface=>set_surface( VALUE #(
      kind       = zcl_gg_host_surface=>surface_document
      aria_label = `Typed <surface>`
      title      = `"><script>alert(1)</script>`
      text       = `A & B`
      link_label = 'Unsafe link'
      link_href  = `javascript:alert(1)`
      actions    = VALUE #( ( transport = zcl_gg_host_surface=>surface_action_ucomm
                               value    = `SAVE" onclick="alert(1)`
                               label    = `Save & go` ) ) ) ).
    zcl_gg_host_surface=>set_surface( VALUE #(
      kind          = zcl_gg_host_surface=>surface_table
      aria_label    = `<typed-table>`
      table_caption = `<typed-caption>`
      columns       = VALUE #( ( `<typed-column>` ) )
      rows          = VALUE #( ( cell1 = `<typed-cell>` cell2 = `&typed-value`
                                 cell3 = `"` row_header = abap_true ) )
      text          = `<typed-text>`
      criteria      = `<typed-criteria>`
      input_label   = `<typed-input-label>`
      input_name    = `"><typed-input-name`
      input_value   = `<typed-input-value>`
      token_label   = `<typed-token-label>`
      token_value   = `"><typed-token`
      data_value    = `<typed-aggregate>`
      actions       = VALUE #( ( value = `"><script>alert(1)</script>`
                                 label = `<typed-action>` ) ) ) ).
    zcl_gg_host_surface=>set_surface( VALUE #(
      kind        = zcl_gg_host_surface=>surface_tree
      aria_label  = `<typed-tree>`
      nodes       = VALUE #( ( text = `<typed-node>` node_key = `"><typed-key>`
                              level = 1 expanded = abap_true ) )
      token_label = `<typed-tree-token-label>`
      token_value = `<typed-tree-token>` ) ).
    zcl_gg_host_surface=>set_surface( VALUE #(
      kind       = zcl_gg_host_surface=>surface_chart
      aria_label = `<typed-chart>`
      title      = `<typed-chart-title>`
      columns    = VALUE #( ( `<typed-chart-column>` ) )
      rows       = VALUE #( ( cell1 = `<typed-chart-cell>` ) )
      payload    = `<typed-chart-payload>` ) ).
    zcl_gg_host_surface=>set_surface( VALUE #(
      kind       = zcl_gg_host_surface=>surface_alert
      control_id = `"><typed-control`
      text       = `<typed-alert>` ) ).
    zcl_gg_host_surface=>set_surface( VALUE #(
      kind = zcl_gg_host_surface=>surface_caption
      text = `<typed-caption-text>` ) ).
    zcl_gg_host_surface=>set_surface( VALUE #(
      kind       = zcl_gg_host_surface=>surface_cockpit
      aria_label = `<typed-cockpit>`
      title      = `<typed-cockpit-title>`
      text       = `<typed-cockpit-text>`
      data_value = `<typed-cockpit-filter>`
      payload    = `<typed-cockpit-payload>` ) ).
    DATA(lv_html) = cl_gui_control=>render_html( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;script&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'A &amp; B' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Save &amp; go' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;typed-table&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;typed-column&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;typed-cell&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;typed-node&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;typed-key&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;typed-chart-payload&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;typed-control' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'javascript:alert' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'onclick="' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'onerror=' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<script>alert(1)</script>' ) ).
    cl_gui_control=>clear( ).
    zcl_gg_host_surface=>clear( ).
  ENDMETHOD.

  METHOD viewer_html.
    DATA lt_events TYPE cntl_simple_events.
    DATA lt_document TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA ls_sapevent TYPE cl_gui_control=>ty_sapevent.

    cl_gui_control=>clear( ).
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'SAPEVENT' ).
    DATA(lo_viewer) = NEW cl_gui_html_viewer( parent = lo_container ).
    IF iv_register = abap_true.
      APPEND VALUE #( eventid    = cl_gui_html_viewer=>m_id_sapevent
                      appl_event = abap_true ) TO lt_events.
      lo_viewer->set_registered_events( lt_events ).
    ENDIF.
    APPEND iv_document TO lt_document.
    lo_viewer->load_data( CHANGING data_table = lt_document ).
    IF iv_transport = abap_true.
      ls_sapevent = VALUE #(
        url          = '/dispatch'
        action_field = 'ucomm'
        fields       = VALUE #( ( name = 'session_id' value = 'HOST-1' )
                                ( name = 'action' value = 'COMMAND' ) ) ).
    ENDIF.
    rv_html = cl_gui_control=>render_html( iv_document = abap_false
                                           is_sapevent = ls_sapevent ).
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD html_viewer_sapevent.
    DATA(lv_html) = viewer_html(
      iv_register  = abap_true
      iv_transport = abap_true
      iv_document  = '<p><a class="keep" href="sapevent:STAGE" title="t">Stage &amp; go</a>' &&
                     '<a href="/manual">plain</a></p>' ).

* The document reaches the browser through srcdoc, so the whole rewritten
* document is escaped once more on the way out.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      'sandbox="allow-forms allow-top-navigation-by-user-activation"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      '&lt;form class=&quot;gg-sapevent&quot; method=&quot;post&quot; action=&quot;/dispatch&quot; target=&quot;_top&quot;&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      'name=&quot;session_id&quot; value=&quot;HOST-1&quot;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      'name=&quot;action&quot; value=&quot;COMMAND&quot;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      '&lt;button type=&quot;submit&quot; name=&quot;ucomm&quot; value=&quot;STAGE&quot;' ) ).
* Everything else the program put on the anchor survives on the button, and
* the markup the anchor wrapped becomes its label.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class=&quot;keep&quot;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'title=&quot;t&quot;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Stage &amp;amp; go&lt;/button&gt;&lt;/form&gt;' ) ).
* A link that is not a sapevent stays a link, and no sapevent href is left.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      '&lt;a href=&quot;/manual&quot;&gt;plain&lt;/a&gt;' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'sapevent:STAGE' ) ).
  ENDMETHOD.

  METHOD html_viewer_without_sapevent.
* No registration and no transport, so the viewer keeps the fully closed
* sandbox it has always had and the document is left exactly as it was.
    DATA(lv_unregistered) = viewer_html( iv_register  = abap_false
                                         iv_transport = abap_true
                                         iv_document  = '<a href="sapevent:STAGE">Stage</a>' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_unregistered CS 'sandbox=""' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_unregistered CS 'sapevent:STAGE' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_unregistered CS 'gg-sapevent' ) ).

    DATA(lv_no_transport) = viewer_html( iv_register  = abap_true
                                         iv_transport = abap_false
                                         iv_document  = '<a href="sapevent:STAGE">Stage</a>' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_no_transport CS 'sandbox=""' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_no_transport CS 'sapevent:STAGE' ) ).
  ENDMETHOD.

ENDCLASS.
