CLASS ltcl_ex_14 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    METHODS stops_before_following_write FOR TESTING.
    METHODS runtime_shows_the_list FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_14 IMPLEMENTATION.

  METHOD teardown.
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD stops_before_following_write.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_014( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `before` )
        ( `end` ) ) ).
  ENDMETHOD.

* Started as from the workbench, STOP goes on to END-OF-SELECTION as well:
* the first page is the list, not a step to continue from.
  METHOD runtime_shows_the_list.
    DATA(ls_response) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_014( ) ).

    cl_abap_unit_assert=>assert_true( act = ls_response-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_response-page_kind
                                        exp = zif_gg_host_html_v1=>page_list ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_response-compatibility-lines
      exp = VALUE string_table( ( `before` ) ( `end` ) ) ).
  ENDMETHOD.

ENDCLASS.
