CLASS ltcl_splitter_container DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT FINAL.

  PRIVATE SECTION.
    METHODS exposes_grid_state FOR TESTING.

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
    lo_splitter->set_row_minimum(
      EXPORTING
        id      = 1
        minimum = 50
      IMPORTING
        result  = lv_result ).
    lo_splitter->set_row_height(
      EXPORTING
        id     = 1
        height = 20
      IMPORTING
        result = lv_height ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_result
      exp = 50 ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_height
      exp = 50 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( cl_gui_control=>render_html( ) CS 'rows=2; columns=2' ) ).
  ENDMETHOD.

ENDCLASS.
