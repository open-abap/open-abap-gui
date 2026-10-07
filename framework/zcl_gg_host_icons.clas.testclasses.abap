CLASS ltcl_gg_host_icons DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS resolves_sap_codes FOR TESTING.
    METHODS resolves_tooltip_codes FOR TESTING.
    METHODS resolves_icon_names FOR TESTING.
    METHODS resolves_semantic_names FOR TESTING.
    METHODS leaves_unknown_initial FOR TESTING.
    METHODS renders_tone FOR TESTING.
    METHODS renders_fallback FOR TESTING.
    METHODS sprite_has_every_symbol FOR TESTING.
    METHODS text_html_plain FOR TESTING.
    METHODS text_html_leading_icon FOR TESTING.
    METHODS text_html_icon_only FOR TESTING.
    METHODS plain_text FOR TESTING.
    METHODS resolves_object_codes FOR TESTING.
    METHODS resolves_object_names FOR TESTING.
    METHODS object_codes_keep_label_text FOR TESTING.
    METHODS object_symbols_exist FOR TESTING.
    METHODS maps_every_type_pool_icon FOR TESTING.
    METHODS prunes_unused_symbols FOR TESTING.

    TYPES: BEGIN OF ty_expected,
             code   TYPE string,
             name   TYPE string,
             symbol TYPE string,
             tone   TYPE string,
             label  TYPE string,
           END OF ty_expected.
    TYPES ty_expected_table TYPE STANDARD TABLE OF ty_expected WITH DEFAULT KEY.

* The codes, ICON_* names and English quick info texts of the ICON table.
    CLASS-METHODS object_icons
      RETURNING
        VALUE(rt_icons) TYPE ty_expected_table.

ENDCLASS.

CLASS ltcl_gg_host_icons IMPLEMENTATION.

  METHOD resolves_sap_codes.
    DATA(ls_icon) = zcl_gg_host_icons=>resolve( '@08@' ).
    cl_abap_unit_assert=>assert_equals( exp = 'status-light'
                                        act = ls_icon-symbol ).
    cl_abap_unit_assert=>assert_equals( exp = 'success'
                                        act = ls_icon-tone ).
    cl_abap_unit_assert=>assert_equals( exp = 'Green light'
                                        act = ls_icon-label ).

    ls_icon = zcl_gg_host_icons=>resolve( '@0v@' ).
    cl_abap_unit_assert=>assert_equals( exp = 'circle-check'
                                        act = ls_icon-symbol ).

    ls_icon = zcl_gg_host_icons=>resolve( '42' ).
    cl_abap_unit_assert=>assert_equals( exp = 'refresh'
                                        act = ls_icon-symbol ).
  ENDMETHOD.

  METHOD resolves_tooltip_codes.
    DATA(ls_icon) = zcl_gg_host_icons=>resolve( '@0A\QOrder blocked@' ).
    cl_abap_unit_assert=>assert_equals( exp = 'status-light'
                                        act = ls_icon-symbol ).
    cl_abap_unit_assert=>assert_equals( exp = 'error'
                                        act = ls_icon-tone ).
    cl_abap_unit_assert=>assert_equals( exp = 'Order blocked'
                                        act = ls_icon-label ).
  ENDMETHOD.

  METHOD resolves_icon_names.
    DATA(ls_icon) = zcl_gg_host_icons=>resolve( 'ICON_LED_RED' ).
    cl_abap_unit_assert=>assert_equals( exp = 'status-led'
                                        act = ls_icon-symbol ).
    cl_abap_unit_assert=>assert_equals( exp = 'error'
                                        act = ls_icon-tone ).

    ls_icon = zcl_gg_host_icons=>resolve( '@ICON_GREEN_LIGHT@' ).
    cl_abap_unit_assert=>assert_equals( exp = 'status-light'
                                        act = ls_icon-symbol ).

    ls_icon = zcl_gg_host_icons=>resolve( 'icon_execute' ).
    cl_abap_unit_assert=>assert_equals( exp = 'player-play'
                                        act = ls_icon-symbol ).
  ENDMETHOD.

  METHOD resolves_semantic_names.
    DATA(ls_icon) = zcl_gg_host_icons=>resolve( 'go' ).
    cl_abap_unit_assert=>assert_equals( exp = 'player-play'
                                        act = ls_icon-symbol ).

    ls_icon = zcl_gg_host_icons=>resolve( 'circle-check' ).
    cl_abap_unit_assert=>assert_equals( exp = 'circle-check'
                                        act = ls_icon-symbol ).
    cl_abap_unit_assert=>assert_initial( ls_icon-tone ).
  ENDMETHOD.

  METHOD leaves_unknown_initial.
    cl_abap_unit_assert=>assert_initial( zcl_gg_host_icons=>resolve( '@SYM_PHONE@' ) ).
    cl_abap_unit_assert=>assert_initial( zcl_gg_host_icons=>resolve( 'LH400' ) ).
    cl_abap_unit_assert=>assert_initial( zcl_gg_host_icons=>resolve( '' ) ).
  ENDMETHOD.

  METHOD renders_tone.
    DATA(lv_html) = zcl_gg_host_icons=>icon( '@5C@' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="wb-icon wb-icon--error" style="color:#b3261e"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'href="#wb-icon-status-led"' ) ).

    lv_html = zcl_gg_host_icons=>icon( 'refresh' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'class="wb-icon" aria-hidden="true"' ) ).
  ENDMETHOD.

  METHOD renders_fallback.
    DATA(lv_html) = zcl_gg_host_icons=>icon( iv_name     = '@ZZ@'
                                             iv_fallback = 'folder' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'href="#wb-icon-folder"' ) ).

    lv_html = zcl_gg_host_icons=>icon( 'not-a-real-icon' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'href="#wb-icon-square-dashed"' ) ).
  ENDMETHOD.

  METHOD sprite_has_every_symbol.
    DATA(lv_sprite) = zcl_gg_host_icons=>sprite( ).
    DATA(lt_names) = VALUE string_table(
      ( `@00@` ) ( `@01@` ) ( `@02@` ) ( `@03@` ) ( `@04@` ) ( `@05@` ) ( `@06@` ) ( `@07@` )
      ( `@08@` ) ( `@EB@` ) ( `@5B@` ) ( `@0V@` ) ( `@0W@` ) ( `@1B@` ) ( `@DR@` ) ( `@0Y@` )
      ( `@10@` ) ( `@12@` ) ( `@14@` ) ( `@EZ@` ) ( `@16@` ) ( `@17@` ) ( `@18@` ) ( `@3R@` )
      ( `@0P@` ) ( `@0Q@` ) ( `@4B@` ) ( `@4D@` ) ( `@4G@` ) ( `@GD@` ) ( `@8B@` ) ( `@49@` )
      ( `@48@` ) ( `@J2@` ) ( `@IT@` ) ( `@38@` ) ( `@39@` ) ( `@3C@` ) ( `@2R@` ) ( `@2S@` )
      ( `@3S@` ) ( `@3T@` ) ( `@0M@` ) ( `@0N@` ) ( `@2K@` ) ( `@2V@` ) ( `@FO@` ) ( `@AR@` )
      ( `@3W@` ) ( `@3M@` ) ( `@3Y@` ) ( `@FM@` ) ( `@1S@` ) ( `@1U@` ) ( `@1T@` ) ( `@96@` )
      ( `@5W@` ) ( `@XC@` ) ( `@45@` ) ( `@4A@` ) ( `@M4@` ) ( `@PO@` ) ( `unknown` ) ).

    LOOP AT lt_names INTO DATA(lv_name).
      DATA(ls_icon) = zcl_gg_host_icons=>resolve( lv_name ).
      cl_abap_unit_assert=>assert_not_initial( act = ls_icon-symbol
                                               msg = lv_name ).
      cl_abap_unit_assert=>assert_true( act = xsdbool( lv_sprite CS |id="wb-icon-{ ls_icon-symbol }"| )
                                        msg = lv_name ).
    ENDLOOP.
  ENDMETHOD.

  METHOD text_html_plain.
    cl_abap_unit_assert=>assert_equals( exp = 'A &amp; B'
                                        act = zcl_gg_host_icons=>text_html( 'A & B' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'mail@host'
                                        act = zcl_gg_host_icons=>text_html( 'mail@host' ) ).
  ENDMETHOD.

  METHOD text_html_leading_icon.
    DATA(lv_html) = zcl_gg_host_icons=>text_html( '@XC@ Output' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<use href="#wb-icon-settings"></use></svg> Output' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-hidden="true"' ) ).

    lv_html = zcl_gg_host_icons=>text_html( '@ICON:position Connection' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<use href="#wb-icon-map-pin"></use></svg> Connection' ) ).

    lv_html = zcl_gg_host_icons=>text_html( '@DR\QError <log>@Log' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<span title="Error &lt;log&gt;"><svg' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '</svg></span> Log' ) ).
  ENDMETHOD.

  METHOD text_html_icon_only.
    DATA(lv_html) = zcl_gg_host_icons=>text_html( '@0A@' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'role="img" aria-label="Red light"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '@0A@' ) ).
  ENDMETHOD.

  METHOD plain_text.
    cl_abap_unit_assert=>assert_equals( exp = 'Connection'
                                        act = zcl_gg_host_icons=>plain_text( '@ICON:position Connection' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Log'
                                        act = zcl_gg_host_icons=>plain_text( '@DR\QError log@Log' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Red light'
                                        act = zcl_gg_host_icons=>plain_text( '@0A@' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'General'
                                        act = zcl_gg_host_icons=>plain_text( 'General' ) ).
  ENDMETHOD.

  METHOD object_icons.
    rt_icons = VALUE #(
      ( code = `@FP@` name = `ICON_OBJECT_FOLDER`     symbol = `folder-open`        label = `Open object folder` )
      ( code = `@TT@` name = `ICON_RETAIL_PRODUCT`    symbol = `shopping-bag`       label = `Retail product` )
      ( code = `@AD@` name = `ICON_SUPPLIER`          symbol = `building-factory-2` label = `Vendor` )
      ( code = `@9F@` name = `ICON_BEN_OFFER_OPEN`    symbol = `tag`                label = `Open offer` )
      ( code = `@2Q@` name = `ICON_OTHER_OBJECT`      symbol = `box`                label = `Other object` )
      ( code = `@AC@` name = `ICON_STORE_LOCATION`    symbol = `building-warehouse` label = `Storage location` )
      ( code = `@A5@` name = `ICON_TRANSPORT_POINT`   symbol = `arrows-exchange`    label = `Stock transfer point` )
      ( code = `@9Z@` name = `ICON_ORDER`             symbol = `clipboard-list`     label = `Order` )
      ( code = `@9O@` name = `ICON_ACTION_FAULT`      symbol = `file-alert`         label = `Request contains errors` tone = `error` )
      ( code = `@AT@` name = `ICON_MATERIAL_REVISION` symbol = `versions`           label = `Article revision` ) ).
  ENDMETHOD.

  METHOD resolves_object_codes.
    LOOP AT object_icons( ) INTO DATA(ls_expected).
      DATA(ls_icon) = zcl_gg_host_icons=>resolve( ls_expected-code ).
      cl_abap_unit_assert=>assert_equals( exp = ls_expected-symbol
                                          act = ls_icon-symbol
                                          msg = ls_expected-code ).
      cl_abap_unit_assert=>assert_equals( exp = ls_expected-tone
                                          act = ls_icon-tone
                                          msg = ls_expected-code ).
      cl_abap_unit_assert=>assert_equals( exp = ls_expected-label
                                          act = ls_icon-label
                                          msg = ls_expected-code ).
* A tab label never falls back to the placeholder for these codes.
      cl_abap_unit_assert=>assert_false( act = xsdbool( zcl_gg_host_icons=>icon( ls_expected-code ) CS 'wb-icon-square-dashed' )
                                         msg = ls_expected-code ).
    ENDLOOP.
* An unknown code still renders the placeholder.
    cl_abap_unit_assert=>assert_initial( zcl_gg_host_icons=>resolve( '@Q9@' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( zcl_gg_host_icons=>icon( '@Q9@' ) CS 'href="#wb-icon-square-dashed"' ) ).
  ENDMETHOD.

  METHOD resolves_object_names.
    LOOP AT object_icons( ) INTO DATA(ls_expected).
      cl_abap_unit_assert=>assert_equals( exp = ls_expected-symbol
                                          act = zcl_gg_host_icons=>resolve( ls_expected-name )-symbol
                                          msg = ls_expected-name ).
    ENDLOOP.
  ENDMETHOD.

  METHOD object_codes_keep_label_text.
    LOOP AT object_icons( ) INTO DATA(ls_expected).
* With and without a blank between icon and text, as tab labels write them.
      DATA(lv_html) = zcl_gg_host_icons=>text_html( |{ ls_expected-code } Release & delivery| ).
      cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS |<use href="#wb-icon-{ ls_expected-symbol }"></use></svg> Release &amp; delivery| )
                                        msg = ls_expected-code ).
      cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS ls_expected-code )
                                         msg = ls_expected-code ).
      lv_html = zcl_gg_host_icons=>text_html( |{ ls_expected-code }Releases| ).
      cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS |<use href="#wb-icon-{ ls_expected-symbol }"></use></svg> Releases| )
                                        msg = ls_expected-code ).
      cl_abap_unit_assert=>assert_equals( exp = `Releases`
                                          act = zcl_gg_host_icons=>plain_text( |{ ls_expected-code }Releases| )
                                          msg = ls_expected-code ).
* An icon-only label is named by the icon's quick info.
      lv_html = zcl_gg_host_icons=>text_html( ls_expected-code ).
      cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS |role="img" aria-label="{ ls_expected-label }"| )
                                        msg = ls_expected-code ).
    ENDLOOP.
  ENDMETHOD.

  METHOD object_symbols_exist.
    DATA(lv_sprite) = zcl_gg_host_icons=>sprite( ).
    LOOP AT object_icons( ) INTO DATA(ls_expected).
      cl_abap_unit_assert=>assert_true( act = xsdbool( lv_sprite CS |<symbol id="wb-icon-{ ls_expected-symbol }" viewBox="0 0 24 24"| )
                                        msg = ls_expected-code ).
    ENDLOOP.
  ENDMETHOD.

  METHOD maps_every_type_pool_icon.
* Every constant of the open-abap ICON type pool, by its value and by its
* name, resolves to a symbol the sprite draws and never to the placeholder.
    TYPES: BEGIN OF ty_constant,
             name  TYPE string,
             value TYPE string,
           END OF ty_constant.
    DATA lt_constants TYPE STANDARD TABLE OF ty_constant WITH DEFAULT KEY.
    DATA(lv_sprite) = zcl_gg_host_icons=>sprite( ).

    lt_constants = VALUE #(
      ( name = `ICON_ABAP` value = icon_abap )
      ( name = `ICON_ACTION_SUCCESS` value = icon_action_success )
      ( name = `ICON_ACTIVATE` value = icon_activate )
      ( name = `ICON_ACTIVITY` value = icon_activity )
      ( name = `ICON_ADD_ROW` value = icon_add_row )
      ( name = `ICON_ADDRESS` value = icon_address )
      ( name = `ICON_ADOPT` value = icon_adopt )
      ( name = `ICON_ALARM` value = icon_alarm )
      ( name = `ICON_ALERT` value = icon_alert )
      ( name = `ICON_ALLOW` value = icon_allow )
      ( name = `ICON_ANNOTATION` value = icon_annotation )
      ( name = `ICON_ARROW_LEFT` value = icon_arrow_left )
      ( name = `ICON_ARROW_RIGHT` value = icon_arrow_right )
      ( name = `ICON_ATTACHMENT` value = icon_attachment )
      ( name = `ICON_BACKGROUND_JOB` value = icon_background_job )
      ( name = `ICON_BEN_CURRENT_BENEFITS` value = icon_ben_current_benefits )
      ( name = `ICON_BEN_TERMINATION` value = icon_ben_termination )
      ( name = `ICON_BIW_INFO_CATALOG` value = icon_biw_info_catalog )
      ( name = `ICON_BIW_INFO_CUBE` value = icon_biw_info_cube )
      ( name = `ICON_BIW_MONITOR` value = icon_biw_monitor )
      ( name = `ICON_BIW_REPORT` value = icon_biw_report )
      ( name = `ICON_BIW_SCHEDULER` value = icon_biw_scheduler )
      ( name = `ICON_BIW_SOURCE_SYS_R3` value = icon_biw_source_sys_r3 )
      ( name = `ICON_BOOKING_OK` value = icon_booking_ok )
      ( name = `ICON_BOOKING_STOP` value = icon_booking_stop )
      ( name = `ICON_BREAKPOINT` value = icon_breakpoint )
      ( name = `ICON_BREAKPOINT_DISABLE` value = icon_breakpoint_disable )
      ( name = `ICON_BUSINAV_PROCESS` value = icon_businav_process )
      ( name = `ICON_BUSINAV_PROCESSMATRIX` value = icon_businav_processmatrix )
      ( name = `ICON_BUSINAV_VALUE_CHAIN` value = icon_businav_value_chain )
      ( name = `ICON_BW_INFO_CUBE_INA` value = icon_bw_info_cube_ina )
      ( name = `ICON_BW_RA_SETTING_ACTIVE` value = icon_bw_ra_setting_active )
      ( name = `ICON_BW_RA_SETTING_INACTIVE` value = icon_bw_ra_setting_inactive )
      ( name = `ICON_CALCULATION` value = icon_calculation )
      ( name = `ICON_CANCEL` value = icon_cancel )
      ( name = `ICON_CHANGE` value = icon_change )
      ( name = `ICON_CHANGE_TEXT` value = icon_change_text )
      ( name = `ICON_CHECK` value = icon_check )
      ( name = `ICON_CHECKBOX` value = icon_checkbox )
      ( name = `ICON_CHECKED` value = icon_checked )
      ( name = `ICON_CLAIM` value = icon_claim )
      ( name = `ICON_CLIENT_BREAKPOINT` value = icon_client_breakpoint )
      ( name = `ICON_CLOSE` value = icon_close )
      ( name = `ICON_CLOSED_FOLDER` value = icon_closed_folder )
      ( name = `ICON_COLLAPSE` value = icon_collapse )
      ( name = `ICON_COLOR` value = icon_color )
      ( name = `ICON_COLUMN_LEFT` value = icon_column_left )
      ( name = `ICON_COLUMN_RIGHT` value = icon_column_right )
      ( name = `ICON_COMPARE` value = icon_compare )
      ( name = `ICON_COMPLETE` value = icon_complete )
      ( name = `ICON_COMPOSITE_ACTIVITYGROUP` value = icon_composite_activitygroup )
      ( name = `ICON_CONFIGURATION` value = icon_configuration )
      ( name = `ICON_CONNECT` value = icon_connect )
      ( name = `ICON_CONNECTION_OBJECT` value = icon_connection_object )
      ( name = `ICON_CONVERT` value = icon_convert )
      ( name = `ICON_COPY_OBJECT` value = icon_copy_object )
      ( name = `ICON_COST_COMPONENTS` value = icon_cost_components )
      ( name = `ICON_CREATE` value = icon_create )
      ( name = `ICON_CREATE_COPY` value = icon_create_copy )
      ( name = `ICON_CREATE_NOTE` value = icon_create_note )
      ( name = `ICON_CREATE_TEXT` value = icon_create_text )
      ( name = `ICON_CUSTOMER` value = icon_customer )
      ( name = `ICON_CUSTOMS` value = icon_customs )
      ( name = `ICON_CUT_RELATION` value = icon_cut_relation )
      ( name = `ICON_DATA_AREA_COLLAPSE` value = icon_data_area_collapse )
      ( name = `ICON_DATA_AREA_EXPAND` value = icon_data_area_expand )
      ( name = `ICON_DATABASE_TABLE` value = icon_database_table )
      ( name = `ICON_DATE` value = icon_date )
      ( name = `ICON_DEACTIVATE` value = icon_deactivate )
      ( name = `ICON_DEFECT` value = icon_defect )
      ( name = `ICON_DELETE` value = icon_delete )
      ( name = `ICON_DELETE_FAVORITES` value = icon_delete_favorites )
      ( name = `ICON_DELETE_ROW` value = icon_delete_row )
      ( name = `ICON_DELETE_TEMPLATE` value = icon_delete_template )
      ( name = `ICON_DELIVERY_INBOUND` value = icon_delivery_inbound )
      ( name = `ICON_DELIVERY_NO_CONFIRMATION` value = icon_delivery_no_confirmation )
      ( name = `ICON_DESELECT_ALL` value = icon_deselect_all )
      ( name = `ICON_DETAIL` value = icon_detail )
      ( name = `ICON_DIMENSION` value = icon_dimension )
      ( name = `ICON_DISCONNECT` value = icon_disconnect )
      ( name = `ICON_DISPLAY` value = icon_display )
      ( name = `ICON_DISPLAY_MORE` value = icon_display_more )
      ( name = `ICON_DISPLAY_NOTE` value = icon_display_note )
      ( name = `ICON_DISPLAY_TEXT` value = icon_display_text )
      ( name = `ICON_DISPO_LEVEL` value = icon_dispo_level )
      ( name = `ICON_DOC_HEADER_DETAIL` value = icon_doc_header_detail )
      ( name = `ICON_DOCUMENT` value = icon_document )
      ( name = `ICON_DROPDOWNLIST` value = icon_dropdownlist )
      ( name = `ICON_DUMMY` value = icon_dummy )
      ( name = `ICON_EDIT_FILE` value = icon_edit_file )
      ( name = `ICON_ELEMENT` value = icon_element )
      ( name = `ICON_EML` value = icon_eml )
      ( name = `ICON_EMPLOYEE` value = icon_employee )
      ( name = `ICON_ENTER_MORE` value = icon_enter_more )
      ( name = `ICON_ENVELOPE_CLOSED` value = icon_envelope_closed )
      ( name = `ICON_EQUAL` value = icon_equal )
      ( name = `ICON_EQUAL_GREEN` value = icon_equal_green )
      ( name = `ICON_EQUAL_RED` value = icon_equal_red )
      ( name = `ICON_ERROR_PROTOCOL` value = icon_error_protocol )
      ( name = `ICON_EXECUTE_OBJECT` value = icon_execute_object )
      ( name = `ICON_EXPAND` value = icon_expand )
      ( name = `ICON_EXPORT` value = icon_export )
      ( name = `ICON_EXTRA` value = icon_extra )
      ( name = `ICON_FAILURE` value = icon_failure )
      ( name = `ICON_FAST_ENTRY` value = icon_fast_entry )
      ( name = `ICON_FIELD_WITH_TEXT` value = icon_field_with_text )
      ( name = `ICON_FILTER` value = icon_filter )
      ( name = `ICON_FILTER_UNDO` value = icon_filter_undo )
      ( name = `ICON_FINITE` value = icon_finite )
      ( name = `ICON_FOLDER` value = icon_folder )
      ( name = `ICON_FOREIGN_KEY` value = icon_foreign_key )
      ( name = `ICON_GENERATE` value = icon_generate )
      ( name = `ICON_GIS_PAN` value = icon_gis_pan )
      ( name = `ICON_GIS_PROMOTE` value = icon_gis_promote )
      ( name = `ICON_GRADUATE` value = icon_graduate )
      ( name = `ICON_GRAPHICS` value = icon_graphics )
      ( name = `ICON_GREATER_EQUAL_GREEN` value = icon_greater_equal_green )
      ( name = `ICON_GREATER_GREEN` value = icon_greater_green )
      ( name = `ICON_GREEN_LIGHT` value = icon_green_light )
      ( name = `ICON_HEADER` value = icon_header )
      ( name = `ICON_HELPASSISTENT_ON` value = icon_helpassistent_on )
      ( name = `ICON_HINT` value = icon_hint )
      ( name = `ICON_HISTORY` value = icon_history )
      ( name = `ICON_HOST` value = icon_host )
      ( name = `ICON_HR_POSITION` value = icon_hr_position )
      ( name = `ICON_HTM` value = icon_htm )
      ( name = `ICON_ICON_LIST` value = icon_icon_list )
      ( name = `ICON_IDOC` value = icon_idoc )
      ( name = `ICON_IMPORT` value = icon_import )
      ( name = `ICON_IMPORT_ALL_REQUESTS` value = icon_import_all_requests )
      ( name = `ICON_IMPORT_TRANSPORT_REQUEST` value = icon_import_transport_request )
      ( name = `ICON_INCOMING_OBJECT` value = icon_incoming_object )
      ( name = `ICON_INCOMPLETE` value = icon_incomplete )
      ( name = `ICON_INCOMPLETION_LOG` value = icon_incompletion_log )
      ( name = `ICON_INFORMATION` value = icon_information )
      ( name = `ICON_INSERT_ROW` value = icon_insert_row )
      ( name = `ICON_INSPECTION_CHARACTERISTIC` value = icon_inspection_characteristic )
      ( name = `ICON_INSPECTION_LOT` value = icon_inspection_lot )
      ( name = `ICON_INSPECTION_METHOD` value = icon_inspection_method )
      ( name = `ICON_INTENSIFY` value = icon_intensify )
      ( name = `ICON_INTENSIFY_CRITICAL` value = icon_intensify_critical )
      ( name = `ICON_INTENSIFY_UNDO` value = icon_intensify_undo )
      ( name = `ICON_INTERFACE` value = icon_interface )
      ( name = `ICON_INTERVAL_INCLUDE_GREEN` value = icon_interval_include_green )
      ( name = `ICON_INTERVAL_INCLUDE_RED` value = icon_interval_include_red )
      ( name = `ICON_LED_GREEN` value = icon_led_green )
      ( name = `ICON_LED_INACTIVE` value = icon_led_inactive )
      ( name = `ICON_LED_RED` value = icon_led_red )
      ( name = `ICON_LED_YELLOW` value = icon_led_yellow )
      ( name = `ICON_LESS_EQUAL_GREEN` value = icon_less_equal_green )
      ( name = `ICON_LESS_GREEN` value = icon_less_green )
      ( name = `ICON_LIGHT_OUT` value = icon_light_out )
      ( name = `ICON_LIST` value = icon_list )
      ( name = `ICON_LOCATION` value = icon_location )
      ( name = `ICON_LOCKED` value = icon_locked )
      ( name = `ICON_MAIL` value = icon_mail )
      ( name = `ICON_MAPPED_RELATION` value = icon_mapped_relation )
      ( name = `ICON_MASS_CHANGE` value = icon_mass_change )
      ( name = `ICON_MASS_CHANGE_DONE` value = icon_mass_change_done )
      ( name = `ICON_MASTER_DATA_ACT` value = icon_master_data_act )
      ( name = `ICON_MATERIAL` value = icon_material )
      ( name = `ICON_MESSAGE_CRITICAL` value = icon_message_critical )
      ( name = `ICON_MESSAGE_CRITICAL_SMALL` value = icon_message_critical_small )
      ( name = `ICON_MESSAGE_ERROR` value = icon_message_error )
      ( name = `ICON_MESSAGE_ERROR_SMALL` value = icon_message_error_small )
      ( name = `ICON_MESSAGE_INFORMATION` value = icon_message_information )
      ( name = `ICON_MESSAGE_INFORMATION_SMALL` value = icon_message_information_small )
      ( name = `ICON_MESSAGE_QUESTION` value = icon_message_question )
      ( name = `ICON_MESSAGE_QUESTION_SMALL` value = icon_message_question_small )
      ( name = `ICON_MESSAGE_WARNING` value = icon_message_warning )
      ( name = `ICON_MESSAGE_WARNING_SMALL` value = icon_message_warning_small )
      ( name = `ICON_MODEL` value = icon_model )
      ( name = `ICON_MODIFICATION_CREATE` value = icon_modification_create )
      ( name = `ICON_MODIFICATION_OVERVIEW` value = icon_modification_overview )
      ( name = `ICON_MODIFY` value = icon_modify )
      ( name = `ICON_MONEY` value = icon_money )
      ( name = `ICON_MOVE` value = icon_move )
      ( name = `ICON_NEGATIVE` value = icon_negative )
      ( name = `ICON_NEW_TASK` value = icon_new_task )
      ( name = `ICON_NEXT_OBJECT` value = icon_next_object )
      ( name = `ICON_NO_STATUS` value = icon_no_status )
      ( name = `ICON_NOT_EQUAL_GREEN` value = icon_not_equal_green )
      ( name = `ICON_NOT_EQUAL_RED` value = icon_not_equal_red )
      ( name = `ICON_OBJECT_FOLDER` value = icon_object_folder )
      ( name = `ICON_OBJECT_LIST` value = icon_object_list )
      ( name = `ICON_OKAY` value = icon_okay )
      ( name = `ICON_OO_CLASS_EVENT` value = icon_oo_class_event )
      ( name = `ICON_OO_CONNECTION` value = icon_oo_connection )
      ( name = `ICON_OO_EVENT` value = icon_oo_event )
      ( name = `ICON_OO_INST_EVENT` value = icon_oo_inst_event )
      ( name = `ICON_OO_OBJECT` value = icon_oo_object )
      ( name = `ICON_OPEN` value = icon_open )
      ( name = `ICON_OPEN_FOLDER` value = icon_open_folder )
      ( name = `ICON_OPERATION` value = icon_operation )
      ( name = `ICON_ORDER` value = icon_order )
      ( name = `ICON_ORG_UNIT` value = icon_org_unit )
      ( name = `ICON_OTHER_OBJECT` value = icon_other_object )
      ( name = `ICON_OUTGOING_OBJECT` value = icon_outgoing_object )
      ( name = `ICON_OUTGOING_ORG_UNIT` value = icon_outgoing_org_unit )
      ( name = `ICON_OVERVIEW` value = icon_overview )
      ( name = `ICON_PACKAGE_APPLICATION` value = icon_package_application )
      ( name = `ICON_PACKAGE_STANDARD` value = icon_package_standard )
      ( name = `ICON_PACKING` value = icon_packing )
      ( name = `ICON_PAGE_LEFT` value = icon_page_left )
      ( name = `ICON_PAGE_RIGHT` value = icon_page_right )
      ( name = `ICON_PARAMETER_RESULT` value = icon_parameter_result )
      ( name = `ICON_PARTNER` value = icon_partner )
      ( name = `ICON_PATIENT_SMARTCARD` value = icon_patient_smartcard )
      ( name = `ICON_PATTERN_INCLUDE_GREEN` value = icon_pattern_include_green )
      ( name = `ICON_PATTERN_INCLUDE_RED` value = icon_pattern_include_red )
      ( name = `ICON_PDF` value = icon_pdf )
      ( name = `ICON_PDIR_BACK` value = icon_pdir_back )
      ( name = `ICON_PERSONAL_HELP` value = icon_personal_help )
      ( name = `ICON_PHYSICAL_SAMPLE` value = icon_physical_sample )
      ( name = `ICON_PLANT` value = icon_plant )
      ( name = `ICON_PM_INSERT` value = icon_pm_insert )
      ( name = `ICON_PM_PRESS` value = icon_pm_press )
      ( name = `ICON_POSITION` value = icon_position )
      ( name = `ICON_POSITION_HR` value = icon_position_hr )
      ( name = `ICON_POSITIVE` value = icon_positive )
      ( name = `ICON_PPE_SNODE` value = icon_ppe_snode )
      ( name = `ICON_PREVIOUS_OBJECT` value = icon_previous_object )
      ( name = `ICON_PRICE` value = icon_price )
      ( name = `ICON_PRICE_ANALYSIS` value = icon_price_analysis )
      ( name = `ICON_PRINT` value = icon_print )
      ( name = `ICON_PRINT_WITH_PARAMETERS` value = icon_print_with_parameters )
      ( name = `ICON_PRODUCT_GROUP` value = icon_product_group )
      ( name = `ICON_PROFIT_CENTER` value = icon_profit_center )
      ( name = `ICON_PROSHARE` value = icon_proshare )
      ( name = `ICON_PROTOCOL` value = icon_protocol )
      ( name = `ICON_PS_RELATIONSHIP` value = icon_ps_relationship )
      ( name = `ICON_PS_WBS_ELEMENT` value = icon_ps_wbs_element )
      ( name = `ICON_QUALIFY` value = icon_qualify )
      ( name = `ICON_QUESTION` value = icon_question )
      ( name = `ICON_RATING_MINUS` value = icon_rating_minus )
      ( name = `ICON_READ_FILE` value = icon_read_file )
      ( name = `ICON_RED_LIGHT` value = icon_red_light )
      ( name = `ICON_REFERENCE_LIST` value = icon_reference_list )
      ( name = `ICON_REFRESH` value = icon_refresh )
      ( name = `ICON_REJECT` value = icon_reject )
      ( name = `ICON_RELATION` value = icon_relation )
      ( name = `ICON_RELATIONSHIP` value = icon_relationship )
      ( name = `ICON_RELEASE` value = icon_release )
      ( name = `ICON_REMOVE_FROM_SELECTION` value = icon_remove_from_selection )
      ( name = `ICON_REMOVE_ROW` value = icon_remove_row )
      ( name = `ICON_REPLACE` value = icon_replace )
      ( name = `ICON_REPORT_TEMPLATE` value = icon_report_template )
      ( name = `ICON_RESUBMISSION` value = icon_resubmission )
      ( name = `ICON_RETAIL_STORE` value = icon_retail_store )
      ( name = `ICON_SAP` value = icon_sap )
      ( name = `ICON_SAP_SERVER` value = icon_sap_server )
      ( name = `ICON_SEARCH` value = icon_search )
      ( name = `ICON_SEARCH_NEXT` value = icon_search_next )
      ( name = `ICON_SELECT_ALL` value = icon_select_all )
      ( name = `ICON_SELECT_BLOCK` value = icon_select_block )
      ( name = `ICON_SELECT_DETAIL` value = icon_select_detail )
      ( name = `ICON_SELECTION` value = icon_selection )
      ( name = `ICON_SET_B` value = icon_set_b )
      ( name = `ICON_SET_COPY_IN_A` value = icon_set_copy_in_a )
      ( name = `ICON_SET_COPY_IN_B` value = icon_set_copy_in_b )
      ( name = `ICON_SET_STATE` value = icon_set_state )
      ( name = `ICON_SET_SUM` value = icon_set_sum )
      ( name = `ICON_SETTINGS` value = icon_settings )
      ( name = `ICON_SHARED_POSITION` value = icon_shared_position )
      ( name = `ICON_SHORT_MESSAGE` value = icon_short_message )
      ( name = `ICON_SHOW_EVENTS` value = icon_show_events )
      ( name = `ICON_SHOW_EXTERNAL_JOBS` value = icon_show_external_jobs )
      ( name = `ICON_SIMULATE` value = icon_simulate )
      ( name = `ICON_SKIP` value = icon_skip )
      ( name = `ICON_SPACE` value = icon_space )
      ( name = `ICON_SPOOL_REQUEST` value = icon_spool_request )
      ( name = `ICON_STACK` value = icon_stack )
      ( name = `ICON_STATISTICS` value = icon_statistics )
      ( name = `ICON_STATUS` value = icon_status )
      ( name = `ICON_STATUS_ALERT` value = icon_status_alert )
      ( name = `ICON_STATUS_BEST` value = icon_status_best )
      ( name = `ICON_STATUS_BOOKED` value = icon_status_booked )
      ( name = `ICON_STATUS_CRITICAL` value = icon_status_critical )
      ( name = `ICON_STATUS_OK` value = icon_status_ok )
      ( name = `ICON_STATUS_OPEN` value = icon_status_open )
      ( name = `ICON_STATUS_OVERVIEW` value = icon_status_overview )
      ( name = `ICON_STATUS_PARTLY_BOOKED` value = icon_status_partly_booked )
      ( name = `ICON_STATUS_REVERSE` value = icon_status_reverse )
      ( name = `ICON_STOCK` value = icon_stock )
      ( name = `ICON_STORE` value = icon_store )
      ( name = `ICON_STORE_LOCATION` value = icon_store_location )
      ( name = `ICON_STORNO` value = icon_storno )
      ( name = `ICON_STRUCTURE` value = icon_structure )
      ( name = `ICON_SUBMIT` value = icon_submit )
      ( name = `ICON_SYM_LOG_SERVER` value = icon_sym_log_server )
      ( name = `ICON_SYSTEM_BACK` value = icon_system_back )
      ( name = `ICON_SYSTEM_CANCEL` value = icon_system_cancel )
      ( name = `ICON_SYSTEM_COPY` value = icon_system_copy )
      ( name = `ICON_SYSTEM_END` value = icon_system_end )
      ( name = `ICON_SYSTEM_EXTENDED_HELP` value = icon_system_extended_help )
      ( name = `ICON_SYSTEM_FAVORITES` value = icon_system_favorites )
      ( name = `ICON_SYSTEM_HELP` value = icon_system_help )
      ( name = `ICON_SYSTEM_LOCAL_COPY` value = icon_system_local_copy )
      ( name = `ICON_SYSTEM_LOCAL_PASTE` value = icon_system_local_paste )
      ( name = `ICON_SYSTEM_OKAY` value = icon_system_okay )
      ( name = `ICON_SYSTEM_PASTE` value = icon_system_paste )
      ( name = `ICON_SYSTEM_PLAY` value = icon_system_play )
      ( name = `ICON_SYSTEM_POSSIBLE_ENTRIES` value = icon_system_possible_entries )
      ( name = `ICON_SYSTEM_SAVE` value = icon_system_save )
      ( name = `ICON_SYSTEM_SHORTCUT` value = icon_system_shortcut )
      ( name = `ICON_SYSTEM_UNDO` value = icon_system_undo )
      ( name = `ICON_TARGET_GROUP` value = icon_target_group )
      ( name = `ICON_TASK` value = icon_task )
      ( name = `ICON_TBH_HOLD` value = icon_tbh_hold )
      ( name = `ICON_TE_ADVANCE_PAYMENT` value = icon_te_advance_payment )
      ( name = `ICON_TERMINATED_ORG_UNIT` value = icon_terminated_org_unit )
      ( name = `ICON_TEST` value = icon_test )
      ( name = `ICON_TEXT_ACT` value = icon_text_act )
      ( name = `ICON_TEXT_FIELD` value = icon_text_field )
      ( name = `ICON_TEXT_INA` value = icon_text_ina )
      ( name = `ICON_TIME` value = icon_time )
      ( name = `ICON_TOGGLE_DISPLAY` value = icon_toggle_display )
      ( name = `ICON_TOGGLE_DISPLAY_CHANGE` value = icon_toggle_display_change )
      ( name = `ICON_TOOLS` value = icon_tools )
      ( name = `ICON_TOTAL_LEFT` value = icon_total_left )
      ( name = `ICON_TRANSFER` value = icon_transfer )
      ( name = `ICON_TRANSFER_STRUCTURE` value = icon_transfer_structure )
      ( name = `ICON_TRANSFER_STRUCTURE_INA` value = icon_transfer_structure_ina )
      ( name = `ICON_TRANSPORT` value = icon_transport )
      ( name = `ICON_TRANSPORT_POINT` value = icon_transport_point )
      ( name = `ICON_TREE` value = icon_tree )
      ( name = `ICON_TREND_DECREASING` value = icon_trend_decreasing )
      ( name = `ICON_TREND_DOWN` value = icon_trend_down )
      ( name = `ICON_TREND_RISING` value = icon_trend_rising )
      ( name = `ICON_TREND_UNCHANGED` value = icon_trend_unchanged )
      ( name = `ICON_TREND_UP` value = icon_trend_up )
      ( name = `ICON_UNLOCKED` value = icon_unlocked )
      ( name = `ICON_UNPACK` value = icon_unpack )
      ( name = `ICON_UNSPECIFIED_FOUR` value = icon_unspecified_four )
      ( name = `ICON_UNSPECIFIED_ONE` value = icon_unspecified_one )
      ( name = `ICON_UNSPECIFIED_THREE` value = icon_unspecified_three )
      ( name = `ICON_UNSPECIFIED_TWO` value = icon_unspecified_two )
      ( name = `ICON_USERGROUP` value = icon_usergroup )
      ( name = `ICON_VARIABLE` value = icon_variable )
      ( name = `ICON_VIDEO` value = icon_video )
      ( name = `ICON_VIEWER_OPTICAL_ARCHIVE` value = icon_viewer_optical_archive )
      ( name = `ICON_WAREHOUSE` value = icon_warehouse )
      ( name = `ICON_WARNING` value = icon_warning )
      ( name = `ICON_WD_CONTEXT` value = icon_wd_context )
      ( name = `ICON_WD_IFRAME` value = icon_wd_iframe )
      ( name = `ICON_WD_TABLE` value = icon_wd_table )
      ( name = `ICON_WD_VIEW` value = icon_wd_view )
      ( name = `ICON_WD_VIEW_AREA` value = icon_wd_view_area )
      ( name = `ICON_WF_LINK` value = icon_wf_link )
      ( name = `ICON_WF_UNLINK` value = icon_wf_unlink )
      ( name = `ICON_WF_WORKITEM_COMPLETED` value = icon_wf_workitem_completed )
      ( name = `ICON_WF_WORKITEM_ERROR` value = icon_wf_workitem_error )
      ( name = `ICON_WF_WORKITEM_OL` value = icon_wf_workitem_ol )
      ( name = `ICON_WIZARD` value = icon_wizard )
      ( name = `ICON_WORKFLOW_ACTIVITY` value = icon_workflow_activity )
      ( name = `ICON_WORKING_PLAN` value = icon_working_plan )
      ( name = `ICON_WS_START_WHSE_PROC_BACKGR` value = icon_ws_start_whse_proc_backgr )
      ( name = `ICON_WS_TRUCK` value = icon_ws_truck )
      ( name = `ICON_XLS` value = icon_xls )
      ( name = `ICON_XML_DOC` value = icon_xml_doc )
      ( name = `ICON_YELLOW_LIGHT` value = icon_yellow_light ) ).
    LOOP AT lt_constants INTO DATA(ls_constant).
      DATA(ls_icon) = zcl_gg_host_icons=>resolve( ls_constant-value ).
      cl_abap_unit_assert=>assert_not_initial( act = ls_icon-symbol
                                               msg = ls_constant-name ).
      cl_abap_unit_assert=>assert_differs( exp = `square-dashed`
                                           act = ls_icon-symbol
                                           msg = ls_constant-name ).
* Only the blank placeholders, ICON_DUMMY and ICON_SPACE, go without a label.
      IF ls_icon-symbol <> `blank`.
        cl_abap_unit_assert=>assert_not_initial( act = ls_icon-label
                                                 msg = ls_constant-name ).
      ENDIF.
      cl_abap_unit_assert=>assert_equals( exp = ls_icon-symbol
                                          act = zcl_gg_host_icons=>resolve( ls_constant-name )-symbol
                                          msg = ls_constant-name ).
      cl_abap_unit_assert=>assert_true( act = xsdbool( lv_sprite CS |<symbol id="wb-icon-{ ls_icon-symbol }"| )
                                        msg = ls_constant-name ).
    ENDLOOP.

* The constants the type pool has no value for yet resolve by their name.
    DATA(lt_names) = VALUE string_table(
      ( `ICON_ACTIVE_INACTIVE` )
      ( `ICON_AVAILABILITY_CHECK` )
      ( `ICON_INCLUDE_IN_SELECTION` )
      ( `ICON_SUPPLIER` )
      ( `ICON_VAL_QUANTITY_STRUCTURE` ) ).
    LOOP AT lt_names INTO DATA(lv_name).
      ls_icon = zcl_gg_host_icons=>resolve( lv_name ).
      cl_abap_unit_assert=>assert_not_initial( act = ls_icon-symbol
                                               msg = lv_name ).
      cl_abap_unit_assert=>assert_true( act = xsdbool( lv_sprite CS |<symbol id="wb-icon-{ ls_icon-symbol }"| )
                                        msg = lv_name ).
    ENDLOOP.
  ENDMETHOD.

  METHOD prunes_unused_symbols.
    DATA(lv_sprite) = zcl_gg_host_icons=>sprite( ).
    DATA(lv_page) = |<body>{ lv_sprite }<p>{ zcl_gg_host_icons=>icon( 'open_folder' ) }</p>|
      && |<script>var x='<svg><use href="#wb-icon-truck"></use></svg>';</script></body>|.

    DATA(lv_pruned) = zcl_gg_host_icons=>prune_sprite( lv_page ).
* Referenced symbols stay, the rest go; a longer id does not keep its prefix.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_pruned CS '<symbol id="wb-icon-folder-open"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_pruned CS '<symbol id="wb-icon-truck"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_pruned CS '<symbol id="wb-icon-folder"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_pruned CS '<symbol id="wb-icon-shopping-bag"' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = count( val = lv_pruned
                                                     sub = '<symbol ' ) ).
* Everything outside the dropped symbols is left as it was.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_pruned CS '<svg class="wb-icon-sprite" aria-hidden="true" focusable="false" xmlns="http://www.w3.org/2000/svg"><symbol' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_pruned CS |</symbol></svg><p>{ zcl_gg_host_icons=>icon( 'open_folder' ) }</p><script>| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `<p>no icons</p>`
                                        act = zcl_gg_host_icons=>prune_sprite( `<p>no icons</p>` ) ).
* Line breaks, as a text editor holds them, survive the pruning.
    lv_page = |{ lv_sprite }<textarea>First line\nSecond line</textarea>{ zcl_gg_host_icons=>icon( 'open_folder' ) }<p>end</p>|.
    lv_pruned = zcl_gg_host_icons=>prune_sprite( lv_page ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_pruned CS |<textarea>First line\nSecond line</textarea>| ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_pruned CS `<p>end</p>` ) ).
  ENDMETHOD.

ENDCLASS.
