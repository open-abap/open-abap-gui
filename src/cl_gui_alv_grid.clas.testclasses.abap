CLASS ltcl_grid_regressions DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_row,
             name   TYPE string,
             amount TYPE i,
           END OF ty_row.
    DATA mt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA mo_grid TYPE REF TO cl_gui_alv_grid.
    DATA mv_event TYPE string.
    METHODS setup.
    METHODS teardown.
    METHODS standard_sort_and_sum FOR TESTING.
    METHODS filter_and_find FOR TESTING.
    METHODS layout_modes_and_order FOR TESTING.
    METHODS help_and_menu_events FOR TESTING.
    METHODS protocol_marks_bad_cells FOR TESTING.
    METHODS on_f4 FOR EVENT onf4 OF cl_gui_alv_grid IMPORTING e_fieldname es_row_no.
    METHODS on_menu FOR EVENT menu_button OF cl_gui_alv_grid IMPORTING e_object e_ucomm.
    METHODS on_context FOR EVENT context_menu_request OF cl_gui_alv_grid IMPORTING e_object.
    METHODS on_command FOR EVENT user_command OF cl_gui_alv_grid IMPORTING e_ucomm.
ENDCLASS.

CLASS cl_gui_alv_grid DEFINITION LOCAL FRIENDS ltcl_grid_regressions.

CLASS ltcl_grid_regressions IMPLEMENTATION.
  METHOD setup.
    cl_gui_control=>clear( ).
    mt_rows = VALUE #( ( name = 'Zulu' amount = 8 ) ( name = 'Alpha' amount = 2 ) ).
    mo_grid = NEW cl_gui_alv_grid( i_parent = cl_gui_container=>default_screen ).
    DATA(lt_fields) = VALUE lvc_t_fcat( ( fieldname = 'NAME' inttype = 'C' col_pos = 1 )
      ( fieldname = 'AMOUNT' inttype = 'I' col_pos = 2 ) ).
    mo_grid->set_table_for_first_display( EXPORTING is_variant = VALUE #( report = 'FOO_TEST' )
                                                    i_save = 'A'
      CHANGING it_outtab = mt_rows it_fieldcatalog = lt_fields ).
  ENDMETHOD.

  METHOD teardown.
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD standard_sort_and_sum.
    mo_grid->dispatch_frontend_event( event  = 'FUNCTION'
                                      params = VALUE #( ( `&SORT_ASC` ) ) ).
    mo_grid->get_sort_criteria( IMPORTING et_sort = DATA(lt_sort) ).
    cl_abap_unit_assert=>assert_equals( act = lt_sort[ 1 ]-fieldname
                                        exp = 'NAME' ).
    cl_abap_unit_assert=>assert_true( lt_sort[ 1 ]-up ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_grid->render_model( ) CS '>Alpha<' ) ).
    mo_grid->ms_current_col-fieldname = 'AMOUNT'.
    mo_grid->dispatch_frontend_event( event  = 'FUNCTION'
                                      params = VALUE #( ( `&SUMC` ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_grid->render_model( ) CS 'gg-grid-total' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_grid->render_model( ) CS '>10</td>' ) ).
  ENDMETHOD.

  METHOD filter_and_find.
    mo_grid->mt_layout_input = VALUE #( ( name = 'layout_field' value = 'NAME' )
      ( name = 'layout_term' value = 'Alpha' ) ( name = 'layout_option' value = 'EQ' ) ).
    mo_grid->dispatch_frontend_event( event  = 'LAYOUT'
                                      params = VALUE #( ( `FILTER` ) ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( mo_grid->render_model( ) CS '>Zulu<' ) ).
    mo_grid->dispatch_frontend_event( event  = 'FUNCTION'
                                      params = VALUE #( ( `&DELETE_FILTER` ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_grid->render_model( ) CS '>Zulu<' ) ).
    mo_grid->mt_layout_input = VALUE #( ( name = 'layout_term' value = 'ALPHA' ) ).
    mo_grid->dispatch_frontend_event( event  = 'LAYOUT'
                                      params = VALUE #( ( `FIND` ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_grid->render_model( ) CS 'gg-state-found' ) ).
  ENDMETHOD.

  METHOD layout_modes_and_order.
    mo_grid->mt_layout_input = VALUE #( ( name = 'layout_col:NAME' value = 'X' )
      ( name = 'layout_col:AMOUNT' value = 'X' ) ( name = 'layout_pos:NAME' value = '2' )
      ( name = 'layout_pos:AMOUNT' value = '1' ) ).
    mo_grid->dispatch_frontend_event( event  = 'LAYOUT'
                                      params = VALUE #( ( `APPLY` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mo_grid->mt_fieldcatalog[ 1 ]-fieldname
                                        exp = 'AMOUNT' ).
    mo_grid->mv_variant_save = 'U'.
    mo_grid->mt_layout_input = VALUE #( ( name = 'layout_name' value = '/GLOBAL' ) ).
    mo_grid->dispatch_frontend_event( event  = 'LAYOUT'
                                      params = VALUE #( ( `SAVE` ) ) ).
    cl_abap_unit_assert=>assert_not_initial( mo_grid->mv_layout_error ).
    mo_grid->mt_layout_input = VALUE #( ( name = 'layout_name' value = 'PERSONAL' ) ).
    mo_grid->dispatch_frontend_event( event  = 'LAYOUT'
                                      params = VALUE #( ( `SAVE` ) ) ).
    DATA(ls_layout) = cl_alv_variant=>read_layout( VALUE #( report = 'FOO_TEST' variant = 'PERSONAL' ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_layout-fields[ 1 ]
                                        exp = 'AMOUNT' ).
    mo_grid->dispatch_frontend_event( event  = 'LAYOUT'
                                      params = VALUE #( ( `DELETE` ) ( `PERSONAL` ) ) ).
    cl_abap_unit_assert=>assert_initial( cl_alv_variant=>read_layout( VALUE #( report = 'FOO_TEST' variant = 'PERSONAL' ) ) ).
    cl_alv_variant=>save_layout( VALUE #( report = 'FOO_TEST' variant = '/GLOBAL' ) ).
    mo_grid->dispatch_frontend_event( event = 'LAYOUT'
      params                                = VALUE #( ( `DELETE` ) ( `/GLOBAL` ) ) ).
    cl_abap_unit_assert=>assert_not_initial( cl_alv_variant=>read_layout( VALUE #( report = 'FOO_TEST' variant = '/GLOBAL' ) ) ).
    mo_grid->mv_variant_save = 'X'.
    mo_grid->dispatch_frontend_event( event = 'LAYOUT'
      params                                = VALUE #( ( `DELETE` ) ( `/GLOBAL` ) ) ).
    cl_abap_unit_assert=>assert_initial( cl_alv_variant=>read_layout( VALUE #( report = 'FOO_TEST' variant = '/GLOBAL' ) ) ).
  ENDMETHOD.

  METHOD protocol_marks_bad_cells.
    mo_grid->mt_protocol = VALUE #( ( row_id = 1 fieldname = 'NAME'
      msgid = 'ZGG_EX' msgno = '001' msgty = 'E' msgv1 = 'Bad' msgv2 = 'name' ) ).
    DATA(lv_html) = mo_grid->render_model( ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_html CS '>Bad name</li>' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_html CS 'aria-invalid="true"' ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_html CS '>001</li>' ) ).
  ENDMETHOD.

  METHOD on_f4.
    mv_event = |F4:{ e_fieldname }:{ es_row_no-row_id }|.
  ENDMETHOD.

  METHOD on_menu.
    mv_event = e_ucomm.
    e_object->add_function( fcode = 'CHOOSE'
                            text  = 'Choose' ).
  ENDMETHOD.

  METHOD on_context.
    mv_event = 'CONTEXT'.
    e_object->add_function( fcode = 'CHOOSE'
                            text  = 'Choose' ).
  ENDMETHOD.

  METHOD on_command.
    mv_event = e_ucomm.
  ENDMETHOD.

  METHOD help_and_menu_events.
    SET HANDLER on_f4 FOR mo_grid.
    SET HANDLER on_menu FOR mo_grid.
    SET HANDLER on_context FOR mo_grid.
    SET HANDLER on_command FOR mo_grid.
    mo_grid->dispatch_frontend_event( event  = 'F4'
                                      params = VALUE #( ( `2` ) ( `NAME` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mv_event
                                        exp = 'F4:NAME:2' ).
    mo_grid->dispatch_frontend_event( event  = 'MENU'
                                      params = VALUE #( ( `MYMENU` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mv_event
                                        exp = 'MYMENU' ).
    cl_abap_unit_assert=>assert_true( xsdbool( mo_grid->render_model( ) CS 'role="menuitem"' ) ).
    mo_grid->dispatch_frontend_event( event  = 'FUNCTION'
                                      params = VALUE #( ( `CHOOSE` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mv_event
                                        exp = 'CHOOSE' ).
    mo_grid->dispatch_frontend_event( event  = 'CONTEXT'
                                      params = VALUE #( ( `1` ) ( `NAME` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = mv_event
                                        exp = 'CONTEXT' ).
  ENDMETHOD.
ENDCLASS.
