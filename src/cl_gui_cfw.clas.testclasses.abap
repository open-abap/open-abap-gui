CLASS ltcl_test DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    METHODS test1 FOR TESTING.
    METHODS cfw_lifecycle FOR TESTING.
    METHODS textedit_roundtrip FOR TESTING.
    METHODS container_and_column_state FOR TESTING.
    METHODS alv_editable_metadata FOR TESTING.
    METHODS alv_sort_filter_total FOR TESTING.
    METHODS alv_total_decimal_places FOR TESTING.
    METHODS alv_subtotals FOR TESTING.
    METHODS calendar_week_navigator FOR TESTING.
    METHODS dialogbox_nested_surface FOR TESTING.
    METHODS picture_safe_state FOR TESTING.
    METHODS html_control_snapshot FOR TESTING.
    METHODS html_control_registry FOR TESTING.
    METHODS alv_tree_outtab_roundtrip FOR TESTING.
    METHODS simple_tree_renders_nodes FOR TESTING.
    METHODS column_tree_renders_hierarchy FOR TESTING.
    METHODS html_alv_structured_rows FOR TESTING.
    METHODS html_alv_formatting FOR TESTING.
    METHODS control_capability_boundary FOR TESTING.
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

CLASS cl_gui_cfw DEFINITION LOCAL FRIENDS ltcl_test.

CLASS lcl_test_grid DEFINITION INHERITING FROM cl_gui_alv_grid.
  PUBLIC SECTION.
    METHODS show_boundary
      IMPORTING
        heading     TYPE string
        explanation TYPE string.
ENDCLASS.

CLASS lcl_test_grid IMPLEMENTATION.
  METHOD show_boundary.
    show_capability_boundary(
      heading     = heading
      explanation = explanation ).
  ENDMETHOD.
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

  METHOD cfw_lifecycle.
    DATA lv_rc TYPE i.
    DATA lv_return_code TYPE i.

    cl_gui_cfw=>reset( ).
    cl_gui_cfw=>set_new_ok_code(
      EXPORTING
        new_code = 'BACK'
      IMPORTING
        rc       = lv_rc ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_rc
      exp = 0 ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_gui_cfw=>get_new_ok_code( )
      exp = 'BACK' ).
    cl_gui_cfw=>dispatch( IMPORTING return_code = lv_return_code ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_return_code
      exp = 0 ).
    cl_gui_cfw=>dispatch( IMPORTING return_code = lv_return_code ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_return_code
      exp = cl_gui_cfw=>rc_noevent ).
    cl_gui_cfw=>flush( ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_gui_cfw=>get_flush_count( )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_gui_cfw=>get_update_count( )
      exp = 1 ).
  ENDMETHOD.

  METHOD textedit_roundtrip.
    DATA lt_input TYPE string_table.
    DATA lt_output TYPE string_table.
    DATA lv_modified TYPE i.
    DATA lv_from_line TYPE i.
    DATA lv_from_pos TYPE i.
    DATA lv_to_line TYPE i.
    DATA lv_to_pos TYPE i.
    DATA lv_text TYPE string.
    DATA lv_file_result TYPE abap_bool.

    cl_gui_control=>clear( ).
    DATA(lo_root) = NEW cl_gui_custom_container( container_name = 'TEXTEDIT-ROUNDTRIP' ).
    DATA(lo_editor) = NEW cl_gui_textedit( parent = lo_root ).
    lo_editor->set_toolbar_mode( cl_gui_textedit=>true ).
    lo_editor->set_statusbar_mode( cl_gui_textedit=>true ).
    lo_editor->set_font_fixed( cl_gui_textedit=>true ).
    lo_editor->set_wordwrap_behavior(
      wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
      wordwrap_position          = 72
      wordwrap_to_linebreak_mode = 1 ).
    lo_editor->protect_lines( from_line = 1
                              to_line   = 1 ).
    lt_input = VALUE #( ( `first` ) ( `second` ) ( `third` ) ).
    lo_editor->set_text_as_r3table( lt_input ).
    lo_editor->get_text_as_r3table(
      IMPORTING
        table       = lt_output
        is_modified = lv_modified ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_output )
      exp = 3 ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_output[ 2 ]
      exp = 'second' ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_modified
      exp = 1 ).
    lo_editor->go_to_line( 99 ).
    lo_editor->get_selection_pos(
      IMPORTING
        from_line = lv_from_line
        to_line   = lv_to_line ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_from_line
      exp = 3 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_to_line
      exp = 3 ).
    lo_editor->set_selection_pos( from_line = 2
                                  from_pos  = 1
                                  to_line   = 3
                                  to_pos    = 2 ).
    lo_editor->get_selection_pos(
      IMPORTING
        from_line = lv_from_line
        from_pos  = lv_from_pos
        to_line   = lv_to_line
        to_pos    = lv_to_pos ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_from_line
      exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_from_pos
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_to_line
      exp = 3 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_to_pos
      exp = 2 ).

    DATA(lv_html) = cl_gui_control=>render_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-textedit-toolbar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-textedit-tool-button' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'COMMAND:TEXTEDIT_CUT' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-textedit-statusbar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Li 3, Co 3' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Ln 1 - Ln 3 of 3 lines' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-wordwrap-position="72"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-protected-from="1"' ) ).

    DATA(lv_host_html) = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'TEXTEDIT-ROUNDTRIP' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_host_html CS 'gg-textedit-shell' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_host_html CS 'height:100%' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_host_html CS 'height:42px' ) ).

    lo_editor->delete_text( ).
    lo_editor->get_textstream(
      IMPORTING
        text        = lv_text
        is_modified = lv_modified ).
    cl_abap_unit_assert=>assert_initial( lv_text ).
    lv_file_result = lo_editor->open_local_file( filename = 'C:\\desktop\\text.txt' ).
    cl_abap_unit_assert=>assert_false( act = lv_file_result ).
    lv_file_result = lo_editor->save_as_local_file( filename = 'C:\\desktop\\text.txt' ).
    cl_abap_unit_assert=>assert_false( act = lv_file_result ).
  ENDMETHOD.

  METHOD container_and_column_state.
    DATA(lv_heading) = VALUE treev_hhdr(
      heading = 'Hierarchy'
      tooltip = 'Tree heading'
      width   = 180 ).

    cl_gui_control=>clear( ).
    DATA(lo_root) = NEW cl_gui_custom_container( container_name = 'NAMED-ROOT' ).
    DATA(lo_tree) = NEW cl_gui_column_tree(
      parent                = lo_root
      node_selection_mode   = cl_tree_control_base=>node_sel_mode_single
      item_selection        = abap_true
      hierarchy_column_name = 'TREE'
      hierarchy_header      = lv_heading ).
    lo_tree->add_column(
      name        = 'DETAIL'
      width       = 120
      header_text = 'Detail' ).
    lo_tree->hierarchy_header_set_text( 'Updated hierarchy' ).
    lo_tree->column_set_hidden( column_name = 'DETAIL'
                                hidden      = abap_false ).
    DATA(lv_html) = cl_gui_control=>render_html( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'name=NAMED-ROOT' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Updated hierarchy' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-column-name="DETAIL"' ) ).
  ENDMETHOD.

  METHOD alv_editable_metadata.
    TYPES: BEGIN OF ty_row,
             flag TYPE c LENGTH 1,
             note TYPE string,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lt_fcat TYPE lvc_t_fcat.
    DATA lt_columns TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA lt_selected_columns TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

    cl_gui_control=>clear( ).
    DATA(lo_root) = NEW cl_gui_custom_container( container_name = 'ALV-ROOT' ).
    DATA(lo_grid) = NEW cl_gui_alv_grid( i_parent = lo_root ).
    APPEND VALUE #( flag = 'X' note = 'edit me' ) TO lt_rows.
    APPEND VALUE #( fieldname = 'FLAG' coltext = 'Flag' checkbox = 'X' ) TO lt_fcat.
    APPEND VALUE #( fieldname = 'NOTE' coltext = 'Note' edit = 'X' hotspot = 'X' ) TO lt_fcat.
    lo_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = lt_rows
        it_fieldcatalog = lt_fcat ).
    APPEND 2 TO lt_columns.
    lo_grid->set_selected_columns( it_col_table = lt_columns ).
    lo_grid->get_selected_columns( IMPORTING et_index_columns = lt_selected_columns ).
    DATA(lv_html) = cl_gui_control=>render_html( ).

    cl_abap_unit_assert=>assert_equals(
      act = lt_selected_columns[ 1 ]
      exp = 2 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'type="checkbox"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'value="edit me"' ) ).
  ENDMETHOD.

  METHOD alv_sort_filter_total.
    TYPES: BEGIN OF ty_row,
             carrier TYPE c LENGTH 3,
             seats   TYPE i,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lt_fcat TYPE lvc_t_fcat.
    DATA lt_filtered TYPE lvc_t_fidx.

    cl_gui_control=>clear( ).
    DATA(lo_root) = NEW cl_gui_custom_container( container_name = 'ALV-CRITERIA' ).
    DATA(lo_grid) = NEW cl_gui_alv_grid( i_parent = lo_root ).
    lt_rows = VALUE #( ( carrier = 'LH' seats = 180 )
                       ( carrier = 'UA' seats = 210 )
                       ( carrier = 'LH' seats = 160 ) ).
    lt_fcat = VALUE #( ( fieldname = 'CARRIER' coltext = 'Carrier' )
                       ( fieldname = 'SEATS' coltext = 'Seats' do_sum = 'X' ) ).
    lo_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = lt_rows
        it_fieldcatalog = lt_fcat ).
    lo_grid->set_filter_criteria( VALUE #( ( fieldname = 'CARRIER'
                                             sign      = 'I'
                                             option    = 'CP'
                                             low       = 'L*' ) ) ).
    lo_grid->set_sort_criteria( VALUE #( ( fieldname = 'SEATS'
                                           down      = 'X'
                                           spos      = 1 ) ) ).
    lo_grid->get_filtered_entries( IMPORTING et_filtered_entries = lt_filtered ).
    DATA(lv_html) = cl_gui_control=>render_html( ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_filtered )
      exp = 1 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>180</td>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>160</td>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '>210</td>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-grid-total' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>340</td>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-alv-tool-button' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label="Refresh"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label="Sort ascending"' ) ).
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD picture_safe_state.
    DATA lv_result TYPE i.
    cl_gui_control=>clear( ).
    DATA(lo_root) = NEW cl_gui_custom_container( container_name = 'PICTURE-ROOT' ).
    DATA(lo_picture) = NEW cl_gui_picture( parent = lo_root ).
    lo_picture->load_picture_from_url(
      EXPORTING
        url    = 'javascript:alert(1)'
      IMPORTING
        result = lv_result ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_result
      exp = 4 ).
    DATA(lv_rejected_html) = cl_gui_control=>render_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_rejected_html CS 'data-picture-state="rejected"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_rejected_html CS 'src="javascript:' ) ).
    lo_picture->load_picture_from_url_async( '/assets/icons/refresh.svg' ).
    lo_picture->set_display_mode( cl_gui_picture=>display_mode_fit_center ).
    lo_picture->set_3d_border( 1 ).
    DATA(lv_html) = cl_gui_control=>render_html( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'src="/assets/icons/refresh.svg"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-picture-state="loaded"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-display-mode="4"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'object-fit:contain' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'javascript:' ) ).
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

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-calendar-week-grid' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'type="date"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'role="tree"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-alv' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-tree-node gg-state' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-grid-row gg-state' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-state-readonly' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label="ALV toolbar" data-toolbar-scope="control"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'sandbox=""' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'javascript:' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lo_salv->get_html( ) CS 'SALV &amp; table' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-salv-table' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<root>' ) ).
    cl_gui_control=>clear_external_html( ).
  ENDMETHOD.

  METHOD calendar_week_navigator.
    DATA lv_april_offset TYPE i.
    DATA lv_january_offset TYPE i.

    cl_gui_control=>clear( ).
    DATA(lo_root) = NEW cl_gui_custom_container( container_name = 'CALENDAR-WEEK-NAVIGATOR' ).
    DATA(lo_calendar) = NEW cl_gui_calendar(
      parent         = lo_root
      view_style     = 4
      focus_date     = '20260824'
      display_months = 3
      week_begin_day = 1 ).
    DATA(lv_html) = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'CALENDAR-WEEK-NAVIGATOR' ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-month-count="10"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'rowspan="2">WN</th>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>2026/4</th>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>2027/1</th>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>MO</th>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>SU</th>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-date="20260824" aria-selected="true"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'type="date"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'data-date-range="/"' ) ).
    FIND FIRST OCCURRENCE OF '>2026/4</th>' IN lv_html MATCH OFFSET lv_april_offset.
    FIND FIRST OCCURRENCE OF '>2027/1</th>' IN lv_html MATCH OFFSET lv_january_offset.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_april_offset < lv_january_offset ) ).
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD dialogbox_nested_surface.
    DATA lv_html TYPE string.
    DATA lv_textedit_count TYPE i.

    cl_gui_control=>clear( ).
    DATA(lo_root) = NEW cl_gui_custom_container( container_name = 'DIALOG-HOST' ).
    DATA(lo_dialog) = NEW cl_gui_dialogbox_container(
      parent  = lo_root
      left    = 80
      top     = 60
      width   = 600
      height  = 320
      caption = 'SAP GUI modeless control dialog' ).
    DATA(lo_editor) = NEW cl_gui_textedit( parent = lo_dialog ).
    lo_editor->set_textstream( 'The owning dynpro remains active.' ).
    lv_html = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'DIALOG-HOST' ).
    FIND ALL OCCURRENCES OF 'data-control-kind="TEXTEDIT"' IN lv_html MATCH COUNT lv_textedit_count.

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lv_textedit_count ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="gg-dialog-title">SAP GUI modeless control dialog</header>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="gg-dialog-body"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-dialog-width="600"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-dialog-height="320"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'The owning dynpro remains active.' ) ).
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD alv_tree_outtab_roundtrip.
    DATA lt_rows TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lt_fieldcat TYPE lvc_t_fcat.
    DATA lo_toolbar TYPE REF TO cl_gui_toolbar.
    DATA lv_root TYPE lvc_nkey.
    DATA lv_leaf TYPE lvc_nkey.
    DATA lv_row TYPE string.
    DATA lv_outtab_line TYPE string.
    DATA ls_header TYPE treev_hhdr.
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'ALV_TREE_OUTTAB' ).
    DATA(lo_tree) = NEW cl_gui_alv_tree( parent = lo_container ).

    APPEND 'row' TO lt_rows.
    ls_header = VALUE #( heading = 'Product hierarchy' width = 34 ).
    lo_tree->set_table_for_first_display(
      EXPORTING
        is_hierarchy_header = ls_header
      CHANGING
        it_outtab           = lt_rows
        it_fieldcatalog     = lt_fieldcat ).
    lo_tree->add_node(
      EXPORTING
        i_relat_node_key = space
        i_relationship   = cl_tree_control_base=>relat_last_child
        i_node_text      = 'Root'
      IMPORTING
        e_new_node_key   = lv_root ).
    lv_row = 'Row data'.
    lo_tree->add_node(
      EXPORTING
        i_relat_node_key = lv_root
        i_relationship   = cl_tree_control_base=>relat_last_child
        is_outtab_line   = lv_row
        i_node_text      = 'Leaf'
      IMPORTING
        e_new_node_key   = lv_leaf ).
    lo_tree->get_toolbar_object( IMPORTING er_toolbar = lo_toolbar ).
    lo_toolbar->add_button( fcode     = 'TEST'
                            icon      = '@00@'
                            butn_type = 0
                            text      = 'Tree action' ).
    lo_tree->frontend_update( ).
    DATA(lv_html) = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'ALV_TREE_OUTTAB' ).

    lo_tree->get_outtab_line(
      EXPORTING
        i_node_key    = lv_leaf
      IMPORTING
        e_outtab_line = lv_outtab_line ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_outtab_line
      exp = lv_row ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Tree action' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-toolbar-button-type="0"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="wb-icon"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-alv-tree-toolbar-spacer' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'height:32px' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<table role="tree" aria-label="ALV tree"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<ul role="tree"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-node-key="TREE-1"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>Product hierarchy</th>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'style="width:221px;min-width:221px;max-width:221px"' ) ).
  ENDMETHOD.

  METHOD simple_tree_renders_nodes.
    DATA lt_nodes TYPE string_table.

    cl_gui_control=>clear( ).
    DATA(lo_root) = NEW cl_gui_custom_container( container_name = 'SIMPLE-TREE-TEST' ).
    DATA(lo_tree) = NEW cl_gui_simple_tree( parent = lo_root ).
    lt_nodes = VALUE #( ( `Root` ) ( `Editor` ) ).
    lo_tree->add_nodes( table_structure_name = 'TREEV_NODE'
                        node_table           = lt_nodes ).

    DATA(lv_html) = cl_gui_control=>render_html( iv_document = abap_false ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>Root</li>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>Editor</li>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'Tree nodes:' ) ).
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD alv_subtotals.
    TYPES: BEGIN OF ty_row,
             category TYPE c LENGTH 10,
             quantity TYPE i,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lt_fcat TYPE lvc_t_fcat.
    DATA lt_sort TYPE lvc_t_sort.
    DATA lv_audio_offset TYPE i.
    DATA lv_display_offset TYPE i.
    DATA lv_input_offset TYPE i.
    DATA lv_total_offset TYPE i.

    cl_gui_control=>clear( ).
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'ALV-SUBTOTALS' ).
    DATA(lo_grid) = NEW cl_gui_alv_grid( i_parent = lo_container ).
    lt_rows = VALUE #(
      ( category = 'Display' quantity = 7 )
      ( category = 'Input' quantity = 11 )
      ( category = 'Audio' quantity = 2 )
      ( category = 'Audio' quantity = 3 ) ).
    lt_fcat = VALUE #(
      ( fieldname = 'CATEGORY' coltext = 'Category' )
      ( fieldname = 'QUANTITY' coltext = 'Quantity' do_sum = 'X' ) ).
    lt_sort = VALUE #(
      ( spos = 1 fieldname = 'CATEGORY' up = 'X' subtot = 'X' ) ).
    lo_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = lt_rows
        it_fieldcatalog = lt_fcat
        it_sort         = lt_sort ).
    DATA(lv_html) = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'ALV-SUBTOTALS' ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-subtotal-value="Audio"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-subtotal-value="Display"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-subtotal-value="Input"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-fieldname="QUANTITY">5</td>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-fieldname="QUANTITY">7</td>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-fieldname="QUANTITY">11</td>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-grid-total gg-state-total' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-fieldname="QUANTITY">23</td>' ) ).
    FIND FIRST OCCURRENCE OF 'data-subtotal-value="Audio"' IN lv_html MATCH OFFSET lv_audio_offset.
    FIND FIRST OCCURRENCE OF 'data-subtotal-value="Display"' IN lv_html MATCH OFFSET lv_display_offset.
    FIND FIRST OCCURRENCE OF 'data-subtotal-value="Input"' IN lv_html MATCH OFFSET lv_input_offset.
    FIND FIRST OCCURRENCE OF '<tfoot>' IN lv_html MATCH OFFSET lv_total_offset.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_audio_offset < lv_display_offset ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_display_offset < lv_input_offset ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_input_offset < lv_total_offset ) ).
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD alv_total_decimal_places.
    TYPES: BEGIN OF ty_row,
             explicit_price TYPE p LENGTH 8 DECIMALS 2,
             inferred_price TYPE p LENGTH 8 DECIMALS 2,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lt_fcat TYPE lvc_t_fcat.

    cl_gui_control=>clear( ).
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'ALV-TOTAL-DECIMALS' ).
    DATA(lo_grid) = NEW cl_gui_alv_grid( i_parent = lo_container ).
    lt_rows = VALUE #(
      ( explicit_price = '10.10' inferred_price = '1.20' )
      ( explicit_price = '2.30' inferred_price = '0.40' ) ).
    lt_fcat = VALUE #(
      ( fieldname = 'EXPLICIT_PRICE' do_sum = 'X' decimals_o = 2 )
      ( fieldname = 'INFERRED_PRICE' do_sum = 'X' ) ).
    lo_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = lt_rows
        it_fieldcatalog = lt_fcat ).
    DATA(lv_html) = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'ALV-TOTAL-DECIMALS' ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-fieldname="EXPLICIT_PRICE">12.40</td>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-fieldname="INFERRED_PRICE">1.60</td>' ) ).
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD column_tree_renders_hierarchy.
    TYPES: BEGIN OF ty_item,
             node_key  TYPE tv_nodekey,
             item_name TYPE tv_itmname,
             class     TYPE i,
             text      TYPE string,
           END OF ty_item.
    DATA lt_nodes TYPE treev_ntab.
    DATA lt_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.
    DATA ls_header TYPE treev_hhdr.

    cl_gui_control=>clear( ).
    DATA(lo_host) = NEW cl_gui_custom_container( container_name = 'COLUMN-TREE-HIERARCHY' ).
    ls_header-heading = 'Hierarchy'.
    ls_header-width = 220.
    DATA(lo_tree) = NEW cl_gui_column_tree(
      parent                = lo_host
      node_selection_mode   = cl_gui_column_tree=>node_sel_mode_single
      item_selection        = abap_false
      hierarchy_column_name = 'NODE'
      hierarchy_header      = ls_header ).
    lt_nodes = VALUE #(
      ( node_key = 'ROOT' isfolder = abap_true n_image = '@04@' exp_image = '@05@' )
      ( node_key = 'CORE' relatkey = 'ROOT' isfolder = abap_true n_image = '@04@' exp_image = '@05@' )
      ( node_key = 'LEAF' relatkey = 'CORE' n_image = '@3Y@' )
      ( node_key = 'LAZY' relatkey = 'ROOT' isfolder = abap_true expander = abap_true n_image = '@04@' exp_image = '@05@' ) ).
    lt_items = VALUE #(
      ( node_key = 'ROOT' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Tree controls' )
      ( node_key = 'CORE' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Core API' )
      ( node_key = 'LEAF' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Containers' )
      ( node_key = 'LAZY' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Lazy children' ) ).
    lo_tree->add_nodes_and_items(
      node_table                = lt_nodes
      item_table                = lt_items
      item_table_structure_name = 'TREEMCITAC' ).
    lo_tree->expand_root_nodes( level_count = 2 ).

    DATA(lv_html) = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'COLUMN-TREE-HIERARCHY' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-tree-level="2"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-tree-level="3"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'padding-left:18px' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'padding-left:36px' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-node-key="LAZY"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-expanded="false"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'href="#wb-icon-folder-open"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'href="#wb-icon-file-code"' ) ).
    cl_gui_control=>clear( ).
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

  METHOD html_alv_formatting.
    TYPES: BEGIN OF ty_row,
             name        TYPE c LENGTH 10,
             category    TYPE c LENGTH 10,
             quantity    TYPE i,
             action      TYPE c LENGTH 12,
             icon        TYPE c LENGTH 4,
             symbol      TYPE c LENGTH 1,
             exception   TYPE i,
             row_color   TYPE c LENGTH 4,
             cell_colors TYPE lvc_t_scol,
             styles      TYPE lvc_t_styl,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lt_fcat TYPE lvc_t_fcat.

    cl_gui_control=>clear( ).
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'ALV-FORMATTING' ).
    DATA(lo_grid) = NEW cl_gui_alv_grid( i_parent = lo_container ).
    lt_rows = VALUE #(
      ( name = 'Primary' category = 'Audio' quantity = 7 action = 'Inspect'
        icon = '@01@' symbol = '+' exception = 3 row_color = 'C210'
        cell_colors = VALUE #( ( fname = 'CATEGORY' color = VALUE #( col = 5 ) ) )
        styles = VALUE #( ( fieldname = 'ACTION' style = cl_gui_alv_grid=>mc_style_button )
                          ( fieldname = 'QUANTITY' style = cl_gui_alv_grid=>mc_style_disabled ) ) )
      ( name = 'Backup' category = 'Storage' quantity = 0 action = 'Inspect'
        icon = '@02@' symbol = '-' exception = 1
        cell_colors = VALUE #( ( fname = 'CATEGORY' color = VALUE #( col = 6 inv = 1 ) ) ) ) ).
    lt_fcat = VALUE #(
      ( fieldname = 'NAME' coltext = 'Name' emphasize = 'C510' )
      ( fieldname = 'CATEGORY' coltext = 'Category' )
      ( fieldname = 'QUANTITY' coltext = 'Quantity' )
      ( fieldname = 'ACTION' coltext = 'Action' )
      ( fieldname = 'ICON' coltext = 'Icon' icon = abap_true )
      ( fieldname = 'SYMBOL' coltext = 'Symbol' symbol = abap_true )
      ( fieldname = 'EXCEPTION' coltext = 'Light' ) ).
    lo_grid->set_table_for_first_display(
      EXPORTING
        is_layout       = VALUE lvc_s_layo(
          ctab_fname = 'CELL_COLORS'
          info_fname = 'ROW_COLOR'
          stylefname = 'STYLES'
          excp_fname = 'EXCEPTION'
          excp_led   = abap_true )
      CHANGING
        it_outtab       = lt_rows
        it_fieldcatalog = lt_fcat ).

    DATA(lv_html) = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'ALV-FORMATTING' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'href="#wb-icon-circle-check"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'href="#wb-icon-circle-x"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label="Green traffic light"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label="Red traffic light"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-alv-symbol-positive' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&#x25C6;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-alv-symbol-negative' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-lvc-color="C210"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-lvc-color="500"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-lvc-color="C510"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-lvc-style="button"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-alv-style-button' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-lvc-style="disabled"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '@01@' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '@02@' ) ).
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD control_capability_boundary.
    cl_gui_control=>clear( ).
    DATA(lo_root) = NEW cl_gui_custom_container( container_name = 'ALV-BOUNDARY' ).
    DATA(lo_grid) = NEW lcl_test_grid( i_parent = lo_root ).
    lo_grid->show_boundary(
      heading     = 'Dynamic table <unavailable>'
      explanation = 'No rows & styles were changed.' ).

    DATA(lv_html) = cl_gui_control=>render_html(
      iv_document       = abap_false
      iv_container_name = 'ALV-BOUNDARY' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-capability-boundary' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Dynamic table &lt;unavailable&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'No rows &amp; styles were changed.' ) ).
    cl_gui_control=>clear( ).
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
