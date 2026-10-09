CLASS ltcl_salv_table_support DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS renders_structured_rows FOR TESTING.
    METHODS keeps_selection_and_functions FOR TESTING.
    METHODS filtered_selection_keeps_index FOR TESTING RAISING cx_salv_not_found cx_salv_data_error cx_salv_existing.
    METHODS form_layout_features FOR TESTING.
    METHODS applies_filter_and_sort_state FOR TESTING
      RAISING
        cx_salv_data_error
        cx_salv_existing
        cx_salv_not_found.
    METHODS hides_technical_columns FOR TESTING
      RAISING
        cx_salv_not_found.
    METHODS column_is_column_table FOR TESTING
      RAISING
        cx_salv_not_found.
    METHODS renders_as_alv_grid FOR TESTING
      RAISING
        cx_salv_not_found.
    METHODS toolbar_follows_functions FOR TESTING
      RAISING
        cx_salv_not_found
        cx_salv_wrong_call.
    METHODS set_all_defaults_to_true FOR TESTING.
    METHODS set_all_false_hides_toolbar FOR TESTING.
    METHODS set_all_keeps_later_settings FOR TESTING
      RAISING
        cx_salv_not_found
        cx_salv_wrong_call.
    METHODS added_function_on_empty_grid FOR TESTING.
    METHODS shows_rows_added_after_factory FOR TESTING.
    METHODS displays_in_its_container FOR TESTING.
    METHODS teardown.
    METHODS on_added_function FOR EVENT added_function OF cl_salv_events_table
      IMPORTING
        e_salv_function.
    DATA mv_function TYPE salv_de_function.
ENDCLASS.

CLASS cl_salv_table DEFINITION LOCAL FRIENDS ltcl_salv_table_support.

CLASS ltcl_salv_table_support IMPLEMENTATION.
  METHOD filtered_selection_keeps_index.
    TYPES: BEGIN OF ty_row,
             name TYPE string,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.
    lt_rows = VALUE #( ( name = 'Hide' ) ( name = 'Keep' ) ( name = 'Keep' ) ).
    cl_salv_table=>factory( IMPORTING r_salv_table = lo_salv CHANGING t_table = lt_rows ).
    lo_salv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>multiple ).
    lo_salv->get_selections( )->set_selected_rows( VALUE #( ( 3 ) ) ).
    lo_salv->get_filters( )->add_filter( columnname = 'NAME'
                                         sign       = 'I'
                                         option     = 'EQ'
                                         low        = 'Keep' ).
    lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_equals( act = lo_salv->get_selections( )->get_selected_rows( )
      exp                                   = VALUE salv_t_row( ( 3 ) ) ).

    lo_salv->get_selections( )->set_selected_rows( VALUE #( ( 2 ) ) ).
    lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_equals( act = lo_salv->get_selections( )->get_selected_rows( )
      exp                                   = VALUE salv_t_row( ( 2 ) ) ).
  ENDMETHOD.


  METHOD form_layout_features.
    DATA lt_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.
    cl_salv_table=>factory( IMPORTING r_salv_table = lo_salv CHANGING t_table = lt_rows ).
    DATA(lo_form) = NEW cl_salv_form_layout_grid( ).
    lo_form->create_label( row     = 1
                           column  = 1
                           rowspan = 2
                           text    = 'Amount' ).
    DATA(lo_text) = lo_form->create_text( row    = 1
                                          column = 2
                                          text   = '42' ).
    lo_form->set_column_label_for( label_column = 1
                                   text_column  = 2 ).
    DATA(lo_layout) = NEW cl_salv_form_layout_data_grid( ).
    lo_layout->set_h_align( 3 ).
    lo_text->set_layout_data( lo_layout ).
    lo_salv->set_top_of_list( lo_form ).
    DATA(lv_html) = lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_html CS 'rowspan="2"' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_html CS 'text-align:right' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_html CS 'aria-labelledby=' ) ).
  ENDMETHOD.

  METHOD renders_structured_rows.
    TYPES: BEGIN OF ty_row,
             carrier TYPE c LENGTH 3,
             seats   TYPE i,
             note    TYPE string,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.
    DATA lo_column TYPE REF TO cl_salv_column.

    APPEND VALUE #( carrier = 'LH' seats = 12 note = '<ready>' ) TO lt_rows.
    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    lo_salv->set_list_header( 'Flights & seats' ).
    lo_salv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>single ).
    lo_salv->get_selections( )->set_selected_rows( VALUE #( ( 1 ) ) ).
    TRY.
        lo_column = lo_salv->get_columns( )->get_column( 'CARRIER' ).
        lo_column->set_short_text( 'Carrier' ).
      CATCH cx_salv_not_found.
        cl_abap_unit_assert=>fail( 'SALV metadata did not expose CARRIER' ).
    ENDTRY.

    DATA(lv_html) = lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Flights &amp; seats' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'CARRIER' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '12' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '&lt;ready&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS ':row:1' ) ).
    DATA(lv_xml) = lo_salv->to_xml( xml_type = 1 ).
    cl_abap_unit_assert=>assert_not_initial( lv_xml ).
  ENDMETHOD.

  METHOD keeps_selection_and_functions.
    DATA lt_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.
    DATA lt_selected TYPE salv_t_row.

    APPEND 7 TO lt_rows.
    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    APPEND 1 TO lt_selected.
    lo_salv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>single ).
    lo_salv->get_selections( )->set_selected_rows( lt_selected ).
    lo_salv->get_functions( )->add_function(
      name     = 'LOCAL'
      text     = 'Local action'
      tooltip  = 'Local action'
      position = 1 ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_salv->get_selections( )->get_selected_rows( )
      exp = lt_selected ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_salv->get_selections( )->get_selection_mode( )
      exp = if_salv_c_selection_mode=>single ).
    DATA(lt_functions) = lo_salv->get_functions( )->get_functions( ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_functions )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_functions[ 1 ]-r_function->get_name( )
      exp = 'LOCAL' ).
  ENDMETHOD.

  METHOD applies_filter_and_sort_state.
    TYPES: BEGIN OF ty_row,
             carrier TYPE c LENGTH 3,
             seats   TYPE i,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.

    lt_rows = VALUE #( ( carrier = 'LH' seats = 180 )
                       ( carrier = 'UA' seats = 210 ) ).
    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    lo_salv->get_filters( )->add_filter(
      columnname = 'CARRIER'
      option     = 'EQ'
      low        = 'LH' ).
    DATA(lo_sort) = lo_salv->get_sorts( )->add_sort(
      columnname = 'SEATS'
      sequence   = 1
      subtotal   = abap_true ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( lo_salv->get_filters( )->get( ) )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( lo_salv->get_sorts( )->get( ) )
      exp = 1 ).
    cl_abap_unit_assert=>assert_true( act = lo_sort->is_subtotalled( ) ).
    DATA(lv_html) = lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'UA' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'LH' ) ).
    lo_salv->get_filters( )->clear( ).
    lo_salv->get_sorts( )->clear( ).
    cl_abap_unit_assert=>assert_initial( lo_salv->get_filters( )->get( ) ).
    cl_abap_unit_assert=>assert_initial( lo_salv->get_sorts( )->get( ) ).
  ENDMETHOD.

  METHOD hides_technical_columns.
    TYPES: BEGIN OF ty_row,
             id           TYPE i,
             name         TYPE string,
             exception    TYPE i,
             technical    TYPE string,
             cell_colors  TYPE string,
             cell_types   TYPE string,
             link_handles TYPE string,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.

    lt_rows = VALUE #( ( id = 1 name = 'visible' exception = 3 technical = 'TECH'
                         cell_colors = 'COLORS' cell_types = 'TYPES' link_handles = 'LINK' ) ).
    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    lo_salv->get_columns( )->set_exception_column( 'EXCEPTION' ).
    lo_salv->get_columns( )->set_color_column( 'CELL_COLORS' ).
    lo_salv->get_columns( )->set_cell_type_column( 'CELL_TYPES' ).
    lo_salv->get_columns( )->set_hyperlink_entry_column( 'LINK_HANDLES' ).
    lo_salv->get_columns( )->get_column( 'TECHNICAL' )->set_technical( abap_true ).

    DATA(lv_html) = lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-fieldname="ID"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-fieldname="NAME"' ) ).
* The exception column is shown, as traffic lights.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-light="3"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'data-fieldname="TECHNICAL"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'data-fieldname="CELL_COLORS"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'data-fieldname="CELL_TYPES"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'data-fieldname="LINK_HANDLES"' ) ).
  ENDMETHOD.

  METHOD column_is_column_table.
    TYPES: BEGIN OF ty_row,
             traffic_light TYPE c LENGTH 4,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.
    DATA lo_column TYPE REF TO cl_salv_column_table.

    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    lo_column ?= lo_salv->get_columns( )->get_column( 'TRAFFIC_LIGHT' ).
    lo_column->set_icon( abap_true ).
    cl_abap_unit_assert=>assert_true( act = lo_column->is_icon( ) ).
  ENDMETHOD.

  METHOD teardown.
    zcl_gg_gui_runtime=>clear( ).
  ENDMETHOD.

  METHOD renders_as_alv_grid.
    TYPES: BEGIN OF ty_row,
             light  TYPE c LENGTH 4,
             object TYPE c LENGTH 20,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.
    DATA lo_column TYPE REF TO cl_salv_column_table.

    lt_rows = VALUE #( ( light = '@08@' object = 'BUS2032' ) ).
    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    lo_column ?= lo_salv->get_columns( )->get_column( 'LIGHT' ).
    lo_column->set_icon( abap_true ).
    lo_column->set_short_text( 'Status' ).
    lo_salv->get_columns( )->get_column( 'OBJECT' )->set_long_text( 'Business object' ).
    lo_salv->get_display_settings( )->set_list_header( 'Event status' ).

    DATA(lv_html) = lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="gg-alv"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label="Event status"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>Status</th>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>Business object</th>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label="Green light"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>BUS2032<' ) ).
* Without enabled functions or a selection mode there is no toolbar and no
* row selector.
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'gg-alv-toolbar' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS ':row:1' ) ).
  ENDMETHOD.

  METHOD toolbar_follows_functions.
    DATA lt_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.

    APPEND 1 TO lt_rows.
    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    lo_salv->get_functions( )->set_all( abap_true ).
    lo_salv->get_functions( )->set_sort_desc( abap_false ).
    lo_salv->get_functions( )->add_function(
      name     = 'ZRESET'
      text     = 'Reset'
      tooltip  = 'Restore rows'
      position = 1 ).

    DATA(lv_html) = lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label="ALV toolbar"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '|&amp;SORT_ASC"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '|&amp;SORT_DSC"' ) ).
* SALV output is read-only, so the grid's editing functions never appear.
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '|&amp;LOCAL&amp;APPEND"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '|ZRESET"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>Reset</button>' ) ).
  ENDMETHOD.

  METHOD on_added_function.
    mv_function = e_salv_function.
  ENDMETHOD.

  METHOD set_all_defaults_to_true.
    DATA lt_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.

    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    lo_salv->get_functions( )->add_function(
      name     = 'REFRESH'
      text     = 'Refresh'
      tooltip  = 'Refresh'
      position = 1 ).
* SET_ALL without a flag enables everything, as its DEFAULT is true.
    lo_salv->get_functions( )->set_all( ).

    DATA(lv_html) = lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label="ALV toolbar"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '|&amp;SORT_ASC"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '|REFRESH"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>Refresh</button>' ) ).
  ENDMETHOD.

  METHOD set_all_false_hides_toolbar.
    DATA lt_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.

    APPEND 1 TO lt_rows.
    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    lo_salv->get_functions( )->add_function(
      name     = 'REFRESH'
      text     = 'Refresh'
      tooltip  = 'Refresh'
      position = 1 ).
    lo_salv->get_functions( )->set_all( abap_false ).

    DATA(lv_html) = lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'gg-alv-toolbar' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '|REFRESH"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '|&amp;SORT_ASC"' ) ).
  ENDMETHOD.

  METHOD set_all_keeps_later_settings.
    DATA lt_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.

    APPEND 1 TO lt_rows.
    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    lo_salv->get_functions( )->add_function(
      name     = 'REFRESH'
      text     = 'Refresh'
      tooltip  = 'Refresh'
      position = 1 ).
    lo_salv->get_functions( )->add_function(
      name     = 'ZHIDDEN'
      text     = 'Hidden'
      tooltip  = 'Hidden'
      position = 2 ).
    lo_salv->get_functions( )->set_all( ).
    lo_salv->get_functions( )->set_sort_desc( abap_false ).
    lo_salv->get_functions( )->set_function( name    = 'ZHIDDEN'
                                             boolean = abap_false ).

    DATA(lv_html) = lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '|&amp;SORT_ASC"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '|&amp;SORT_DSC"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '|REFRESH"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '|ZHIDDEN"' ) ).
  ENDMETHOD.

  METHOD added_function_on_empty_grid.
    DATA lt_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.

    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'CC_MAIN' ).
    cl_salv_table=>factory(
      EXPORTING
        r_container  = lo_container
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    lo_salv->get_functions( )->add_function(
      name     = 'REFRESH'
      text     = 'Refresh'
      tooltip  = 'Refresh'
      position = 1 ).
    lo_salv->get_functions( )->set_all( ).
    SET HANDLER on_added_function FOR lo_salv->get_event( ).
    lo_salv->display( ).

* The toolbar shows above the grid even without rows.
    DATA(lv_html) = zcl_gg_gui_runtime=>render_html(
      iv_document       = abap_false
      iv_container_name = 'CC_MAIN' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-label="ALV toolbar"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '|FUNCTION|&amp;SORT_ASC"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '|FUNCTION|REFRESH"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>Refresh</button>' ) ).

    CLEAR mv_function.
    lo_salv->mo_grid->set_user_command( 'REFRESH' ).
    cl_abap_unit_assert=>assert_equals( act = mv_function
                                        exp = 'REFRESH' ).
  ENDMETHOD.

  METHOD shows_rows_added_after_factory.
    TYPES: BEGIN OF ty_row,
             name TYPE c LENGTH 10,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.

    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    APPEND VALUE #( name = 'LATE' ) TO lt_rows.

    DATA(lv_html) = lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>LATE<' ) ).
  ENDMETHOD.

  METHOD displays_in_its_container.
    DATA lt_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA lo_salv TYPE REF TO cl_salv_table.

    APPEND 42 TO lt_rows.
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'CC_MAIN' ).
    cl_salv_table=>factory(
      EXPORTING
        r_container  = lo_container
      IMPORTING
        r_salv_table = lo_salv
      CHANGING
        t_table      = lt_rows ).
    lo_salv->display( ).

    DATA(lv_html) = zcl_gg_gui_runtime=>render_html(
      iv_document       = abap_false
      iv_container_name = 'CC_MAIN' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-control-kind="ALV_GRID"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>42<' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'gg-external' ) ).
  ENDMETHOD.
ENDCLASS.
