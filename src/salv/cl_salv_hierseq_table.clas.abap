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

    METHODS render_level
      IMPORTING
        ir_table     TYPE REF TO data
        iv_level     TYPE i
      RETURNING
        VALUE(value) TYPE string.

    METHODS is_total_component
      IMPORTING
        iv_name         TYPE string
      RETURNING
        VALUE(rv_total) TYPE abap_bool.

    METHODS heading_for_column
      IMPORTING
        iv_name           TYPE string
      RETURNING
        VALUE(rv_heading) TYPE string.

    METHODS render_total_row
      IMPORTING
        ir_table        TYPE REF TO data
        io_struct_descr TYPE REF TO cl_abap_structdescr
      RETURNING
        VALUE(value)    TYPE string.

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
    GET REFERENCE OF t_table_level1 INTO DATA(lr_level1).
    GET REFERENCE OF t_table_level2 INTO DATA(lr_level2).
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
    DATA lv_level1_html TYPE string.
    DATA lv_level2_html TYPE string.
    DATA lv_master_name TYPE string.
    DATA lv_slave_name TYPE string.
    READ TABLE mt_binding INTO DATA(ls_binding) INDEX 1.
    IF sy-subrc = 0.
      lv_master_name = ls_binding-master.
      lv_slave_name = ls_binding-slave.
    ENDIF.
    lv_level1_html = render_level(
      ir_table = mr_table_level1
      iv_level = 1 ).
    lv_level2_html = render_level(
      ir_table = mr_table_level2
      iv_level = 2 ).
    cl_gui_control=>set_external_html(
      |<section class="gg-salv-hierseq" aria-label="Hierarchical sequential SALV" data-binding-master="{ cl_gui_control=>escape_html( lv_master_name ) }" data-binding-slave="{ cl_gui_control=>escape_html( lv_slave_name ) }"><div class="gg-salv-hierseq-scroll">{ lv_level1_html }{ lv_level2_html }</div></section>| ).
  ENDMETHOD.

  METHOD refresh.
    display( ).
  ENDMETHOD.

  METHOD render_level.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <component> TYPE any.
    DATA lo_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lo_line_descr TYPE REF TO cl_abap_datadescr.
    DATA lo_columns TYPE REF TO cl_salv_columns_hierseq.
    DATA lv_key_name TYPE string.
    DATA lv_key_value TYPE string.
    IF ir_table IS NOT BOUND.
      RETURN.
    ENDIF.
    ASSIGN ir_table->* TO <table>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( ir_table->* ).
    lo_line_descr = lo_table_descr->get_table_line_type( ).
    IF iv_level = 1.
      lo_columns = mo_level1->get_columns( ).
    ELSE.
      lo_columns = mo_level2->get_columns( ).
    ENDIF.
    READ TABLE mt_binding INTO DATA(ls_binding) INDEX 1.
    IF sy-subrc = 0.
      lv_key_name = COND string( WHEN iv_level = 1 THEN ls_binding-master ELSE ls_binding-slave ).
    ENDIF.
    value = |<section class="gg-salv-hierseq-level" aria-label="SALV hierarchy level { iv_level }" data-level="{ iv_level }"><h3>{ COND string( WHEN iv_level = 1 THEN 'Header level' ELSE 'Item level' ) }</h3><table><caption>{ COND string( WHEN iv_level = 1 THEN 'Header records' ELSE 'Item records grouped by binding' ) }</caption><thead><tr>|.
    IF lo_line_descr->kind = cl_abap_typedescr=>kind_struct.
      DATA(lo_struct_descr) = CAST cl_abap_structdescr( lo_line_descr ).
      LOOP AT lo_columns->get( ) INTO DATA(ls_column_ref).
        IF ls_column_ref-r_column->is_technical( ) = abap_true.
          CONTINUE.
        ENDIF.
        DATA(lv_heading) = ls_column_ref-r_column->get_long_text( ).
        IF lv_heading IS INITIAL.
          lv_heading = heading_for_column( CONV string( ls_column_ref-columnname ) ).
        ENDIF.
        value = value && |<th scope="col">{ cl_gui_control=>escape_html( lv_heading ) }</th>|.
      ENDLOOP.
      value = value && '</tr></thead><tbody>'.
      LOOP AT <table> ASSIGNING <row>.
        CLEAR lv_key_value.
        IF lv_key_name IS NOT INITIAL.
          ASSIGN COMPONENT lv_key_name OF STRUCTURE <row> TO <component>.
          IF sy-subrc = 0.
            lv_key_value = CONV string( <component> ).
            CONDENSE lv_key_value.
          ENDIF.
        ENDIF.
        value = value && |<tr data-level="{ iv_level }"{ COND string( WHEN iv_level = 1 THEN | data-group-key="{ cl_gui_control=>escape_html( lv_key_value ) }"| ELSE | data-parent-key="{ cl_gui_control=>escape_html( lv_key_value ) }"| ) }>|.
        LOOP AT lo_columns->get( ) INTO ls_column_ref.
          IF ls_column_ref-r_column->is_technical( ) = abap_true.
            CONTINUE.
          ENDIF.
          ASSIGN COMPONENT ls_column_ref-columnname OF STRUCTURE <row> TO <component>.
          IF sy-subrc = 0.
            value = value && |<td data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_column_ref-columnname ) ) }">{ cl_gui_control=>escape_html( CONV string( <component> ) ) }</td>|.
          ENDIF.
        ENDLOOP.
        value = value && '</tr>'.
      ENDLOOP.
      value = value && render_total_row(
        ir_table        = ir_table
        io_struct_descr = lo_struct_descr ).
    ELSE.
      value = value && '<th scope="col">VALUE</th></tr></thead><tbody>'.
      LOOP AT <table> ASSIGNING <row>.
        value = value && |<tr><td>{ cl_gui_control=>escape_html( CONV string( <row> ) ) }</td></tr>|.
      ENDLOOP.
    ENDIF.
    value = value && '</tbody></table></section>'.
  ENDMETHOD.

  METHOD is_total_component.
    DATA lv_name TYPE string.
    lv_name = iv_name.
    TRANSLATE lv_name TO UPPER CASE.
    rv_total = xsdbool( lv_name CS 'PRICE'
                        OR lv_name CS 'AMOUNT'
                        OR lv_name CS 'TOTAL'
                        OR lv_name CS 'QUANTITY'
                        OR lv_name CS 'QTY'
                        OR lv_name CS 'SEATS' ).
  ENDMETHOD.

  METHOD heading_for_column.
    rv_heading = iv_name.
    REPLACE ALL OCCURRENCES OF '_' IN rv_heading WITH ` `.
    TRANSLATE rv_heading TO LOWER CASE.
  ENDMETHOD.

  METHOD render_total_row.
    FIELD-SYMBOLS <table> TYPE ANY TABLE.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <component> TYPE any.
    DATA lv_has_total TYPE abap_bool.
    DATA lv_total TYPE decfloat34.
    DATA lv_total_text TYPE string.
    DATA lv_total_sample TYPE string.
    DATA lo_columns TYPE REF TO cl_salv_columns_hierseq.

    IF io_struct_descr IS INITIAL.
      RETURN.
    ENDIF.

    ASSIGN ir_table->* TO <table>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT io_struct_descr->get_components( ) INTO DATA(ls_component).
      IF is_total_component( CONV string( ls_component-name ) ) = abap_true.
        lv_has_total = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF lv_has_total = abap_false.
      RETURN.
    ENDIF.
    IF ir_table = mr_table_level1.
      lo_columns = mo_level1->get_columns( ).
    ELSE.
      lo_columns = mo_level2->get_columns( ).
    ENDIF.
    value = '<tfoot><tr class="gg-salv-hierseq-total"><th scope="row">Total</th>'.
    LOOP AT io_struct_descr->get_components( ) INTO ls_component.
      TRY.
          IF lo_columns->get_column( CONV lvc_fname( ls_component-name ) )->is_technical( ) = abap_true.
            CONTINUE.
          ENDIF.
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
      CLEAR: lv_total, lv_total_text, lv_total_sample.
      IF is_total_component( CONV string( ls_component-name ) ) = abap_true.
        LOOP AT <table> ASSIGNING <row>.
          ASSIGN COMPONENT ls_component-name OF STRUCTURE <row> TO <component>.
          IF sy-subrc = 0.
            IF lv_total_sample IS INITIAL.
              lv_total_sample = CONV string( <component> ).
            ENDIF.
            TRY.
                lv_total = lv_total + CONV decfloat34( <component> ).
              CATCH cx_root.
                CONTINUE.
            ENDTRY.
          ENDIF.
        ENDLOOP.
        lv_total_text = format_total_value(
          iv_value  = lv_total
          iv_sample = lv_total_sample ).
      ELSE.
        lv_total_text = '-'.
      ENDIF.
      value = value && |<td data-total="true" data-fieldname="{ cl_gui_control=>escape_html( CONV string( ls_component-name ) ) }">{ cl_gui_control=>escape_html( lv_total_text ) }</td>|.
    ENDLOOP.
    value = value && '</tr></tfoot>'.
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
