CLASS ltcl_ex_63 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS accepts_pf5_rejects_pf6 FOR TESTING.
ENDCLASS.
CLASS ltcl_ex_63 IMPLEMENTATION.
  METHOD accepts_pf5_rejects_pf6.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_063( ) ).
    DATA(ls_bad) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id page_id = ls_start-page_id
      action = zif_gg_host_html_v1=>action_pf pf_key = 6 ) ).
    cl_abap_unit_assert=>assert_false( ls_bad-valid ).
    DATA(ls_good) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = ls_start-session_id page_id = ls_start-page_id
      action = zif_gg_host_html_v1=>action_pf pf_key = 5 ) ).
    cl_abap_unit_assert=>assert_true( ls_good-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_good-compatibility-lines[ 2 ]
                                        exp = 'pf5' ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.
ENDCLASS.
