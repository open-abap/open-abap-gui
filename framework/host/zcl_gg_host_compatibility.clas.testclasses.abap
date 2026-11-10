CLASS ltcl_gg_compatibility_popup DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    METHODS table_popup_returns_choice FOR TESTING.
    METHODS classic_alv_renders_rows FOR TESTING.
    METHODS classic_alv_metadata_events FOR TESTING.
    METHODS classic_alv_blocks_are_grouped FOR TESTING.
    METHODS selection_lists_are_refreshed FOR TESTING.
    METHODS refresh_skips_tab_labels FOR TESTING.
    METHODS selection_table_any_key FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_compatibility_popup IMPLEMENTATION.

  METHOD teardown.
* A popup request makes the layer current; no other test should find it.
    zcl_gg_host_compatibility=>set_current( ).
  ENDMETHOD.

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
    zcl_gg_gui_runtime=>clear( ).
    lo_compatibility->alv_display(
      EXPORTING
        is_request = VALUE #( grid_title = 'Classic flights' list_type = 0 )
      CHANGING
        ct_outtab  = lt_rows ).
    DATA(lv_html) = zcl_gg_gui_runtime=>render_html( ).
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
    DATA(lv_html) = zcl_gg_gui_runtime=>render_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-classic-alv-blocks' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Block row' ) ).
  ENDMETHOD.

  METHOD selection_lists_are_refreshed.
    DATA lo_compatibility TYPE REF TO zif_gg_compatibility_v1.
    lo_compatibility ?= NEW zcl_gg_host_compatibility( ).
    lo_compatibility->set_selection_list_values(
      iv_id     = 'P_MODE'
      it_values = VALUE #( ( key = 'A' text = 'Alpha' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( zcl_gg_host_compatibility=>get_selection_list_values( ) )
                                        exp = 1 ).
    lo_compatibility->refresh_selection_list_values( ).
    cl_abap_unit_assert=>assert_initial( zcl_gg_host_compatibility=>get_selection_list_values( ) ).
  ENDMETHOD.

  METHOD refresh_skips_tab_labels.
* A tab label travels in the values but is no selection.
    DATA lo_compatibility TYPE REF TO zif_gg_compatibility_v1.
    DATA lt_selection TYPE zif_gg_compatibility_v1=>ty_variant_parameters.
    lo_compatibility ?= NEW zcl_gg_host_compatibility( ).
    lo_compatibility->set_selection_context(
      iv_report = 'ZREPORT'
      it_values = VALUE #( ( name = 'P_NAME' value = 'Ada' ) ( name = 'TAB1' value = 'General' ) )
      it_states = VALUE #( ( name = 'P_NAME' ) ) ).
    lo_compatibility->variant_refresh(
      EXPORTING
        is_request   = VALUE #( )
      CHANGING
        ct_selection = lt_selection ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_selection )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_selection[ 1 ]-selname
                                        exp = 'P_NAME' ).
  ENDMETHOD.

  METHOD selection_table_any_key.
* SUBMIT ... WITH SELECTION-TABLE takes a table of rsparams with any key.
    DATA lo_compatibility TYPE REF TO zif_gg_compatibility_v1.
    DATA lt_default TYPE STANDARD TABLE OF rsparams WITH DEFAULT KEY.
    DATA lt_empty TYPE STANDARD TABLE OF rsparams WITH EMPTY KEY.
    lo_compatibility ?= NEW zcl_gg_host_compatibility( ).
    lt_default = VALUE #(
      ( selname = 'P_NAME' kind = 'P' low = 'Ada' )
      ( selname = 'S_CARR' kind = 'S' sign = 'I' option = 'EQ' low = 'LH' ) ).
    lt_empty = lt_default.
    DATA(lt_values) = lo_compatibility->selection_table_to_values( lt_empty ).
    cl_abap_unit_assert=>assert_equals( act = lt_values
                                        exp = lo_compatibility->selection_table_to_values( lt_default ) ).
    cl_abap_unit_assert=>assert_equals( act = lt_values[ name = 'P_NAME' ]-value
                                        exp = `Ada` ).
    cl_abap_unit_assert=>assert_equals( act = lt_values[ name = 'S_CARR' ]-ranges[ 1 ]-low
                                        exp = `LH` ).
  ENDMETHOD.

ENDCLASS.

* cl_gui_frontend_services on a screen: what it hands to the browser goes
* through this layer.
CLASS ltcl_frontend_services DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    METHODS clipboard_roundtrip FOR TESTING.
    METHODS execute_opens_web_document FOR TESTING.
    METHODS execute_refuses_unsupported FOR TESTING.
    METHODS execute_refuses_bad_document FOR TESTING.

    "! sy-subrc of EXECUTE: 3 is BAD_PARAMETER and 9 NOT_SUPPORTED_BY_GUI.
    METHODS execute_subrc
      IMPORTING
        iv_document     TYPE string
        iv_application  TYPE string OPTIONAL
        iv_parameter    TYPE string OPTIONAL
        iv_synchronous  TYPE string OPTIONAL
        iv_operation    TYPE string DEFAULT 'OPEN'
      RETURNING
        VALUE(rv_subrc) TYPE i.

    "! The compatibility layer of a screen being processed.
    METHODS screen_host
      RETURNING
        VALUE(ro_host) TYPE REF TO zcl_gg_host_compatibility.

ENDCLASS.

CLASS ltcl_frontend_services IMPLEMENTATION.

  METHOD teardown.
    zcl_gg_host_compatibility=>set_current( ).
  ENDMETHOD.

  METHOD screen_host.
    ro_host = NEW zcl_gg_host_compatibility( ).
    ro_host->zif_gg_compatibility_v1~set_popup_request( iv_action = ''
                                                        it_values = VALUE #( ) ).
  ENDMETHOD.

  METHOD execute_subrc.
    cl_gui_frontend_services=>execute(
      EXPORTING
        document               = iv_document
        application            = iv_application
        parameter              = iv_parameter
        synchronous            = iv_synchronous
        operation              = iv_operation
      EXCEPTIONS
        cntl_error             = 1
        error_no_gui           = 2
        bad_parameter          = 3
        file_not_found         = 4
        path_not_found         = 5
        file_extension_unknown = 6
        error_execute_failed   = 7
        synchronous_failed     = 8
        not_supported_by_gui   = 9
        OTHERS                 = 10 ).
    rv_subrc = sy-subrc.
  ENDMETHOD.

  METHOD clipboard_roundtrip.
    DATA(lo_host) = NEW zcl_gg_host_compatibility( ).
    DATA lv_rc TYPE i.
    DATA lt_text TYPE string_table.
    lo_host->zif_gg_compatibility_v1~set_popup_request( iv_action = 'CLIPBOARD:OK'
      it_values                                                   = VALUE #( ( name = 'CONTENT' value = |first\r\nsecond  | ) ) ).
    cl_gui_frontend_services=>clipboard_import( IMPORTING data = lt_text length = DATA(lv_lines) ).
    cl_abap_unit_assert=>assert_equals( act = lv_lines
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_text[ 2 ]
                                        exp = `second  ` ).
    cl_gui_frontend_services=>clipboard_export( IMPORTING data = lt_text CHANGING rc = lv_rc ).
    cl_abap_unit_assert=>assert_equals( act = lv_rc
                                        exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_text )
                                        exp = 2 ).
    DATA(lt_actions) = lo_host->get_downloads( ).
    cl_abap_unit_assert=>assert_true( lt_actions[ 1 ]-clipboard ).
    cl_abap_unit_assert=>assert_equals( act = cl_abap_codepage=>convert_from( lt_actions[ 1 ]-content )
      exp                                   = |first\r\nsecond  | ).
  ENDMETHOD.

  METHOD execute_opens_web_document.
    DATA(lo_host) = screen_host( ).

    cl_abap_unit_assert=>assert_equals( act = execute_subrc( ` https://example.com/docs/guide.html?lang=en#intro ` )
                                        exp = 0 ).
* Neither the operation nor the scheme is case sensitive.
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( iv_document  = `HTTP://example.org:8080/a`
                                                             iv_operation = `open` )
                                        exp = 0 ).

    DATA(lt_actions) = lo_host->get_downloads( ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_actions )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_actions[ 1 ]-url
                                        exp = `https://example.com/docs/guide.html?lang=en#intro` ).
    cl_abap_unit_assert=>assert_initial( lt_actions[ 1 ]-content ).
    cl_abap_unit_assert=>assert_initial( lt_actions[ 1 ]-filename ).
    cl_abap_unit_assert=>assert_equals( act = lt_actions[ 2 ]-url
                                        exp = `HTTP://example.org:8080/a` ).
  ENDMETHOD.

  METHOD execute_refuses_unsupported.
    DATA(lo_host) = screen_host( ).

* Local files and programs are out of a browser's reach.
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `C:\temp\report.txt` )
                                        exp = 9 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `\\server\share\report.txt` )
                                        exp = 9 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `/tmp/report.txt` )
                                        exp = 9 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `file:///tmp/report.txt` )
                                        exp = 9 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `www.example.com` )
                                        exp = 9 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( iv_document    = ``
                                                             iv_application = `notepad.exe` )
                                        exp = 9 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( iv_document  = `https://example.com/`
                                                             iv_parameter = `-new-window` )
                                        exp = 9 ).
* Other schemes, script ones among them, are never opened.
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `javascript:alert(1)` )
                                        exp = 9 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `data:text/html,<p>x</p>` )
                                        exp = 9 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `mailto:someone@example.com` )
                                        exp = 9 ).
* Only OPEN, and nothing waits for the tab to close.
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( iv_document  = `https://example.com/report.pdf`
                                                             iv_operation = `PRINT` )
                                        exp = 9 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( iv_document    = `https://example.com/`
                                                             iv_synchronous = `X` )
                                        exp = 9 ).

    cl_abap_unit_assert=>assert_initial( lo_host->get_downloads( ) ).
  ENDMETHOD.

  METHOD execute_refuses_bad_document.
    DATA(lo_host) = screen_host( ).

    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `` )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `   ` )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `https://` )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `https:///no-host` )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `https:example.com` )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `https://user:secret@example.com/` )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `https://example.com/a b` )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( |https://example.com/\r\nx| )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = execute_subrc( `https://example.com\@other.example/` )
                                        exp = 3 ).

    cl_abap_unit_assert=>assert_initial( lo_host->get_downloads( ) ).
  ENDMETHOD.

ENDCLASS.
