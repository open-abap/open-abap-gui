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

ENDCLASS.
