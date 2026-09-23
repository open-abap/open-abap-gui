CLASS ltcl_gg_compatibility_popup DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS table_popup_returns_choice FOR TESTING.
    METHODS classic_alv_renders_rows FOR TESTING.
    METHODS classic_alv_metadata_events FOR TESTING.
    METHODS classic_alv_blocks_are_grouped FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_compatibility_popup IMPLEMENTATION.

  METHOD table_popup_returns_choice.
    DATA lt_values TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lv_choice TYPE i.
    DATA lx_popup TYPE REF TO zcx_gg_control_flow.
    DATA lo_compatibility TYPE REF TO zif_gg_compatibility_v1.
    lo_compatibility ?= NEW zcl_gg_host_compatibility( ).

    APPEND 'First row' TO lt_values.
    APPEND 'Second row' TO lt_values.
    lo_compatibility->set_popup_request(
      iv_action = ''
      it_values = VALUE #( ) ).
    TRY.
        lv_choice = lo_compatibility->popup_with_table_display(
          EXPORTING
            is_request = VALUE #( title = 'Choose a row' )
          CHANGING
            ct_values  = lt_values ).
        cl_abap_unit_assert=>fail( 'The table popup must suspend on first display' ).
      CATCH zcx_gg_control_flow INTO lx_popup.
        cl_abap_unit_assert=>assert_equals(
          act = lx_popup->mv_operation
          exp = 'POPUP WITH TABLE DISPLAY' ).
    ENDTRY.

    DATA(ls_popup) = lo_compatibility->get_popup( ).
    cl_abap_unit_assert=>assert_equals( act = ls_popup-kind
                                        exp = 'TABLE' ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_popup-table_values )
                                        exp = 2 ).
    lo_compatibility->set_popup_request(
      iv_action = 'TABLE:2'
      it_values = VALUE #( ) ).
    lv_choice = lo_compatibility->popup_with_table_display(
      EXPORTING
        is_request = VALUE #( title = 'Choose a row' )
      CHANGING
        ct_values  = lt_values ).
    cl_abap_unit_assert=>assert_equals( act = lv_choice
                                        exp = 2 ).
  ENDMETHOD.

  METHOD classic_alv_renders_rows.
    TYPES: BEGIN OF ty_row,
             carrier TYPE string,
             flight  TYPE string,
             seats   TYPE i,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lo_compatibility TYPE REF TO zif_gg_compatibility_v1.
    lo_compatibility ?= NEW zcl_gg_host_compatibility( ).
    APPEND VALUE #( carrier = 'Lufthansa' flight = 'LH400' seats = 180 ) TO lt_rows.
    cl_gui_control=>clear( ).
    lo_compatibility->alv_display(
      EXPORTING
        is_request = VALUE #( grid_title = 'Classic flights' list_type = 0 )
      CHANGING
        ct_outtab  = lt_rows ).
    DATA(lv_html) = cl_gui_control=>render_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-classic-alv' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Classic flights' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'LH400' ) ).
  ENDMETHOD.

  METHOD classic_alv_metadata_events.
    DATA lt_fieldcat TYPE slis_t_fieldcat_alv.
    DATA lt_events TYPE slis_t_event.
    DATA lt_commentary TYPE slis_t_listheader.
    DATA ls_variant TYPE disvariant.
    DATA lv_exit TYPE c.
    DATA lo_compatibility TYPE REF TO zif_gg_compatibility_v1.
    lo_compatibility ?= NEW zcl_gg_host_compatibility( ).
    lo_compatibility->alv_fieldcatalog_merge(
      EXPORTING
        is_request  = VALUE #( tabname_header = 'GT_ROWS' title = 'Flight' )
      CHANGING
        ct_fieldcat = lt_fieldcat ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_fieldcat )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_fieldcat[ 1 ]-fieldname
      exp = 'FIELD1' ).
    lo_compatibility->alv_events_get(
      EXPORTING
        is_request = VALUE #( list_type = 0 )
      CHANGING
        ct_events  = lt_events ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( lt_events[ name = 'USER_COMMAND' ] ) ) ).
    lo_compatibility->alv_variant_f4(
      EXPORTING
        is_request = VALUE #( report = 'ZCLASSIC' )
      CHANGING
        cs_variant = ls_variant
        cv_exit    = lv_exit ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_variant-variant
      exp = 'DEFAULT' ).
    lo_compatibility->alv_commentary_write( CHANGING ct_list_commentary = lt_commentary ).
    cl_abap_unit_assert=>assert_equals( act = lt_commentary[ 1 ]-info
                                        exp = 'Classic ALV semantic renderer' ).
  ENDMETHOD.

  METHOD classic_alv_blocks_are_grouped.
    TYPES: BEGIN OF ty_row,
             value TYPE string,
           END OF ty_row.
    DATA lt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
    DATA lo_compatibility TYPE REF TO zif_gg_compatibility_v1.
    lo_compatibility ?= NEW zcl_gg_host_compatibility( ).
    APPEND VALUE #( value = 'Block row' ) TO lt_rows.
    lo_compatibility->alv_block_init( is_request = VALUE #( ) ).
    lo_compatibility->alv_block_append(
      EXPORTING
        is_request = VALUE #( title = 'First block' )
      CHANGING
        ct_outtab  = lt_rows ).
    lo_compatibility->alv_block_display( is_request = VALUE #( ) ).
    DATA(lv_html) = cl_gui_control=>render_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-classic-alv-blocks' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Block row' ) ).
  ENDMETHOD.

ENDCLASS.
