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
    METHODS set_top_of_list IMPORTING val TYPE any.
    METHODS set_top_of_list_print IMPORTING val TYPE any.
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

    METHODS build_metadata.
    METHODS collect_rows.
    METHODS rebuild_html
      RETURNING
        VALUE(value) TYPE string.
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
    cl_gui_control=>set_external_html( get_html( ) ).
  ENDMETHOD.

  METHOD set_top_of_list_print.
    cl_gui_control=>set_external_html( get_html( ) ).
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
    cl_gui_control=>set_external_html( get_html( ) ).
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
    cl_gui_control=>set_external_html( get_html( ) ).
  ENDMETHOD.

  METHOD display.
    cl_gui_control=>set_external_html( get_html( ) ).
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
    cl_gui_control=>set_external_html( get_html( ) ).
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

    IF mr_table IS NOT BOUND OR mo_columns IS NOT BOUND.
      RETURN.
    ENDIF.
    lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( mr_table->* ).
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
    DATA ls_row TYPE ty_html_row.
    DATA lv_select_header TYPE string.
    DATA lv_checked TYPE string.
    DATA lt_selected_rows TYPE salv_t_row.

    IF mo_columns IS NOT BOUND.
      mo_columns = NEW cl_salv_columns_table( ).
      build_metadata( ).
    ENDIF.
    CLEAR mt_html_rows.
    collect_rows( ).
    mv_row_count = lines( mt_html_rows ).

    DATA(lv_header) = mv_header.
    IF lv_header IS INITIAL AND mo_display_settings IS BOUND.
      lv_header = mo_display_settings->get_list_header( ).
    ENDIF.
    value = |<section class="gg-salv-table" aria-label="SALV table"><h2>{ cl_gui_control=>escape_html( lv_header ) }</h2><p>{ mv_row_count } rows</p><table><caption>{ cl_gui_control=>escape_html( lv_header ) }</caption><thead><tr>|.
    CLEAR lv_select_header.
    IF mo_selections IS BOUND
        AND mo_selections->get_selection_mode( ) <> if_salv_c_selection_mode=>none.
      lv_select_header = `<th scope="col">Select</th>`.
      lt_selected_rows = mo_selections->get_selected_rows( ).
    ENDIF.
    value = value && lv_select_header.
    LOOP AT mo_columns->get( ) INTO DATA(ls_heading).
      IF ls_heading-r_column->is_technical( ) = abap_true.
        CONTINUE.
      ENDIF.
      value = value && |<th scope="col" data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_heading-columnname ) ) }">{ cl_gui_control=>escape_html( CONV string( ls_heading-columnname ) ) }</th>|.
    ENDLOOP.
    value = value && |</tr></thead><tbody>|.
    LOOP AT mt_html_rows INTO ls_row.
      value = value && |<tr data-row-index="{ ls_row-index }">|.
      IF lv_select_header IS NOT INITIAL.
        CLEAR lv_checked.
        IF line_exists( lt_selected_rows[ table_line = ls_row-index ] ).
          lv_checked = ` checked`.
        ENDIF.
        value = value && |<td><input type="checkbox" name="gg-salv-row-{ ls_row-index }" aria-label="Select row { ls_row-index }"{ lv_checked }></td>|.
      ENDIF.
      LOOP AT ls_row-cells INTO DATA(ls_cell).
        TRY.
            IF mo_columns->get_column( ls_cell-columnname )->is_technical( ) = abap_true.
              CONTINUE.
            ENDIF.
          CATCH cx_salv_not_found.
            CONTINUE.
        ENDTRY.
        value = value && |<td data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_cell-columnname ) ) }">{ cl_gui_control=>escape_html( ls_cell-text ) }</td>|.
      ENDLOOP.
      value = value && |</tr>|.
    ENDLOOP.
    value = value && |</tbody></table></section>|.
  ENDMETHOD.

  METHOD collect_rows.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <component> TYPE any.
    DATA ls_row TYPE ty_html_row.
    DATA lo_component_type TYPE REF TO cl_abap_typedescr.

    IF mr_table IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN mr_table->* TO <table>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT <table> ASSIGNING <row>.
      CLEAR ls_row.
      ls_row-index = sy-tabix.
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
    IF iv_sign = 'E'.
      result = xsdbool( result = abap_false ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
