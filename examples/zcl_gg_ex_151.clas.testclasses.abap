CLASS ltcl_ex_151 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS renders_home_in_the_viewer FOR TESTING.
    METHODS rewrites_sapevent_anchors FOR TESTING.
    METHODS opens_a_repository_page FOR TESTING.
    METHODS stages_and_re_renders FOR TESTING.
    METHODS steps_back_to_the_overview FOR TESTING.
    METHODS rejects_an_undeclared_command FOR TESTING.

    METHODS command
      IMPORTING
        iv_session_id      TYPE string
        iv_page_id         TYPE string
        iv_ucomm           TYPE string
      RETURNING
        VALUE(rs_response) TYPE zif_gg_host_html_v1=>ty_response.

ENDCLASS.

CLASS ltcl_ex_151 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_151( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).

    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode
                                        exp = 'ZGG_EX_151' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD renders_home_in_the_viewer.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_151( ) ).

* The whole UI is the control: one sandboxed iframe, no list lines behind it.
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'title="HTML viewer"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'DOCKING_CONTAINER' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '$ZDEMO_ALPHA' ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-status-status
                                        exp = 'OVERVIEW' ).
    cl_abap_unit_assert=>assert_initial( act = ls_result-render_lines ).
  ENDMETHOD.

  METHOD rewrites_sapevent_anchors.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_151( ) ).

* The document keeps abapGit's sapevent anchors. The host turns each one into
* a form posting the dispatch the rest of the page posts to, and relaxes the
* sandbox by exactly the two tokens that takes.
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS
      'sandbox="allow-forms allow-top-navigation-by-user-activation"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS
      'action=&quot;/dispatch&quot; target=&quot;_top&quot;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS
      'name=&quot;ucomm&quot; value=&quot;OPEN_BETA&quot;' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS 'sapevent:' ) ).
  ENDMETHOD.

  METHOD opens_a_repository_page.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_151( ) ).
    DATA(ls_open) = command( iv_session_id = ls_start-session_id
                             iv_page_id    = ls_start-page_id
                             iv_ucomm      = 'OPEN_BETA' ).

    cl_abap_unit_assert=>assert_true( act = ls_open-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_open-current_page-status-status
                                        exp = 'REPOSITORY' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_open-html CS '$ZDEMO_BETA' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_open-html CS 'release' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_open-html CS 'not staged' ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD stages_and_re_renders.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_151( ) ).
    DATA(ls_open) = command( iv_session_id = ls_start-session_id
                             iv_page_id    = ls_start-page_id
                             iv_ucomm      = 'OPEN_BETA' ).
    DATA(ls_staged) = command( iv_session_id = ls_open-session_id
                               iv_page_id    = ls_open-page_id
                               iv_ucomm      = 'STAGE' ).

    cl_abap_unit_assert=>assert_true( act = ls_staged-valid ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_staged-html CS 'Staging' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_staged-html CS 'not staged' ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD steps_back_to_the_overview.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_151( ) ).
    DATA(ls_open) = command( iv_session_id = ls_start-session_id
                             iv_page_id    = ls_start-page_id
                             iv_ucomm      = 'OPEN_BETA' ).
    DATA(ls_back) = command( iv_session_id = ls_open-session_id
                             iv_page_id    = ls_open-page_id
                             iv_ucomm      = 'GO_BACK' ).

    cl_abap_unit_assert=>assert_true( act = ls_back-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_back-current_page-status-status
                                        exp = 'OVERVIEW' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_back-html CS '$ZDEMO_GAMMA' ) ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD rejects_an_undeclared_command.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_151( ) ).
    DATA(ls_open) = command( iv_session_id = ls_start-session_id
                             iv_page_id    = ls_start-page_id
                             iv_ucomm      = 'OPEN_BETA' ).

* The repository page declares Stage, Refresh and Back, so the actions of the
* overview are no longer accepted while it is the current page.
    DATA(ls_rejected) = command( iv_session_id = ls_open-session_id
                                 iv_page_id    = ls_open-page_id
                                 iv_ucomm      = 'OPEN_ALPHA' ).

    cl_abap_unit_assert=>assert_false( act = ls_rejected-valid ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_rejected-error
      exp = 'Command is not active for the current host page' ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

  METHOD command.
    rs_response = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id = iv_session_id
      page_id    = iv_page_id
      action     = zif_gg_host_html_v1=>action_command
      ucomm      = iv_ucomm ) ).
  ENDMETHOD.

ENDCLASS.
