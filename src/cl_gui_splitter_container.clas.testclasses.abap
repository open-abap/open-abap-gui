CLASS ltcl_splitter_container DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    METHODS exposes_grid_state FOR TESTING.
    METHODS honors_relative_sizing FOR TESTING.

ENDCLASS.

CLASS ltcl_splitter_container IMPLEMENTATION.

  METHOD exposes_grid_state.
    DATA lv_result TYPE i.
    DATA lv_height TYPE i.
    DATA lv_width TYPE i.
    DATA lo_cell TYPE REF TO cl_gui_container.
    DATA(lo_parent) = NEW cl_gui_custom_container( container_name = 'SPLITTER_PARENT' ).
    DATA(lo_splitter) = NEW cl_gui_splitter_container(
      parent  = lo_parent
      rows    = 2
      columns = 2 ).

    lo_cell = lo_splitter->get_container(
      row    = 1
      column = 1 ).
    cl_abap_unit_assert=>assert_bound( lo_cell ).
    lo_cell = lo_splitter->get_container(
      row    = 2
      column = 2 ).
    cl_abap_unit_assert=>assert_bound( lo_cell ).
    lo_splitter->set_row_height(
      EXPORTING
        id     = 1
        height = 40
      IMPORTING
        result = lv_result ).
    lo_splitter->get_row_height(
      EXPORTING
        id     = 1
      IMPORTING
        result = lv_height ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_result
      exp = 40 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_height
      exp = 40 ).
    lo_splitter->set_column_width(
      EXPORTING
        id     = 2
        width  = 60
      IMPORTING
        result = lv_result ).
    lo_splitter->get_column_width(
      EXPORTING
        id     = 2
      IMPORTING
        result = lv_width ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_result
      exp = 60 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_width
      exp = 60 ).
    lo_splitter->set_row_mode( mode = cl_gui_splitter_container=>mode_absolute ).
    lo_splitter->set_row_height(
      EXPORTING
        id     = 1
        height = 20
      IMPORTING
        result = lv_height ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_height
      exp = 24 ).
    lo_splitter->set_row_sash(
      EXPORTING
        id     = 1
        type   = cl_gui_splitter_container=>type_movable
        value  = cl_gui_splitter_container=>false
      IMPORTING
        result = lv_result ).
    lo_splitter->get_row_height(
      EXPORTING
        id     = 1
      IMPORTING
        result = lv_height ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_height
      exp = 24
      msg = 'sash flags do not change row height' ).
    lo_splitter->set_column_sash(
      EXPORTING
        id     = 2
        type   = cl_gui_splitter_container=>type_sashvisible
        value  = cl_gui_splitter_container=>false
      IMPORTING
        result = lv_result ).
    lo_splitter->get_column_width(
      EXPORTING
        id     = 2
      IMPORTING
        result = lv_width ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_width
      exp = 60
      msg = 'sash flags do not change column width' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( cl_gui_control=>render_html( ) CS 'rows=2; columns=2' ) ).
  ENDMETHOD.

  METHOD honors_relative_sizing.
    cl_gui_control=>clear( ).
    DATA(lo_host) = NEW cl_gui_custom_container( container_name = 'SPLITTER-SIZING' ).
    DATA(lo_splitter) = NEW cl_gui_splitter_container(
      parent  = lo_host
      rows    = 3
      columns = 2 ).

    lo_splitter->set_column_width(
      id    = 1
      width = 38 ).
    lo_splitter->set_row_height(
      id     = 1
      height = 8 ).
    lo_splitter->set_row_height(
      id     = 2
      height = 58 ).
    lo_splitter->set_row_height(
      id     = 3
      height = 34 ).

    DATA(lv_html) = cl_gui_control=>render_html( ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lv_html CS 'grid-template-columns:38% 62%' )
      msg = 'relative column width and remaining width' ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lv_html CS 'grid-template-rows:8% 58% 34%' )
      msg = 'relative row heights' ).
    cl_gui_control=>clear( ).
  ENDMETHOD.

ENDCLASS.
