CLASS cl_gui_chart_engine DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        parent TYPE REF TO cl_gui_container OPTIONAL
        name   TYPE string OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error
        create_error
        lifetime_error.

    METHODS set_data
      IMPORTING
        data  TYPE string OPTIONAL
        xdata TYPE xstring OPTIONAL
        size  TYPE i OPTIONAL.

    METHODS set_customizing
      IMPORTING
        data  TYPE string OPTIONAL
        xdata TYPE xstring OPTIONAL.

    METHODS render
      EXCEPTIONS
        cntl_error.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_series,
             label  TYPE string,
             values TYPE STANDARD TABLE OF decfloat34 WITH DEFAULT KEY,
           END OF ty_series.
    TYPES ty_series_table TYPE STANDARD TABLE OF ty_series WITH DEFAULT KEY.

    CONSTANTS c_width TYPE i VALUE 560.
    CONSTANTS c_height TYPE i VALUE 260.
    CONSTANTS c_margin TYPE i VALUE 40.

    DATA mv_data TYPE string.
    DATA mv_customizing TYPE string.
    DATA mt_categories TYPE string_table.
    DATA mt_series TYPE ty_series_table.
    DATA mv_maximum TYPE decfloat34.

    METHODS parse_data.

    METHODS elements
      IMPORTING
        xml           TYPE string
        tag           TYPE string
      RETURNING
        VALUE(result) TYPE string_table.

    METHODS setting
      IMPORTING
        tag           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS color
      IMPORTING
        index         TYPE i
      RETURNING
        VALUE(result) TYPE string.

    METHODS svg_columns
      IMPORTING
        horizontal    TYPE abap_bool
      RETURNING
        VALUE(result) TYPE string.

    METHODS svg_lines
      RETURNING
        VALUE(result) TYPE string.

    METHODS data_table
      IMPORTING
        title         TYPE string
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.

CLASS cl_gui_chart_engine IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'CHART_ENGINE' ).
    IF parent IS BOUND.
      parent->add_child( me ).
    ENDIF.
  ENDMETHOD.

  METHOD set_data.
    IF data IS SUPPLIED.
      mv_data = data.
    ELSEIF xdata IS SUPPLIED.
      mv_data = cl_abap_codepage=>convert_from( xdata ).
    ENDIF.
  ENDMETHOD.

  METHOD set_customizing.
    IF data IS SUPPLIED.
      mv_customizing = data.
    ELSEIF xdata IS SUPPLIED.
      mv_customizing = cl_abap_codepage=>convert_from( xdata ).
    ENDIF.
  ENDMETHOD.

  METHOD elements.
* The text of every <tag>...</tag> in XML, in document order, with the
* predefined entities resolved.
    DATA lt_parts TYPE string_table.
    DATA lv_value TYPE string.
    DATA lv_rest TYPE string.

    SPLIT xml AT |<{ tag }>| INTO TABLE lt_parts.
    LOOP AT lt_parts INTO DATA(lv_part) FROM 2.
      SPLIT lv_part AT |</{ tag }>| INTO lv_value lv_rest.
      REPLACE ALL OCCURRENCES OF '&lt;' IN lv_value WITH '<'.
      REPLACE ALL OCCURRENCES OF '&gt;' IN lv_value WITH '>'.
      REPLACE ALL OCCURRENCES OF '&quot;' IN lv_value WITH '"'.
      REPLACE ALL OCCURRENCES OF '&apos;' IN lv_value WITH ''''.
      REPLACE ALL OCCURRENCES OF '&amp;' IN lv_value WITH '&'.
      APPEND lv_value TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD setting.
    READ TABLE elements( xml = mv_customizing
                         tag = tag ) INTO result INDEX 1.
  ENDMETHOD.

  METHOD parse_data.
* SimpleChartData: <Categories><C>..</C></Categories> and one
* <Series label=".."><S>..</S></Series> per data series.
    DATA lt_series TYPE string_table.
    DATA ls_series TYPE ty_series.
    DATA lv_label TYPE string.
    DATA lv_rest TYPE string.
    DATA lv_value TYPE decfloat34.

    CLEAR: mt_categories, mt_series, mv_maximum.
    mt_categories = elements( xml = mv_data
                              tag = 'C' ).
    SPLIT mv_data AT '<Series' INTO TABLE lt_series.
    LOOP AT lt_series INTO DATA(lv_chunk) FROM 2.
      CLEAR: ls_series, lv_label.
      SPLIT lv_chunk AT 'label="' INTO lv_rest lv_label.
      SPLIT lv_label AT '"' INTO ls_series-label lv_rest.
      LOOP AT elements( xml = lv_chunk
                        tag = 'S' ) INTO DATA(lv_text).
        TRY.
            lv_value = lv_text.
          CATCH cx_root.
            CLEAR lv_value.
        ENDTRY.
        APPEND lv_value TO ls_series-values.
        mv_maximum = nmax( val1 = mv_maximum
                           val2 = lv_value ).
      ENDLOOP.
      APPEND ls_series TO mt_series.
    ENDLOOP.
    IF mv_maximum <= 0.
      mv_maximum = 1.
    ENDIF.
  ENDMETHOD.

  METHOD color.
    DATA(lt_colors) = VALUE string_table( ( `#2668a3` ) ( `#e07b24` ) ( `#3f9b49` ) ( `#b03a48` ) ( `#7a5aa6` ) ).
    result = lt_colors[ ( index - 1 ) MOD lines( lt_colors ) + 1 ].
  ENDMETHOD.

  METHOD svg_columns.
    DATA lv_x TYPE i.
    DATA lv_y TYPE i.
    DATA lv_length TYPE i.

    DATA(lv_series_count) = nmax( val1 = lines( mt_series )
                                  val2 = 1 ).
    DATA(lv_category_count) = nmax( val1 = lines( mt_categories )
                                    val2 = 1 ).
    DATA(lv_extent) = COND i( WHEN horizontal = abap_true THEN c_height - 2 * c_margin ELSE c_width - 2 * c_margin ).
    DATA(lv_scale) = COND i( WHEN horizontal = abap_true THEN c_width - 3 * c_margin ELSE c_height - 2 * c_margin ).
    DATA(lv_slot) = lv_extent DIV lv_category_count.
    DATA(lv_bar) = nmax( val1 = ( lv_slot - 8 ) DIV lv_series_count
                         val2 = 2 ).
    LOOP AT mt_categories INTO DATA(lv_category).
      DATA(lv_category_index) = sy-tabix.
      LOOP AT mt_series INTO DATA(ls_series).
        DATA(lv_series_index) = sy-tabix.
        READ TABLE ls_series-values INTO DATA(lv_value) INDEX lv_category_index.
        lv_length = lv_value * lv_scale / mv_maximum.
        DATA(lv_offset) = ( lv_category_index - 1 ) * lv_slot + 4 + ( lv_series_index - 1 ) * lv_bar.
        IF horizontal = abap_true.
          lv_x = 2 * c_margin.
          lv_y = c_margin + lv_offset.
          result = result && |<rect x="{ lv_x }" y="{ lv_y }" width="{ lv_length }" height="{ lv_bar }" fill="{ color( lv_series_index ) }"><title>{ escape_html( lv_category ) }: { lv_value }</title></rect>|.
        ELSE.
          lv_x = c_margin + lv_offset.
          lv_y = c_height - c_margin - lv_length.
          result = result && |<rect x="{ lv_x }" y="{ lv_y }" width="{ lv_bar }" height="{ lv_length }" fill="{ color( lv_series_index ) }"><title>{ escape_html( lv_category ) }: { lv_value }</title></rect>|.
        ENDIF.
      ENDLOOP.
      IF horizontal = abap_true.
        lv_y = c_margin + ( lv_category_index - 1 ) * lv_slot + lv_slot DIV 2 + 4.
        result = result && |<text x="{ 2 * c_margin - 6 }" y="{ lv_y }" text-anchor="end">{ escape_html( lv_category ) }</text>|.
      ELSE.
        lv_x = c_margin + ( lv_category_index - 1 ) * lv_slot + lv_slot DIV 2.
        result = result && |<text x="{ lv_x }" y="{ c_height - c_margin + 16 }" text-anchor="middle">{ escape_html( lv_category ) }</text>|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD svg_lines.
    DATA lv_points TYPE string.

    DATA(lv_category_count) = nmax( val1 = lines( mt_categories ) - 1
                                    val2 = 1 ).
    DATA(lv_step) = ( c_width - 2 * c_margin ) DIV lv_category_count.
    LOOP AT mt_series INTO DATA(ls_series).
      DATA(lv_series_index) = sy-tabix.
      CLEAR lv_points.
      LOOP AT ls_series-values INTO DATA(lv_value).
        DATA(lv_x) = c_margin + ( sy-tabix - 1 ) * lv_step.
        DATA(lv_y) = CONV i( c_height - c_margin - lv_value * ( c_height - 2 * c_margin ) / mv_maximum ).
        lv_points = |{ lv_points } { lv_x },{ lv_y }|.
        result = result && |<circle cx="{ lv_x }" cy="{ lv_y }" r="3" fill="{ color( lv_series_index ) }"><title>{ lv_value }</title></circle>|.
      ENDLOOP.
      result = result && |<polyline points="{ condense( lv_points ) }" fill="none" stroke="{ color( lv_series_index ) }" stroke-width="2"/>|.
    ENDLOOP.
    LOOP AT mt_categories INTO DATA(lv_category).
      lv_x = c_margin + ( sy-tabix - 1 ) * lv_step.
      result = result && |<text x="{ lv_x }" y="{ c_height - c_margin + 16 }" text-anchor="middle">{ escape_html( lv_category ) }</text>|.
    ENDLOOP.
  ENDMETHOD.

  METHOD data_table.
    result = |<table class="gg-chart-data"><caption>{ escape_html( title ) }</caption><thead><tr><th scope="col"></th>|.
    LOOP AT mt_series INTO DATA(ls_series).
      result = result && |<th scope="col">{ escape_html( ls_series-label ) }</th>|.
    ENDLOOP.
    result = result && '</tr></thead><tbody>'.
    LOOP AT mt_categories INTO DATA(lv_category).
      DATA(lv_index) = sy-tabix.
      result = result && |<tr><th scope="row">{ escape_html( lv_category ) }</th>|.
      LOOP AT mt_series INTO ls_series.
        READ TABLE ls_series-values INTO DATA(lv_value) INDEX lv_index.
        result = result && |<td>{ lv_value }</td>|.
      ENDLOOP.
      result = result && '</tr>'.
    ENDLOOP.
    result = result && '</tbody></table>'.
  ENDMETHOD.

  METHOD render.
* The chart is drawn as SVG from the data and the customizing (chart type
* Columns, Bars or Lines, and the title); the values follow as a table.
    DATA lv_legend TYPE string.

    parse_data( ).
    DATA(lv_type) = setting( 'ChartType' ).
    DATA(lv_title) = setting( 'Caption' ).
    DATA(lv_body) = SWITCH string( lv_type
      WHEN 'Lines' OR 'Line' THEN svg_lines( )
      WHEN 'Bars' OR 'StackedBars' THEN svg_columns( abap_true )
      ELSE svg_columns( abap_false ) ).
    LOOP AT mt_series INTO DATA(ls_series).
      lv_legend = lv_legend && |<li><span class="gg-chart-swatch" style="background:{ color( sy-tabix ) }"></span>{ escape_html( ls_series-label ) }</li>|.
    ENDLOOP.
    cl_gui_control=>set_html(
      control = me
      html    = |<figure class="gg-chart" data-chart-type="{ escape_html( COND string( WHEN lv_type IS INITIAL THEN 'Columns' ELSE lv_type ) ) }">| &&
                |{ COND string( WHEN lv_title IS NOT INITIAL THEN |<figcaption>{ escape_html( lv_title ) }</figcaption>| ) }| &&
                |<svg role="img" aria-label="{ escape_html( COND string( WHEN lv_title IS INITIAL THEN 'Chart' ELSE lv_title ) ) }" viewBox="0 0 { c_width } { c_height }" | &&
                |width="{ c_width }" height="{ c_height }"><line x1="{ c_margin }" y1="{ c_height - c_margin }" x2="{ c_width - c_margin }" y2="{ c_height - c_margin }" stroke="#8daac4"/>| &&
                |{ lv_body }</svg><ul class="gg-chart-legend">{ lv_legend }</ul>{ data_table( lv_title ) }</figure>| ).
  ENDMETHOD.

ENDCLASS.
