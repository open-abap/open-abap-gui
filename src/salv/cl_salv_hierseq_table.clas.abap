CLASS cl_salv_hierseq_table DEFINITION PUBLIC INHERITING FROM cl_salv_model_base.
  PUBLIC SECTION.

    CLASS-METHODS factory
      IMPORTING
        t_binding_level1_level2 TYPE salv_t_hierseq_binding
        r_container             TYPE REF TO cl_gui_container OPTIONAL
        container_name          TYPE clike OPTIONAL
      EXPORTING
        r_hierseq               TYPE REF TO cl_salv_hierseq_table
      CHANGING
        t_table_level1          TYPE STANDARD TABLE
        t_table_level2          TYPE STANDARD TABLE
      RAISING
        cx_salv_data_error
        cx_salv_not_found.

    METHODS get_columns
      IMPORTING
        level        TYPE i
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_columns_hierseq
      RAISING
        cx_salv_not_found.

    METHODS get_level
      IMPORTING
        level        TYPE i
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_hierseq_level
      RAISING
        cx_salv_not_found.

    METHODS get_selections
      IMPORTING
        level        TYPE i
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_selections
      RAISING
        cx_salv_not_found.

    METHODS get_functions
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_functions_list.

    METHODS get_layout
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_layout.

    METHODS get_sorts
      IMPORTING
        level        TYPE i
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_sorts
      RAISING
        cx_salv_not_found.

    METHODS get_filters
      IMPORTING
        level        TYPE i
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_filters
      RAISING
        cx_salv_not_found.

    METHODS get_aggregations
      IMPORTING
        level        TYPE i
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_aggregations
      RAISING
        cx_salv_not_found.

    METHODS get_event
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_events_hierseq.

    METHODS get_display_settings
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_display_settings.

    METHODS display.

    METHODS refresh.

  PRIVATE SECTION.
    DATA mr_table_level1 TYPE REF TO data.
    DATA mr_table_level2 TYPE REF TO data.
    DATA mt_binding TYPE salv_t_hierseq_binding.
    DATA mo_level1 TYPE REF TO cl_salv_hierseq_level.
    DATA mo_level2 TYPE REF TO cl_salv_hierseq_level.
    DATA mo_functions TYPE REF TO cl_salv_functions_list.
    DATA mo_layout TYPE REF TO cl_salv_layout.
    DATA mo_events TYPE REF TO cl_salv_events_hierseq.
    DATA mo_display_settings TYPE REF TO cl_salv_display_settings.

* The visible columns of a level: not technical, not hidden, and not the
* expand column, whose value only decides whether the items are shown.
    METHODS visible_columns
      IMPORTING
        io_columns    TYPE REF TO cl_salv_columns_hierseq
      RETURNING
        VALUE(result) TYPE salv_t_column_ref.

    METHODS column_heading
      IMPORTING
        io_column     TYPE REF TO cl_salv_column
      RETURNING
        VALUE(result) TYPE string.

    METHODS render_row
      IMPORTING
        is_row        TYPE any
        it_columns    TYPE salv_t_column_ref
        iv_level      TYPE i
        iv_width      TYPE i
      RETURNING
        VALUE(result) TYPE string.

    METHODS is_child
      IMPORTING
        is_header     TYPE any
        is_item       TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS is_expanded
      IMPORTING
        is_header     TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS colspan
      IMPORTING
        iv_index      TYPE i
        iv_count      TYPE i
        iv_width      TYPE i
      RETURNING
        VALUE(result) TYPE string.

    METHODS render_total_row
      IMPORTING
        it_columns    TYPE salv_t_column_ref
        iv_width      TYPE i
      RETURNING
        VALUE(result) TYPE string.

    METHODS format_total_value
      IMPORTING
        iv_value      TYPE decfloat34
        iv_decimals   TYPE i DEFAULT -1
        iv_sample     TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.

CLASS cl_salv_hierseq_table IMPLEMENTATION.

  METHOD factory.
    DATA lr_level1 TYPE REF TO data.
    DATA lr_level2 TYPE REF TO data.
    GET REFERENCE OF t_table_level1 INTO lr_level1.
    GET REFERENCE OF t_table_level2 INTO lr_level2.
    r_hierseq = NEW cl_salv_hierseq_table( ).
    r_hierseq->mr_table_level1 = lr_level1.
    r_hierseq->mr_table_level2 = lr_level2.
    r_hierseq->mt_binding = t_binding_level1_level2.
    r_hierseq->mo_level1 = NEW cl_salv_hierseq_level( binding = t_binding_level1_level2 ).
    r_hierseq->mo_level2 = NEW cl_salv_hierseq_level( binding = t_binding_level1_level2 ).
    r_hierseq->mo_level1->set_data(
      value     = lr_level1
      t_binding = t_binding_level1_level2 ).
    r_hierseq->mo_level2->set_data(
      value     = lr_level2
      t_binding = t_binding_level1_level2 ).
    r_hierseq->mo_functions = NEW cl_salv_functions_list( ).
    r_hierseq->mo_layout = NEW cl_salv_layout( ).
    r_hierseq->mo_events = NEW cl_salv_events_hierseq( ).
    r_hierseq->mo_display_settings = NEW cl_salv_display_settings( ).
  ENDMETHOD.

  METHOD get_columns.
    CASE level.
      WHEN 1.
        value = mo_level1->get_columns( ).
      WHEN 2.
        value = mo_level2->get_columns( ).
      WHEN OTHERS.
        RAISE EXCEPTION TYPE cx_salv_not_found.
    ENDCASE.
  ENDMETHOD.

  METHOD get_level.
    CASE level.
      WHEN 1.
        value = mo_level1.
      WHEN 2.
        value = mo_level2.
      WHEN OTHERS.
        RAISE EXCEPTION TYPE cx_salv_not_found.
    ENDCASE.
  ENDMETHOD.

  METHOD get_selections.
    CASE level.
      WHEN 1.
        value = mo_level1->get_selections( ).
      WHEN 2.
        value = mo_level2->get_selections( ).
      WHEN OTHERS.
        RAISE EXCEPTION TYPE cx_salv_not_found.
    ENDCASE.
  ENDMETHOD.

  METHOD get_functions.
    value = mo_functions.
  ENDMETHOD.

  METHOD get_layout.
    value = mo_layout.
  ENDMETHOD.

  METHOD get_sorts.
    CASE level.
      WHEN 1.
        value = mo_level1->get_sorts( ).
      WHEN 2.
        value = mo_level2->get_sorts( ).
      WHEN OTHERS.
        RAISE EXCEPTION TYPE cx_salv_not_found.
    ENDCASE.
  ENDMETHOD.

  METHOD get_filters.
    CASE level.
      WHEN 1.
        value = mo_level1->get_filters( ).
      WHEN 2.
        value = mo_level2->get_filters( ).
      WHEN OTHERS.
        RAISE EXCEPTION TYPE cx_salv_not_found.
    ENDCASE.
  ENDMETHOD.

  METHOD get_aggregations.
    CASE level.
      WHEN 1.
        value = mo_level1->get_aggregations( ).
      WHEN 2.
        value = mo_level2->get_aggregations( ).
      WHEN OTHERS.
        RAISE EXCEPTION TYPE cx_salv_not_found.
    ENDCASE.
  ENDMETHOD.

  METHOD get_event.
    value = mo_events.
  ENDMETHOD.

  METHOD get_display_settings.
    value = mo_display_settings.
  ENDMETHOD.

  METHOD display.
* A hierarchical-sequential list as SAP writes it: each header line followed
* by its items, the column headings of both levels on top, and the totals of
* the aggregated item columns at the end.
    FIELD-SYMBOLS <headers> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <items> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <header> TYPE any.
    FIELD-SYMBOLS <item> TYPE any.
    DATA lt_heading_columns TYPE salv_t_column_ref.
    DATA lv_html TYPE string.

    ASSIGN mr_table_level1->* TO <headers>.
    ASSIGN mr_table_level2->* TO <items>.
    DATA(lt_columns1) = visible_columns( mo_level1->get_columns( ) ).
    DATA(lt_columns2) = visible_columns( mo_level2->get_columns( ) ).
    DATA(lv_width) = nmax( val1 = lines( lt_columns1 )
                           val2 = lines( lt_columns2 ) ).
    DATA(lv_title) = CONV string( mo_display_settings->get_list_header( ) ).

    lv_html = `<section class="gg-alv gg-salv-hierseq" aria-label="Hierarchical-sequential list">`.
    IF lv_title IS NOT INITIAL.
      lv_html = lv_html && |<header><h2>{ cl_gui_control=>escape_html( lv_title ) }</h2></header>|.
    ENDIF.
    lv_html = lv_html && |<div class="gg-alv-grid-area"><table{ COND string( WHEN lv_title IS NOT INITIAL THEN | aria-label="{ cl_gui_control=>escape_html( lv_title ) }"| ) }><thead>|.
    DO 2 TIMES.
      DATA(lv_level) = sy-index.
      lt_heading_columns = COND #( WHEN lv_level = 1 THEN lt_columns1 ELSE lt_columns2 ).
      lv_html = lv_html && |<tr data-level="{ lv_level }">|.
      LOOP AT lt_heading_columns INTO DATA(ls_heading_column).
        DATA(lv_heading_span) = colspan( iv_index = sy-tabix
                                         iv_count = lines( lt_heading_columns )
                                         iv_width = lv_width ).
        lv_html = lv_html && |<th scope="col" data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_heading_column-columnname ) ) }"{ lv_heading_span }>{ cl_gui_control=>escape_html( column_heading( ls_heading_column-r_column ) ) }</th>|.
      ENDLOOP.
      lv_html = lv_html && `</tr>`.
    ENDDO.
    lv_html = lv_html && `</thead><tbody>`.
    LOOP AT <headers> ASSIGNING <header>.
      lv_html = lv_html && render_row( is_row     = <header>
                                       it_columns = lt_columns1
                                       iv_level   = 1
                                       iv_width   = lv_width ).
      IF is_expanded( <header> ) = abap_false.
        CONTINUE.
      ENDIF.
      LOOP AT <items> ASSIGNING <item>.
        IF is_child( is_header = <header>
                     is_item   = <item> ) = abap_true.
          lv_html = lv_html && render_row( is_row     = <item>
                                           it_columns = lt_columns2
                                           iv_level   = 2
                                           iv_width   = lv_width ).
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    lv_html = lv_html && `</tbody>` && render_total_row( it_columns = lt_columns2
                                                         iv_width   = lv_width ) && `</table></div></section>`.
    cl_gui_control=>set_external_html( lv_html ).
  ENDMETHOD.

  METHOD refresh.
    display( ).
  ENDMETHOD.

  METHOD visible_columns.
    LOOP AT io_columns->get( ) INTO DATA(ls_column).
      IF ls_column-r_column->is_technical( ) = abap_true
          OR ls_column-r_column->is_visible( ) = abap_false
          OR ls_column-columnname = io_columns->get_expand_column( ).
        CONTINUE.
      ENDIF.
      APPEND ls_column TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD column_heading.
    result = io_column->get_long_text( ).
    IF result IS INITIAL.
      result = io_column->get_medium_text( ).
    ENDIF.
    IF result IS INITIAL.
      result = io_column->get_short_text( ).
    ENDIF.
    IF result IS INITIAL.
      result = io_column->get_columnname( ).
    ENDIF.
  ENDMETHOD.

  METHOD colspan.
* The last cell of the narrower level spans the rest of the wider one.
    IF iv_index = iv_count AND iv_count < iv_width.
      result = | colspan="{ iv_width - iv_count + 1 }"|.
    ENDIF.
  ENDMETHOD.

  METHOD render_row.
    FIELD-SYMBOLS <key> TYPE any.
    FIELD-SYMBOLS <value> TYPE any.
    DATA lv_key TYPE string.
    DATA lv_type TYPE c LENGTH 1.

    READ TABLE mt_binding INTO DATA(ls_binding) INDEX 1.
    IF sy-subrc = 0.
      ASSIGN COMPONENT COND string( WHEN iv_level = 1 THEN ls_binding-master ELSE ls_binding-slave )
        OF STRUCTURE is_row TO <key>.
      IF sy-subrc = 0.
        lv_key = condense( CONV string( <key> ) ).
      ENDIF.
    ENDIF.
    result = |<tr data-level="{ iv_level }"{ COND string( WHEN iv_level = 1 THEN | data-group-key="{ cl_gui_control=>escape_html( lv_key ) }"| ELSE | data-parent-key="{ cl_gui_control=>escape_html( lv_key ) }"| ) }>|.
    LOOP AT it_columns INTO DATA(ls_column).
      DATA(lv_index) = sy-tabix.
      ASSIGN COMPONENT ls_column-columnname OF STRUCTURE is_row TO <value>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      DESCRIBE FIELD <value> TYPE lv_type.
      DATA(lv_cell_span) = colspan( iv_index = lv_index
                                    iv_count = lines( it_columns )
                                    iv_width = iv_width ).
      result = result && |<td data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_column-columnname ) ) }"{ COND string( WHEN lv_type CA 'IPFbsa8' THEN ` class="gg-type-number"` ) }{ lv_cell_span }>{ cl_gui_control=>escape_html( condense( CONV string( <value> ) ) ) }</td>|.
    ENDLOOP.
    result = result && `</tr>`.
  ENDMETHOD.

  METHOD is_child.
    FIELD-SYMBOLS <master> TYPE any.
    FIELD-SYMBOLS <slave> TYPE any.

    result = abap_true.
    LOOP AT mt_binding INTO DATA(ls_binding).
      ASSIGN COMPONENT ls_binding-master OF STRUCTURE is_header TO <master>.
      IF sy-subrc <> 0.
        result = abap_false.
        RETURN.
      ENDIF.
      ASSIGN COMPONENT ls_binding-slave OF STRUCTURE is_item TO <slave>.
      IF sy-subrc <> 0 OR <master> <> <slave>.
        result = abap_false.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD is_expanded.
* With an expand column each header line says whether its items are shown;
* without one the level setting decides for all of them.
    FIELD-SYMBOLS <expand> TYPE any.

    DATA(lv_expand_column) = mo_level1->get_columns( )->get_expand_column( ).
    IF lv_expand_column IS INITIAL.
      result = mo_level1->is_items_expanded( ).
      RETURN.
    ENDIF.
    ASSIGN COMPONENT lv_expand_column OF STRUCTURE is_header TO <expand>.
    IF sy-subrc = 0.
      result = xsdbool( <expand> IS NOT INITIAL ).
    ENDIF.
  ENDMETHOD.

  METHOD render_total_row.
    FIELD-SYMBOLS <items> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <item> TYPE any.
    FIELD-SYMBOLS <value> TYPE any.
    DATA lv_total TYPE decfloat34.
    DATA lv_sample TYPE string.
    DATA lv_aggregated TYPE abap_bool.

    DATA(lo_aggregations) = mo_level2->get_aggregations( ).
    LOOP AT it_columns INTO DATA(ls_column).
      IF lo_aggregations->is_aggregated( ls_column-columnname ) = abap_true.
        lv_aggregated = abap_true.
      ENDIF.
    ENDLOOP.
    IF lv_aggregated = abap_false.
      RETURN.
    ENDIF.
    ASSIGN mr_table_level2->* TO <items>.
    result = `<tfoot><tr data-level="total">`.
    LOOP AT it_columns INTO ls_column.
      DATA(lv_colspan) = colspan( iv_index = sy-tabix
                                  iv_count = lines( it_columns )
                                  iv_width = iv_width ).
      IF lo_aggregations->is_aggregated( ls_column-columnname ) = abap_false.
        result = result && |<td{ lv_colspan }></td>|.
        CONTINUE.
      ENDIF.
      CLEAR: lv_total, lv_sample.
      LOOP AT <items> ASSIGNING <item>.
        ASSIGN COMPONENT ls_column-columnname OF STRUCTURE <item> TO <value>.
        IF sy-subrc = 0.
          IF lv_sample IS INITIAL.
            lv_sample = condense( CONV string( <value> ) ).
          ENDIF.
          lv_total = lv_total + <value>.
        ENDIF.
      ENDLOOP.
      DATA(lv_total_text) = format_total_value( iv_value  = lv_total
                                                iv_sample = lv_sample ).
      result = result && |<td class="gg-grid-cell gg-state-total gg-type-number" data-total="true" data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_column-columnname ) ) }"{ lv_colspan }>{ cl_gui_control=>escape_html( lv_total_text ) }</td>|.
    ENDLOOP.
    result = result && `</tr></tfoot>`.
  ENDMETHOD.

  METHOD format_total_value.
    DATA lv_integer TYPE string.
    DATA lv_fraction TYPE string.
    DATA lv_decimals TYPE i.
    DATA lv_factor TYPE decfloat34.
    DATA lv_scaled TYPE decfloat34.
    DATA lv_scaled_text TYPE string.
    DATA lv_sign TYPE string.
    DATA lv_integer_length TYPE i.
    DATA lv_integer_part TYPE string.
    DATA lv_fraction_part TYPE string.

    lv_decimals = iv_decimals.
    IF lv_decimals < 0.
      SPLIT iv_sample AT '.' INTO lv_integer lv_fraction.
      lv_decimals = strlen( lv_fraction ).
    ENDIF.
    IF lv_decimals > 14.
      lv_decimals = 14.
    ENDIF.
    lv_factor = 1.
    DO lv_decimals TIMES.
      lv_factor = lv_factor * 10.
    ENDDO.
    lv_scaled = round(
      val = iv_value * lv_factor
      dec = 0 ).
    lv_scaled_text = |{ lv_scaled }|.
    IF lv_scaled_text+0(1) = '-'.
      lv_sign = '-'.
      lv_scaled_text = substring(
        val = lv_scaled_text
        off = 1 ).
    ENDIF.
    WHILE strlen( lv_scaled_text ) <= lv_decimals.
      lv_scaled_text = |0{ lv_scaled_text }|.
    ENDWHILE.
    IF lv_decimals = 0.
      result = lv_sign && lv_scaled_text.
    ELSE.
      lv_integer_length = strlen( lv_scaled_text ) - lv_decimals.
      lv_integer_part = substring(
        val = lv_scaled_text
        off = 0
        len = lv_integer_length ).
      lv_fraction_part = substring(
        val = lv_scaled_text
        off = lv_integer_length ).
      result = |{ lv_sign }{ lv_integer_part }.{ lv_fraction_part }|.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
