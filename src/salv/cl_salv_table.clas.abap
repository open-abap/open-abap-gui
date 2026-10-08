CLASS cl_salv_table DEFINITION PUBLIC INHERITING FROM cl_salv_model_base.
  PUBLIC SECTION.
    TYPES ty_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

    CLASS-METHODS is_offline
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS set_end_of_list
      IMPORTING
        value TYPE REF TO cl_salv_form_element.

    CLASS-METHODS factory
      IMPORTING
        list_display   TYPE any OPTIONAL
        r_container    TYPE any OPTIONAL
        container_name TYPE clike OPTIONAL
      EXPORTING
        r_salv_table   TYPE REF TO cl_salv_table
      CHANGING
        t_table        TYPE any.

    METHODS get_screen_status
      EXPORTING
        report   TYPE syrepid
        pfstatus TYPE any.

    METHODS get_selections RETURNING VALUE(val) TYPE REF TO cl_salv_selections.
    METHODS close_screen.
    METHODS refresh
      IMPORTING
        s_stable     TYPE any OPTIONAL
        refresh_mode TYPE any OPTIONAL
      PREFERRED PARAMETER s_stable.
    METHODS display.

    METHODS get_metadata.
    METHODS get_layout
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_layout.
    METHODS set_screen_popup
      IMPORTING
        start_column TYPE i
        end_column   TYPE i
        start_line   TYPE i
        end_line     TYPE i.

    METHODS get_event
      RETURNING
        VALUE(val) TYPE REF TO cl_salv_events_table.

    METHODS get_display_settings
      RETURNING
        VALUE(val) TYPE REF TO cl_salv_display_settings.

    METHODS set_striped_pattern IMPORTING value TYPE any.
    METHODS set_list_header IMPORTING val TYPE any.
    METHODS set_top_of_list IMPORTING value TYPE REF TO cl_salv_form_element.
    METHODS set_top_of_list_print IMPORTING value TYPE REF TO cl_salv_form_element.
    METHODS get_columns RETURNING VALUE(val) TYPE REF TO cl_salv_columns_table.
    METHODS get_functions RETURNING VALUE(val) TYPE REF TO cl_salv_functions_list.

    METHODS get_aggregations
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_aggregations.
    METHODS get_filters
      RETURNING
        VALUE(foo) TYPE REF TO cl_salv_filters.

    METHODS to_xml
      IMPORTING
        xml_type   TYPE any
      RETURNING
        VALUE(xml) TYPE xstring.

    METHODS get_sorts
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_sorts.

    METHODS get_functional_settings
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_functional_settings.

    METHODS get_html
      RETURNING
        VALUE(value) TYPE string.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_html_cell,
             columnname TYPE lvc_fname,
             text       TYPE string,
           END OF ty_html_cell.
    TYPES ty_html_cells TYPE STANDARD TABLE OF ty_html_cell WITH DEFAULT KEY.
    TYPES: BEGIN OF ty_html_row,
             index TYPE i,
             cells TYPE ty_html_cells,
           END OF ty_html_row.
    TYPES ty_html_rows TYPE STANDARD TABLE OF ty_html_row WITH DEFAULT KEY.

    DATA mv_row_count TYPE i.
    DATA mv_header TYPE string.
    DATA mr_table TYPE REF TO data.
    DATA mt_html_rows TYPE ty_html_rows.
    DATA mo_selections TYPE REF TO cl_salv_selections.
    DATA mo_layout TYPE REF TO cl_salv_layout.
    DATA mo_columns TYPE REF TO cl_salv_columns_table.
    DATA mo_functions TYPE REF TO cl_salv_functions_list.
    DATA mo_events TYPE REF TO cl_salv_events_table.
    DATA mo_display_settings TYPE REF TO cl_salv_display_settings.
    DATA mo_aggregations TYPE REF TO cl_salv_aggregations.
    DATA mo_filters TYPE REF TO cl_salv_filters.
    DATA mo_sorts TYPE REF TO cl_salv_sorts.
    DATA mo_functional_settings TYPE REF TO cl_salv_functional_settings.
    DATA mo_container TYPE REF TO cl_gui_container.
    DATA mo_grid TYPE REF TO cl_gui_alv_grid.
    DATA mo_top_of_list TYPE REF TO cl_salv_form_element.
    DATA mo_end_of_list TYPE REF TO cl_salv_form_element.
* In a container the SALV table is a grid control; its events are the SALV
* table's events.
    METHODS on_grid_double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.
    METHODS on_grid_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
    METHODS on_grid_user_command FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm.
    DATA mr_display_table TYPE REF TO data.

    METHODS build_metadata.
    METHODS collect_rows.
    METHODS rebuild_html
      RETURNING
        VALUE(value) TYPE string.
* Shows the table: in its container when the factory got one, otherwise as
* fullscreen output.
    METHODS publish.
* Hands the SALV model to an ALV grid, which does all of the rendering.
    METHODS fill_grid
      IMPORTING
        io_grid TYPE REF TO cl_gui_alv_grid.
    METHODS field_catalog
      RETURNING
        VALUE(result) TYPE lvc_t_fcat.
    METHODS is_table_column
      IMPORTING
        iv_columnname TYPE lvc_fname
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS ddic_field
      IMPORTING
        io_type       TYPE REF TO cl_abap_typedescr
      RETURNING
        VALUE(result) TYPE dfies.
* The ALV function codes behind one SALV function name. Names that are not
* SALV standard functions have none; they are application functions.
    METHODS function_codes
      IMPORTING
        iv_name       TYPE salv_de_function
      RETURNING
        VALUE(result) TYPE ui_functions.
    METHODS toolbar_excluding
      RETURNING
        VALUE(result) TYPE ui_functions.
    METHODS application_toolbar
      RETURNING
        VALUE(result) TYPE ttb_button.
    METHODS passes_filters
      IMPORTING
        columnname    TYPE lvc_fname
        value         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS selopt_matches
      IMPORTING
        selopt        TYPE REF TO cl_salv_selopt
        value         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS compare_option
      IMPORTING
        iv_value         TYPE string
        iv_option        TYPE string
        iv_low           TYPE string
        iv_high          TYPE string OPTIONAL
        iv_sign          TYPE string OPTIONAL
        iv_unknown_as_eq TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result)    TYPE abap_bool.
ENDCLASS.

CLASS cl_salv_table IMPLEMENTATION.
  METHOD get_screen_status.
    report = sy-repid.
    CLEAR pfstatus.
  ENDMETHOD.

  METHOD set_end_of_list.
    mo_end_of_list = value.
    publish( ).
  ENDMETHOD.

  METHOD set_top_of_list_print.
    publish( ).
  ENDMETHOD.

  METHOD get_sorts.
    IF mo_sorts IS NOT BOUND.
      mo_sorts = NEW cl_salv_sorts( ).
    ENDIF.
    value = mo_sorts.
  ENDMETHOD.

  METHOD get_functional_settings.
    IF mo_functional_settings IS NOT BOUND.
      mo_functional_settings = NEW cl_salv_functional_settings( ).
    ENDIF.
    value = mo_functional_settings.
  ENDMETHOD.

  METHOD get_layout.
    IF mo_layout IS NOT BOUND.
      mo_layout = NEW cl_salv_layout( ).
    ENDIF.
    value = mo_layout.
  ENDMETHOD.

  METHOD to_xml.
    DATA(lv_html) = get_html( ).
    DATA(lo_converter) = cl_abap_conv_out_ce=>create( ).
    lo_converter->write( data = lv_html ).
    xml = lo_converter->get_buffer( ).
  ENDMETHOD.

  METHOD get_filters.
    IF mo_filters IS NOT BOUND.
      mo_filters = NEW cl_salv_filters( ).
    ENDIF.
    foo = mo_filters.
  ENDMETHOD.

  METHOD get_aggregations.
    IF mo_aggregations IS NOT BOUND.
      mo_aggregations = NEW cl_salv_aggregations( ).
    ENDIF.
    value = mo_aggregations.
  ENDMETHOD.

  METHOD get_functions.
    IF mo_functions IS NOT BOUND.
      mo_functions = NEW cl_salv_functions_list( ).
    ENDIF.
    val = mo_functions.
  ENDMETHOD.

  METHOD get_metadata.
    build_metadata( ).
  ENDMETHOD.

  METHOD set_striped_pattern.
    get_display_settings( )->set_striped_pattern( CONV abap_bool( value ) ).
    publish( ).
  ENDMETHOD.

  METHOD set_list_header.
    mv_header = CONV string( val ).
  ENDMETHOD.

  METHOD factory.
    r_salv_table = NEW cl_salv_table( ).
    r_salv_table->mv_row_count = lines( t_table ).
    GET REFERENCE OF t_table INTO r_salv_table->mr_table.
    r_salv_table->mo_selections = NEW cl_salv_selections( ).
    r_salv_table->mo_layout = NEW cl_salv_layout( ).
    r_salv_table->mo_columns = NEW cl_salv_columns_table( ).
    r_salv_table->mo_functions = NEW cl_salv_functions_list( ).
    r_salv_table->mo_events = NEW cl_salv_events_table( ).
    r_salv_table->mo_display_settings = NEW cl_salv_display_settings( ).
    r_salv_table->mo_aggregations = NEW cl_salv_aggregations( ).
    r_salv_table->mo_filters = NEW cl_salv_filters( ).
    r_salv_table->mo_sorts = NEW cl_salv_sorts( ).
    r_salv_table->mo_functional_settings = NEW cl_salv_functional_settings( ).
    IF r_container IS SUPPLIED.
      TRY.
          r_salv_table->mo_container ?= r_container.
        CATCH cx_sy_move_cast_error.
          CLEAR r_salv_table->mo_container.
      ENDTRY.
    ENDIF.
    r_salv_table->build_metadata( ).
  ENDMETHOD.

  METHOD is_offline.
    value = abap_false.
  ENDMETHOD.

  METHOD get_selections.
    IF mo_selections IS NOT BOUND.
      mo_selections = NEW cl_salv_selections( ).
    ENDIF.
    val = mo_selections.
  ENDMETHOD.

  METHOD close_screen.
    cl_gui_control=>clear_external_html( ).
  ENDMETHOD.

  METHOD refresh.
    publish( ).
  ENDMETHOD.

  METHOD display.
    publish( ).
  ENDMETHOD.

  METHOD set_screen_popup.
    cl_gui_control=>set_external_html( get_html( ) ).
  ENDMETHOD.

  METHOD get_event.
    IF mo_events IS NOT BOUND.
      mo_events = NEW cl_salv_events_table( ).
    ENDIF.
    val = mo_events.
  ENDMETHOD.

  METHOD get_display_settings.
    IF mo_display_settings IS NOT BOUND.
      mo_display_settings = NEW cl_salv_display_settings( ).
    ENDIF.
    val = mo_display_settings.
  ENDMETHOD.

  METHOD set_top_of_list.
    mo_top_of_list = value.
    publish( ).
  ENDMETHOD.

  METHOD get_columns.
    IF mo_columns IS NOT BOUND.
      mo_columns = NEW cl_salv_columns_table( ).
    ENDIF.
    val = mo_columns.
  ENDMETHOD.

  METHOD get_html.
    value = rebuild_html( ).
  ENDMETHOD.

  METHOD build_metadata.
    DATA lo_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lo_line_descr TYPE REF TO cl_abap_datadescr.
    DATA lo_struct_descr TYPE REF TO cl_abap_structdescr.
    FIELD-SYMBOLS <lt_table> TYPE ANY TABLE.

    IF mr_table IS NOT BOUND OR mo_columns IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN mr_table->* TO <lt_table>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( <lt_table> ).
    lo_line_descr = lo_table_descr->get_table_line_type( ).
    IF lo_line_descr->kind = cl_abap_typedescr=>kind_struct.
      lo_struct_descr ?= lo_line_descr.
      LOOP AT lo_struct_descr->get_components( ) INTO DATA(ls_component).
        mo_columns->add_column( CONV lvc_fname( ls_component-name ) ).
      ENDLOOP.
    ELSE.
      mo_columns->add_column( 'VALUE' ).
    ENDIF.
  ENDMETHOD.

  METHOD rebuild_html.
    IF mo_grid IS NOT BOUND.
      mo_grid = NEW cl_gui_alv_grid( i_parent = mo_container ).
      IF mo_container IS NOT BOUND.
        mo_grid->enable_fullscreen_events( ).
      ENDIF.
      SET HANDLER on_grid_double_click FOR mo_grid.
      SET HANDLER on_grid_hotspot_click FOR mo_grid.
      SET HANDLER on_grid_user_command FOR mo_grid.
      DATA(lo_selections) = get_selections( ).
      lo_selections->mo_grid = mo_grid.
    ENDIF.
    fill_grid( mo_grid ).
    value = mo_grid->render_model( ).
* The top and end of list frame the list, as in a fullscreen SALV list.
    IF mo_top_of_list IS BOUND.
      value = |<div class="gg-salv-top-of-list">{ mo_top_of_list->render_html( ) }</div>{ value }|.
    ENDIF.
    IF mo_end_of_list IS BOUND.
      value = |{ value }<div class="gg-salv-end-of-list">{ mo_end_of_list->render_html( ) }</div>|.
    ENDIF.
  ENDMETHOD.

  METHOD publish.
    IF mo_container IS NOT BOUND.
      cl_gui_control=>set_external_html( get_html( ) ).
      RETURN.
    ENDIF.
    IF mo_grid IS NOT BOUND.
      mo_grid = NEW cl_gui_alv_grid( i_parent = mo_container ).
      IF mo_container IS NOT BOUND.
        mo_grid->enable_fullscreen_events( ).
      ENDIF.
      SET HANDLER on_grid_double_click FOR mo_grid.
      SET HANDLER on_grid_hotspot_click FOR mo_grid.
      SET HANDLER on_grid_user_command FOR mo_grid.
      DATA(lo_selections) = get_selections( ).
      lo_selections->mo_grid = mo_grid.
    ENDIF.
    fill_grid( mo_grid ).
  ENDMETHOD.

  METHOD on_grid_double_click.
    get_event( ).
    mo_events->raise_double_click( row    = VALUE #( mt_html_rows[ e_row-index ]-index OPTIONAL )
                                   column = e_column-fieldname ).
  ENDMETHOD.

  METHOD on_grid_hotspot_click.
    get_event( ).
    mo_events->raise_link_click( row    = VALUE #( mt_html_rows[ e_row_id-index ]-index OPTIONAL )
                                 column = e_column_id-fieldname ).
  ENDMETHOD.

  METHOD on_grid_user_command.
    get_event( ).
    mo_events->raise_added_function( e_ucomm ).
  ENDMETHOD.

  METHOD fill_grid.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.
    FIELD-SYMBOLS <display> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line> TYPE any.
    FIELD-SYMBOLS <row> TYPE any.
    DATA lo_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lr_line TYPE REF TO data.
    DATA lt_fieldcatalog TYPE lvc_t_fcat.
    DATA ls_layout TYPE lvc_s_layo.
    DATA lt_excluding TYPE ui_functions.
    DATA lt_sort TYPE lvc_t_sort.
    DATA lv_index TYPE i.
    DATA lt_selected_rows TYPE salv_t_row.

    IF mo_columns IS NOT BOUND.
      mo_columns = NEW cl_salv_columns_table( ).
      build_metadata( ).
    ENDIF.
    CLEAR mt_html_rows.
    collect_rows( ).
    mv_row_count = lines( mt_html_rows ).
    IF mr_table IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN mr_table->* TO <table>.

* The grid reads a standard table. The program's own table is handed over when
* it is one and no filter hides rows, so row numbers stay the program's.
    lo_table_descr ?= cl_abap_typedescr=>describe_by_data( <table> ).
    IF lo_table_descr->table_kind = cl_abap_tabledescr=>tablekind_std
        AND mv_row_count = lines( <table> ).
      ASSIGN mr_table->* TO <display>.
    ELSE.
      CREATE DATA lr_line LIKE LINE OF <table>.
      ASSIGN lr_line->* TO <line>.
      CREATE DATA mr_display_table LIKE STANDARD TABLE OF <line>.
      ASSIGN mr_display_table->* TO <display>.
      LOOP AT <table> ASSIGNING <row>.
        lv_index = lv_index + 1.
        IF line_exists( mt_html_rows[ index = lv_index ] ).
          APPEND <row> TO <display>.
        ENDIF.
      ENDLOOP.
    ENDIF.

    lt_fieldcatalog = field_catalog( ).
    IF mo_display_settings IS BOUND.
      ls_layout-zebra = mo_display_settings->is_striped_pattern( ).
    ENDIF.
* A color column must hold a color table (LVC_T_SCOL); anything else is
* rejected.
    IF is_table_column( mo_columns->get_color_column( ) ) = abap_true.
      ls_layout-ctab_fname = mo_columns->get_color_column( ).
    ENDIF.
    ls_layout-excp_fname = mo_columns->get_exception_column( ).

    IF mo_selections IS BOUND.
      lt_selected_rows = mo_selections->get_selected_rows( ).
    ENDIF.
    CLEAR io_grid->mt_selected_rows.
    IF mo_selections IS NOT BOUND
        OR mo_selections->get_selection_mode( ) = if_salv_c_selection_mode=>none.
      ls_layout-no_rowmark = abap_true.
    ELSE.
      LOOP AT lt_selected_rows INTO DATA(lv_selected).
        READ TABLE mt_html_rows TRANSPORTING NO FIELDS WITH KEY index = lv_selected.
        IF sy-subrc = 0.
          APPEND VALUE #( index = sy-tabix ) TO io_grid->mt_selected_rows.
        ENDIF.
      ENDLOOP.
    ENDIF.
    IF mo_selections IS BOUND.
      mo_selections->mt_row_map = VALUE #( FOR ls_map IN mt_html_rows ( ls_map-index ) ).
    ENDIF.
    IF mv_header IS NOT INITIAL.
      io_grid->mv_gridtitle = mv_header.
    ELSEIF mo_display_settings IS BOUND.
      io_grid->mv_gridtitle = mo_display_settings->get_list_header( ).
    ENDIF.
    lt_excluding = toolbar_excluding( ).
* The sorts become the grid's sort criteria, with their subtotals.
    IF mo_sorts IS BOUND.
      LOOP AT mo_sorts->get( ) INTO DATA(ls_sort).
        APPEND VALUE #( spos      = sy-tabix
                        fieldname = ls_sort-columnname
                        up        = xsdbool( ls_sort-r_sort->get_sequence( ) <> if_salv_c_sort=>sort_down )
                        down      = xsdbool( ls_sort-r_sort->get_sequence( ) = if_salv_c_sort=>sort_down )
                        subtot    = ls_sort-r_sort->is_subtotalled( ) ) TO lt_sort.
      ENDLOOP.
    ENDIF.
    io_grid->mt_toolbar = application_toolbar( ).
    io_grid->set_table_for_first_display(
      EXPORTING
        is_layout            = ls_layout
        it_toolbar_excluding = lt_excluding
      CHANGING
        it_outtab            = <display>
        it_fieldcatalog      = lt_fieldcatalog
        it_sort              = lt_sort ).
  ENDMETHOD.

  METHOD field_catalog.
    DATA lo_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lo_line_descr TYPE REF TO cl_abap_datadescr.
    DATA lo_struct_descr TYPE REF TO cl_abap_structdescr.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    DATA lo_column_list TYPE REF TO cl_salv_column_list.
    DATA ls_fieldcat TYPE lvc_s_fcat.
    DATA ls_ddic TYPE dfies.
    DATA ls_color TYPE lvc_s_colo.
    FIELD-SYMBOLS <lt_table> TYPE ANY TABLE.

    IF mr_table IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN mr_table->* TO <lt_table>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lo_table_descr ?= cl_abap_typedescr=>describe_by_data( <lt_table> ).
    lo_line_descr = lo_table_descr->get_table_line_type( ).
    IF lo_line_descr->kind = cl_abap_typedescr=>kind_struct.
      lo_struct_descr ?= lo_line_descr.
    ENDIF.

    LOOP AT mo_columns->get( ) INTO DATA(ls_column).
      CLEAR: ls_fieldcat, ls_ddic, lo_type.
      ls_fieldcat-col_pos = sy-tabix.
      ls_fieldcat-fieldname = ls_column-columnname.
      IF lo_struct_descr IS BOUND.
        lo_struct_descr->get_component_type(
          EXPORTING
            p_name              = ls_column-columnname
          RECEIVING
            p_descr_ref         = lo_type
          EXCEPTIONS
            component_not_found = 1
            OTHERS              = 2 ).
        IF sy-subrc <> 0.
          CLEAR lo_type.
        ENDIF.
      ELSE.
        lo_type = lo_line_descr.
      ENDIF.
* Only elementary fields have a cell value. Tables such as a color column
* are read through the layout, never printed.
      IF lo_type IS NOT BOUND OR lo_type->kind <> cl_abap_typedescr=>kind_elem.
        ls_fieldcat-tech = abap_true.
      ELSE.
        ls_fieldcat-inttype = SWITCH #( lo_type->type_kind
          WHEN cl_abap_typedescr=>typekind_int1
            OR cl_abap_typedescr=>typekind_int2
            OR cl_abap_typedescr=>typekind_int8 THEN 'I'
          WHEN cl_abap_typedescr=>typekind_decfloat16
            OR cl_abap_typedescr=>typekind_decfloat34 THEN 'P'
          ELSE lo_type->type_kind ).
        ls_ddic = ddic_field( lo_type ).
      ENDIF.

* Texts the program set win over the DDIC field labels.
      ls_fieldcat-scrtext_l = ls_column-r_column->get_long_text( ).
      IF ls_fieldcat-scrtext_l IS INITIAL.
        ls_fieldcat-scrtext_l = ls_ddic-scrtext_l.
      ENDIF.
      ls_fieldcat-scrtext_m = ls_column-r_column->get_medium_text( ).
      IF ls_fieldcat-scrtext_m IS INITIAL.
        ls_fieldcat-scrtext_m = ls_ddic-scrtext_m.
      ENDIF.
      ls_fieldcat-scrtext_s = ls_column-r_column->get_short_text( ).
      IF ls_fieldcat-scrtext_s IS INITIAL.
        ls_fieldcat-scrtext_s = ls_ddic-scrtext_s.
      ENDIF.
      ls_fieldcat-coltext = COND #(
        WHEN ls_fieldcat-scrtext_l IS NOT INITIAL THEN ls_fieldcat-scrtext_l
        WHEN ls_fieldcat-scrtext_m IS NOT INITIAL THEN ls_fieldcat-scrtext_m
        ELSE ls_fieldcat-scrtext_s ).
      ls_fieldcat-tooltip = ls_column-r_column->get_tooltip( ).
      ls_fieldcat-outputlen = ls_column-r_column->get_output_length( ).
      ls_fieldcat-cfieldname = ls_column-r_column->get_currency_column( ).
      ls_fieldcat-qfieldname = ls_column-r_column->get_quantity_column( ).
      IF ls_column-r_column->is_technical( ) = abap_true.
        ls_fieldcat-tech = abap_true.
      ENDIF.
      IF ls_column-r_column->is_visible( ) = abap_false.
        ls_fieldcat-no_out = abap_true.
      ENDIF.

      TRY.
          lo_column_list ?= ls_column-r_column.
          ls_fieldcat-icon = lo_column_list->is_icon( ).
          ls_fieldcat-key = lo_column_list->is_key( ).
          ls_color = lo_column_list->get_color( ).
          IF ls_color-col <> 0.
            ls_fieldcat-emphasize = |C{ ls_color-col }{ ls_color-int }{ ls_color-inv }|.
          ENDIF.
          CASE lo_column_list->get_cell_type( ).
            WHEN if_salv_c_cell_type=>checkbox OR if_salv_c_cell_type=>checkbox_hotspot.
              ls_fieldcat-checkbox = abap_true.
            WHEN if_salv_c_cell_type=>hotspot OR if_salv_c_cell_type=>link.
              ls_fieldcat-hotspot = abap_true.
          ENDCASE.
        CATCH cx_sy_move_cast_error.
          CLEAR lo_column_list.
      ENDTRY.
      IF mo_aggregations IS BOUND.
        ls_fieldcat-do_sum = mo_aggregations->is_aggregated( ls_column-columnname ).
      ENDIF.
      APPEND ls_fieldcat TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD is_table_column.
    DATA lo_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lo_struct_descr TYPE REF TO cl_abap_structdescr.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    FIELD-SYMBOLS <lt_table> TYPE ANY TABLE.

    IF mr_table IS NOT BOUND OR iv_columnname IS INITIAL.
      RETURN.
    ENDIF.
    ASSIGN mr_table->* TO <lt_table>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lo_table_descr ?= cl_abap_typedescr=>describe_by_data( <lt_table> ).
    IF lo_table_descr->get_table_line_type( )->kind <> cl_abap_typedescr=>kind_struct.
      RETURN.
    ENDIF.
    lo_struct_descr ?= lo_table_descr->get_table_line_type( ).
    lo_struct_descr->get_component_type(
      EXPORTING
        p_name              = iv_columnname
      RECEIVING
        p_descr_ref         = lo_type
      EXCEPTIONS
        component_not_found = 1
        OTHERS              = 2 ).
    result = xsdbool( sy-subrc = 0 AND lo_type->kind = cl_abap_typedescr=>kind_table ).
  ENDMETHOD.

  METHOD ddic_field.
    DATA lo_element TYPE REF TO cl_abap_elemdescr.

    IF io_type->kind <> cl_abap_typedescr=>kind_elem OR io_type->is_ddic_type( ) = abap_false.
      RETURN.
    ENDIF.
    lo_element ?= io_type.
    lo_element->get_ddic_field(
      RECEIVING
        p_flddescr   = result
      EXCEPTIONS
        not_found    = 1
        no_ddic_type = 2
        OTHERS       = 3 ).
    IF sy-subrc <> 0.
      CLEAR result.
    ENDIF.
  ENDMETHOD.

  METHOD function_codes.
    CASE iv_name.
      WHEN 'SORT_ASC'.
        result = VALUE #( ( '&SORT_ASC' ) ).
      WHEN 'SORT_DESC'.
        result = VALUE #( ( '&SORT_DSC' ) ).
      WHEN 'GROUP_SORT'.
        result = VALUE #( ( '&SORT_ASC' ) ( '&SORT_DSC' ) ).
      WHEN 'FIND'.
        result = VALUE #( ( '&FIND' ) ).
      WHEN 'FILTER' OR 'GROUP_FILTER'.
        result = VALUE #( ( '&FILTER' ) ).
      WHEN 'GROUP_AGGREGATION'.
        result = VALUE #( ( '&SUMC' ) ( '&SUBTOT' ) ).
      WHEN 'PRINT' OR 'PRINT_PREVIEW'.
        result = VALUE #( ( '&PRINT' ) ).
      WHEN 'EXPORT_SPREADSHEET' OR 'VIEW_EXCEL'.
        result = VALUE #( ( '&XML' ) ).
      WHEN 'EXPORT_LOCALFILE'.
        result = VALUE #( ( '&PC' ) ).
      WHEN 'LAYOUT_SAVE'.
        result = VALUE #( ( '&SAVE' ) ).
      WHEN 'GROUP_LAYOUT'.
        result = VALUE #( ( '&COL0' ) ( '&LOAD' ) ( '&SAVE' ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD toolbar_excluding.
* SALV is read-only, so only its display functions can appear, and only the
* ones the program enabled. With none enabled the table has no toolbar.
    DATA lt_offered TYPE ui_functions.
    DATA lt_allowed TYPE ui_functions.
    DATA lv_code TYPE ui_func.

    lt_offered = VALUE #(
      ( '&SORT_ASC' ) ( '&SORT_DSC' ) ( '&FIND' ) ( '&FILTER' ) ( '&SUMC' ) ( '&SUBTOT' )
      ( '&PRINT' ) ( '&XML' ) ( '&PC' ) ( '&COL0' ) ( '&LOAD' ) ( '&SAVE' ) ).
    IF mo_functions IS BOUND.
      IF mo_functions->mv_all = abap_true.
        lt_allowed = lt_offered.
      ENDIF.
      LOOP AT mo_functions->mt_functions INTO DATA(ls_function).
        LOOP AT function_codes( ls_function-name ) INTO lv_code.
          DELETE lt_allowed WHERE table_line = lv_code.
          IF ls_function-function->get_visible( ) = abap_true.
            APPEND lv_code TO lt_allowed.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
    IF lt_allowed IS INITIAL.
      result = VALUE #( ( cl_gui_alv_grid=>mc_fc_excl_all ) ).
      RETURN.
    ENDIF.
    result = VALUE #(
      ( '&REFRESH' ) ( '&ALL' ) ( '&LOCAL&APPEND' ) ( '&LOCAL&DELETE_ROW' ) ( '&UNDO' ) ( '&HELP' ) ).
    LOOP AT lt_offered INTO lv_code.
      IF NOT line_exists( lt_allowed[ table_line = lv_code ] ).
        APPEND lv_code TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD application_toolbar.
    IF mo_functions IS NOT BOUND.
      RETURN.
    ENDIF.
    LOOP AT mo_functions->mt_functions INTO DATA(ls_function).
      IF function_codes( ls_function-name ) IS NOT INITIAL
          OR ls_function-function->get_visible( ) = abap_false.
        CONTINUE.
      ENDIF.
      APPEND VALUE #( function  = ls_function-name
                      text      = ls_function-function->get_text( )
                      quickinfo = ls_function-function->get_tooltip( ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD collect_rows.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <component> TYPE any.
    DATA ls_row TYPE ty_html_row.
    DATA lo_component_type TYPE REF TO cl_abap_typedescr.
    DATA lv_index TYPE i.

    IF mr_table IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN mr_table->* TO <table>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT <table> ASSIGNING <row>.
      CLEAR ls_row.
      lv_index = lv_index + 1.
      ls_row-index = lv_index.
      DATA(lv_matches) = abap_true.
      LOOP AT mo_columns->get( ) INTO DATA(ls_column).
        DATA(lv_text) = ``.
        ASSIGN COMPONENT ls_column-columnname OF STRUCTURE <row> TO <component>.
        IF sy-subrc = 0.
          TRY.
              lo_component_type = cl_abap_typedescr=>describe_by_data( <component> ).
              IF lo_component_type->kind <> cl_abap_typedescr=>kind_table
                  AND lo_component_type->kind <> cl_abap_typedescr=>kind_struct
                  AND lo_component_type->kind <> cl_abap_typedescr=>kind_ref.
                lv_text = |{ <component> }|.
              ENDIF.
            CATCH cx_root.
              CLEAR lv_text.
          ENDTRY.
        ELSEIF ls_column-columnname = 'VALUE'.
          lv_text = |{ <row> }|.
        ENDIF.
        APPEND VALUE #( columnname = ls_column-columnname
                        text       = lv_text ) TO ls_row-cells.
        IF passes_filters( columnname = ls_column-columnname
                           value      = lv_text ) = abap_false.
          lv_matches = abap_false.
        ENDIF.
      ENDLOOP.
      IF lv_matches = abap_true.
        APPEND ls_row TO mt_html_rows.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD passes_filters.
    result = abap_true.
    IF mo_filters IS NOT BOUND.
      RETURN.
    ENDIF.
    LOOP AT mo_filters->get( ) INTO DATA(ls_filter) WHERE columnname = columnname.
      LOOP AT ls_filter-r_filter->get( ) INTO DATA(lo_selopt).
        result = selopt_matches( selopt = lo_selopt
                                 value  = value ).
        RETURN.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD selopt_matches.
    result = compare_option(
      iv_value  = value
      iv_option = CONV string( selopt->get_option( ) )
      iv_low    = CONV string( selopt->get_low( ) )
      iv_high   = CONV string( selopt->get_high( ) )
      iv_sign   = CONV string( selopt->get_sign( ) ) ).
  ENDMETHOD.

  METHOD compare_option.
    DATA lv_value TYPE decfloat34.
    DATA lv_low TYPE decfloat34.
    DATA lv_high TYPE decfloat34.

* A numeric column compares with the select-option as numbers: 90 is less
* than 100.
    DATA(lv_numeric) = xsdbool( matches( val   = condense( iv_value )
                                         regex = '^-?[0-9]+([.][0-9]+)?$' )
                            AND matches( val   = condense( iv_low )
                                         regex = '^-?[0-9]+([.][0-9]+)?$' )
                            AND ( iv_high IS INITIAL OR matches( val   = condense( iv_high )
                                                                 regex = '^-?[0-9]+([.][0-9]+)?$' ) ) ).
    IF lv_numeric = abap_true.
      lv_value = condense( iv_value ).
      lv_low = condense( iv_low ).
      IF iv_high IS NOT INITIAL.
        lv_high = condense( iv_high ).
      ENDIF.
      CASE to_upper( iv_option ).
        WHEN 'EQ'.
          result = xsdbool( lv_value = lv_low ).
        WHEN 'NE'.
          result = xsdbool( lv_value <> lv_low ).
        WHEN 'BT'.
          result = xsdbool( lv_value >= lv_low AND lv_value <= lv_high ).
        WHEN 'NB'.
          result = xsdbool( lv_value < lv_low OR lv_value > lv_high ).
        WHEN 'GE'.
          result = xsdbool( lv_value >= lv_low ).
        WHEN 'GT'.
          result = xsdbool( lv_value > lv_low ).
        WHEN 'LE'.
          result = xsdbool( lv_value <= lv_low ).
        WHEN 'LT'.
          result = xsdbool( lv_value < lv_low ).
        WHEN OTHERS.
          lv_numeric = abap_false.
      ENDCASE.
    ENDIF.
    IF lv_numeric = abap_false.
      CASE to_upper( iv_option ).
        WHEN 'EQ'.
          result = xsdbool( iv_value = iv_low ).
        WHEN 'NE'.
          result = xsdbool( iv_value <> iv_low ).
        WHEN 'BT'.
          result = xsdbool( iv_value >= iv_low AND iv_value <= iv_high ).
        WHEN 'NB'.
          result = xsdbool( iv_value < iv_low OR iv_value > iv_high ).
        WHEN 'GE'.
          result = xsdbool( iv_value >= iv_low ).
        WHEN 'GT'.
          result = xsdbool( iv_value > iv_low ).
        WHEN 'LE'.
          result = xsdbool( iv_value <= iv_low ).
        WHEN 'LT'.
          result = xsdbool( iv_value < iv_low ).
        WHEN 'CP'.
          result = xsdbool( iv_value CP iv_low ).
        WHEN 'NP'.
          result = xsdbool( iv_value NP iv_low ).
        WHEN OTHERS.
          result = xsdbool( iv_unknown_as_eq = abap_true AND iv_value = iv_low ).
      ENDCASE.
    ENDIF.
    IF iv_sign = 'E'.
      result = xsdbool( result = abap_false ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
