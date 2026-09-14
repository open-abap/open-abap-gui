CLASS ltcl_salv_table_support DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS renders_structured_rows FOR TESTING.
    METHODS keeps_selection_and_functions FOR TESTING.
    METHODS applies_filter_and_sort_state FOR TESTING
      RAISING
        cx_salv_data_error
        cx_salv_existing
        cx_salv_not_found.
ENDCLASS.

CLASS ltcl_salv_table_support IMPLEMENTATION.
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
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-salv-row-1' ) ).
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
    cl_abap_unit_assert=>assert_true( act = lo_sort->is_subtotal( ) ).
    DATA(lv_html) = lo_salv->get_html( ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'UA' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'LH' ) ).
    lo_salv->get_filters( )->clear( ).
    lo_salv->get_sorts( )->clear( ).
    cl_abap_unit_assert=>assert_initial( lo_salv->get_filters( )->get( ) ).
    cl_abap_unit_assert=>assert_initial( lo_salv->get_sorts( )->get( ) ).
  ENDMETHOD.
ENDCLASS.
