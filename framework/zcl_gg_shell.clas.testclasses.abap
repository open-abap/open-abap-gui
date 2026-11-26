CLASS ltcl_shell DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS renders_rail_and_frames FOR TESTING.

ENDCLASS.

CLASS ltcl_shell IMPLEMENTATION.

* The shell is a page of its own: the rail, the place for the session frames,
* and the script that asks the host for its first session.
  METHOD renders_rail_and_frames.
    DATA(lv_html) = zcl_gg_shell=>render( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CP '<!doctype html>*</html>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<nav id="gg-rail" aria-label="Sessions">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<ol id="gg-rail-list"></ol>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<div id="gg-frames"></div>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'var NEW_WINDOW = "new";' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '"x-gg-window": session.window' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'gg-window" content=' ) ).
* The first session opens on the route in the hash, which must be a path of this host.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'request(first, hashRoute());' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'return /^\/(?!\/)/.test(value) ? value : "/";' ) ).
  ENDMETHOD.

ENDCLASS.
