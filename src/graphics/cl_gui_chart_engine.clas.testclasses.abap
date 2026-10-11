CLASS ltcl_chart_regressions DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS stacked_columns FOR TESTING.
    METHODS pie_and_colors FOR TESTING.
    METHODS depth FOR TESTING.
    METHODS teardown.
ENDCLASS.

CLASS cl_gui_chart_engine DEFINITION LOCAL FRIENDS ltcl_chart_regressions.

CLASS ltcl_chart_regressions IMPLEMENTATION.
  METHOD teardown.
    zcl_gg_gui_runtime=>clear( ).
  ENDMETHOD.

  METHOD stacked_columns.
    DATA(lo_chart) = NEW cl_gui_chart_engine( ).
    lo_chart->set_data( data = '<Categories><C>One</C><C>Two</C></Categories><Series label="A"><S>3</S><S>2</S></Series><Series label="B"><S>4</S><S>1</S></Series>' ).
    lo_chart->set_customizing( data = '<ChartType>StackedColumns</ChartType>' ).
    lo_chart->render( ).
    cl_abap_unit_assert=>assert_equals( act = lo_chart->mv_maximum
                                        exp = 7 ).
    DATA(lv_html) = zcl_gg_gui_runtime=>render_html( ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_html CS 'y="40"' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_html CS 'data-chart-type="StackedColumns"' ) ).
  ENDMETHOD.

  METHOD pie_and_colors.
    DATA(lo_chart) = NEW cl_gui_chart_engine( ).
    lo_chart->set_data( data = '<Categories><C>One</C><C>Two</C></Categories><Series label="A"><S>3</S><S>2</S></Series>' ).
    lo_chart->set_customizing( data = '<ChartType>Pie</ChartType><Color>#123abc</Color><Color>#456def</Color>' ).
    lo_chart->render( ).
    DATA(lv_html) = zcl_gg_gui_runtime=>render_html( ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_html CS '<path d="M 280 130' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_html CS 'fill="#123abc"' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_html CS 'fill="#456def"' ) ).
    lo_chart->set_customizing( data = '<Color>red&quot; onclick=&quot;bad</Color>' ).
    cl_abap_unit_assert=>assert_equals( act = lo_chart->color( 1 )
                                        exp = '#2668a3' ).
  ENDMETHOD.

  METHOD depth.
    DATA(lo_chart) = NEW cl_gui_chart_engine( ).
    lo_chart->set_data( data = '<Categories><C>One</C></Categories><Series label="A"><S>3</S></Series>' ).
    lo_chart->set_customizing( data = '<ChartType>Columns</ChartType><Dimension>Three</Dimension>' ).
    lo_chart->render( ).
    cl_abap_unit_assert=>assert_true( xsdbool( zcl_gg_gui_runtime=>render_html( ) CS 'data-chart-depth="true"' ) ).
  ENDMETHOD.
ENDCLASS.
