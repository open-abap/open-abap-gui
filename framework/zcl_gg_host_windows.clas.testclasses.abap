CLASS ltcl_windows DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    METHODS keeps_gui_state_per_window FOR TESTING.
    METHODS numbers_new_windows FOR TESTING.
    METHODS keeps_last_window FOR TESTING.
    METHODS no_window_swaps_nothing FOR TESTING.
    METHODS normalizes_window_names FOR TESTING.
    METHODS keeps_last_window_per_shell FOR TESTING.
    METHODS script_names_the_window FOR TESTING.
    METHODS shell_ids_are_not_reused FOR TESTING.
    METHODS ends_the_whole_shell FOR TESTING.

ENDCLASS.

CLASS ltcl_windows IMPLEMENTATION.

  METHOD teardown.
    zcl_gg_host_windows=>clear( ).
    zcl_gg_host_runtime=>restore_gui_state( ).
  ENDMETHOD.

* What a program shows in one GUI session stays there when another session
* runs, and is back when the first one does.
  METHOD keeps_gui_state_per_window.
    zcl_gg_host_windows=>enter( `W0` ).
    zcl_gg_gui_runtime=>set_external_html( `<p>first</p>` ).
    cl_abap_unit_assert=>assert_true( act = zcl_gg_gui_runtime=>has_content( ) ).

    DATA(lv_second) = zcl_gg_host_windows=>open( ).
    cl_abap_unit_assert=>assert_false( act = zcl_gg_gui_runtime=>has_content( ) ).

    zcl_gg_host_windows=>enter( `W0` ).
    cl_abap_unit_assert=>assert_true( act = zcl_gg_gui_runtime=>has_content( ) ).

    zcl_gg_host_windows=>enter( lv_second ).
    cl_abap_unit_assert=>assert_false( act = zcl_gg_gui_runtime=>has_content( ) ).
  ENDMETHOD.

  METHOD numbers_new_windows.
    zcl_gg_host_windows=>enter( `W0` ).
    cl_abap_unit_assert=>assert_true( act = zcl_gg_host_windows=>enabled( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>open( )
      exp = `W1` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>current( )
      exp = `W1` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>open( )
      exp = `W2` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>count( )
      exp = 3 ).
  ENDMETHOD.

  METHOD keeps_last_window.
    zcl_gg_host_windows=>enter( `W0` ).
    DATA(lv_second) = zcl_gg_host_windows=>open( ).
    cl_abap_unit_assert=>assert_initial( act = zcl_gg_host_windows=>end( lv_second ) ).
    cl_abap_unit_assert=>assert_initial( act = zcl_gg_host_windows=>current( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>total( )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>end( `W0` )
      exp = 'The last session cannot be ended.' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>total( )
      exp = 1 ).
  ENDMETHOD.

* Two browser tabs each run a shell; each keeps its own last window, however
* many the other has.
  METHOD keeps_last_window_per_shell.
    DATA(lv_first_tab) = zcl_gg_host_windows=>open( iv_own_shell = abap_true ).
    DATA(lv_second_tab) = zcl_gg_host_windows=>open( iv_own_shell = abap_true ).
    DATA(lv_second_tab_more) = zcl_gg_host_windows=>open( ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>count( )
      exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>total( )
      exp = 3 ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>end( lv_first_tab )
      exp = 'The last session cannot be ended.' ).
    cl_abap_unit_assert=>assert_initial( act = zcl_gg_host_windows=>end( lv_second_tab ) ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>end( lv_second_tab_more )
      exp = 'The last session cannot be ended.' ).
  ENDMETHOD.

* A tab that enters a window name again after it ended starts a shell of its
* own; it does not join the windows the ended one opened.
  METHOD shell_ids_are_not_reused.
    zcl_gg_host_windows=>enter( `W0` ).
    DATA(lv_second) = zcl_gg_host_windows=>open( ).
    zcl_gg_host_windows=>enter( `W0` ).
    cl_abap_unit_assert=>assert_initial( act = zcl_gg_host_windows=>end( `W0` ) ).

    zcl_gg_host_windows=>enter( `W0` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>count( )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>end( `W0` )
      exp = 'The last session cannot be ended.' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>end( lv_second )
      exp = 'The last session cannot be ended.' ).
  ENDMETHOD.

* A shell closed or reloaded takes all its windows along, and no other's.
  METHOD ends_the_whole_shell.
    DATA(lv_first_tab) = zcl_gg_host_windows=>open( iv_own_shell = abap_true ).
    DATA(lv_second_tab) = zcl_gg_host_windows=>open( iv_own_shell = abap_true ).
    zcl_gg_host_windows=>open( ).
    zcl_gg_gui_runtime=>set_external_html( `<p>second tab</p>` ).
    zcl_gg_host_windows=>end_shell( lv_second_tab ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>total( )
      exp = 1 ).
    cl_abap_unit_assert=>assert_initial( act = zcl_gg_host_windows=>current( ) ).
    cl_abap_unit_assert=>assert_false( act = zcl_gg_gui_runtime=>has_content( ) ).
    zcl_gg_host_windows=>enter( lv_first_tab ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>count( )
      exp = 1 ).
  ENDMETHOD.

* The name a request sends goes into the page script, so only a plain name is
* taken; anything else, or none, is the first window.
  METHOD normalizes_window_names.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>normalize( `W3` )
      exp = `W3` ).
    DATA(lv_long) = repeat( val = `W`
                            occ = 33 ).
    LOOP AT VALUE string_table( ( `` ) ( `W1"><script>` ) ( `W 1` ) ( lv_long ) ) INTO DATA(lv_name).
      cl_abap_unit_assert=>assert_equals(
        act = zcl_gg_host_windows=>normalize( lv_name )
        exp = zcl_gg_host_windows=>c_first_window ).
    ENDLOOP.
  ENDMETHOD.

  METHOD script_names_the_window.
    cl_abap_unit_assert=>assert_initial( act = zcl_gg_host_windows=>script( ) ).
    zcl_gg_host_windows=>enter( `W2` ).
    DATA(lv_html) = zcl_gg_host_windows=>script( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<meta name="gg-window" content="W2">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'var id="W2";var name="gg_window";' ) ).
  ENDMETHOD.

* A host without the shell names no window; its GUI state stays as it is.
  METHOD no_window_swaps_nothing.
    zcl_gg_host_windows=>enter( `` ).
    zcl_gg_gui_runtime=>set_external_html( `<p>only</p>` ).
    zcl_gg_host_windows=>enter( `` ).
    cl_abap_unit_assert=>assert_false( act = zcl_gg_host_windows=>enabled( ) ).
    cl_abap_unit_assert=>assert_true( act = zcl_gg_gui_runtime=>has_content( ) ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_host_windows=>count( )
      exp = 0 ).
  ENDMETHOD.

ENDCLASS.
