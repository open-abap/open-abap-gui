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

    TYPES: BEGIN OF ty_expected,
             code   TYPE string,
             name   TYPE string,
             symbol TYPE string,
             tone   TYPE string,
             label  TYPE string,
           END OF ty_expected.
    TYPES ty_expected_table TYPE STANDARD TABLE OF ty_expected WITH DEFAULT KEY.

* The codes, ICON_* names and English quick info texts of the SAP ICON table.
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

ENDCLASS.
