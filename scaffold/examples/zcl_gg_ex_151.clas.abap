CLASS zcl_gg_ex_151 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 151, one full-screen cl_gui_html_viewer carrying the whole program
* UI, arranged the way ZCL_ABAPGIT_GUI arranges abapGit: a stack of pages, one
* complete HTML document rendered per page, and an event handler that answers
* an action with a new page, a re-render, or a step back.
*
* abapGit reaches its viewer through sapevent, the anchor scheme the SAP GUI
* HTML control turns back into an ABAP event, and startup registers that event
* here the same way. A browser cannot turn an anchor into an ABAP event, so the
* host rewrites every registered sapevent anchor into a form posting to its own
* dispatch, and the action arrives as a function code in at_user_command. Both
* routes end in the one handle_action the sapevent handler also uses.
*
* The status still declares each action, so the host rejects a function code
* the current page never offered, whether it came from an anchor or a button.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.
    INTERFACES zif_gg_list_processing_v1.

  PRIVATE SECTION.
* The event states of ZCL_ABAPGIT_GUI, reduced to the ones this example needs.
    CONSTANTS:
      BEGIN OF c_event_state,
        not_handled TYPE i VALUE 0,
        re_render   TYPE i VALUE 1,
        new_page    TYPE i VALUE 2,
        go_back     TYPE i VALUE 3,
      END OF c_event_state.

* abapGit names every action once and both the renderer and the router use
* that name. Here the same constants are the function codes the list status
* declares, so an action nobody declared is rejected by the host.
    CONSTANTS:
      BEGIN OF c_action,
        open_alpha TYPE zif_gg_session_types_v1=>ty_ucomm VALUE 'OPEN_ALPHA',
        open_beta  TYPE zif_gg_session_types_v1=>ty_ucomm VALUE 'OPEN_BETA',
        open_gamma TYPE zif_gg_session_types_v1=>ty_ucomm VALUE 'OPEN_GAMMA',
        stage      TYPE zif_gg_session_types_v1=>ty_ucomm VALUE 'STAGE',
        refresh    TYPE zif_gg_session_types_v1=>ty_ucomm VALUE 'REFRESH',
        go_back    TYPE zif_gg_session_types_v1=>ty_ucomm VALUE 'GO_BACK',
      END OF c_action.

    CONSTANTS c_page_home TYPE string VALUE 'HOME'.
    CONSTANTS c_page_repo TYPE string VALUE 'REPO'.
    CONSTANTS c_viewer_width TYPE i VALUE 960.
    CONSTANTS c_viewer_height TYPE i VALUE 540.

    TYPES: BEGIN OF ty_repository,
             ucomm   TYPE zif_gg_session_types_v1=>ty_ucomm,
             name    TYPE string,
             branch  TYPE string,
             objects TYPE i,
           END OF ty_repository.
    TYPES ty_repositories TYPE STANDARD TABLE OF ty_repository WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_page,
             name TYPE string,
             repo TYPE zif_gg_session_types_v1=>ty_ucomm,
           END OF ty_page.
    TYPES ty_page_stack TYPE STANDARD TABLE OF ty_page WITH DEFAULT KEY.

* The result of routing one action, as zif_abapgit_gui_event_handler returns it.
    TYPES: BEGIN OF ty_handling_result,
             state TYPE i,
             page  TYPE ty_page,
           END OF ty_handling_result.

    DATA mo_shell TYPE REF TO cl_gui_docking_container.
    DATA mo_viewer TYPE REF TO cl_gui_html_viewer.
    DATA ms_cur_page TYPE ty_page.
    DATA mt_stack TYPE ty_page_stack.
    DATA mv_staged TYPE abap_bool.
* abapGit keeps its GUI services on the instance because sapevent arrives
* without them. The host passes the execution session into every event, so the
* current one is kept here for the sapevent path to use.
    DATA mo_session TYPE REF TO zif_gg_session_v1.

    METHODS startup.

    METHODS shell_is_alive
      RETURNING
        VALUE(rv_alive) TYPE abap_bool.

    METHODS on_sapevent
      FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING
        action.

    METHODS handle_action
      IMPORTING
        iv_action TYPE clike.

    METHODS route
      IMPORTING
        iv_action         TYPE clike
      RETURNING
        VALUE(rs_handled) TYPE ty_handling_result.

    METHODS call_page
      IMPORTING
        is_page TYPE ty_page.

    METHODS back.

    METHODS render.

    METHODS publish_status.

    METHODS render_home
      RETURNING
        VALUE(rv_html) TYPE string.

    METHODS render_repository
      RETURNING
        VALUE(rv_html) TYPE string.

    METHODS page_document
      IMPORTING
        iv_title       TYPE string
        iv_body        TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    "! One sapevent anchor, the way zcl_abapgit_html builds them.
    CLASS-METHODS sapevent
      IMPORTING
        iv_action      TYPE clike
        iv_label       TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    METHODS repositories
      RETURNING
        VALUE(rt_repositories) TYPE ty_repositories.
ENDCLASS.

CLASS zcl_gg_ex_151 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode       = 'ZGG_EX_151'
                              description = 'Full-screen HTML viewer shell' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    mo_session = io_session.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_151 HTML viewer shell' ).
    startup( ).
    render( ).
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_user_command.
    mo_session = io_session.
    handle_action( iv_ucomm ).
  ENDMETHOD.

  METHOD on_sapevent.
* The path a real SAP GUI takes: the control turns a sapevent anchor back into
* this event and the action reaches the same router as a declared command.
    handle_action( action ).
  ENDMETHOD.

  METHOD startup.
    DATA lt_events TYPE cntl_simple_events.

* abapGit builds the viewer once, in the GUI constructor. The HTML host runs
* the program again for every request and empties the control registry first,
* so the shell is rebuilt whenever the previous one is gone.
    IF shell_is_alive( ) = abap_true.
      RETURN.
    ENDIF.

* abapGit docks its viewer on the whole dynpro screen, cl_gui_container=>screen0.
* A report without a dynpro of its own gets the same surface from a docking
* container whose extension is wider than any screen, so nothing is left beside
* it. Only the viewer is given a size, as abapGit leaves the container alone.
    mo_shell = NEW cl_gui_docking_container(
      side      = cl_gui_docking_container=>dock_at_left
      extension = 9999
      caption   = 'open-abap workbench' ).

    mo_viewer = NEW cl_gui_html_viewer( parent               = mo_shell
                                        query_table_disabled = abap_true ).
    mo_viewer->set_position( left   = 0
                             top    = 0
                             width  = c_viewer_width
                             height = c_viewer_height ).

    APPEND VALUE #( eventid    = cl_gui_html_viewer=>m_id_sapevent
                    appl_event = abap_true ) TO lt_events.
    mo_viewer->set_registered_events( lt_events ).
    SET HANDLER on_sapevent FOR mo_viewer.

    IF ms_cur_page-name IS INITIAL.
      ms_cur_page = VALUE #( name = c_page_home ).
    ENDIF.
  ENDMETHOD.

  METHOD shell_is_alive.
    DATA lt_snapshots TYPE cl_gui_control=>ty_snapshots.

    IF mo_viewer IS NOT BOUND.
      RETURN.
    ENDIF.
    lt_snapshots = cl_gui_control=>get_snapshots( ).
    READ TABLE lt_snapshots TRANSPORTING NO FIELDS
      WITH KEY control_id = mo_viewer->control_id.
    rv_alive = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD handle_action.
    DATA ls_handled TYPE ty_handling_result.

    ls_handled = route( iv_action ).
    CASE ls_handled-state.
      WHEN c_event_state-re_render.
        render( ).
      WHEN c_event_state-new_page.
        call_page( ls_handled-page ).
      WHEN c_event_state-go_back.
        back( ).
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD route.
    DATA lv_action TYPE zif_gg_session_types_v1=>ty_ucomm.
    DATA lt_repositories TYPE ty_repositories.
    DATA ls_repository TYPE ty_repository.

    lv_action = iv_action.
    rs_handled-state = c_event_state-not_handled.
    CASE lv_action.
      WHEN c_action-go_back.
        rs_handled-state = c_event_state-go_back.
      WHEN c_action-stage.
        mv_staged = abap_true.
        rs_handled-state = c_event_state-re_render.
      WHEN c_action-refresh.
        rs_handled-state = c_event_state-re_render.
      WHEN OTHERS.
        lt_repositories = repositories( ).
        READ TABLE lt_repositories INTO ls_repository WITH KEY ucomm = lv_action.
        IF sy-subrc = 0.
          rs_handled-state = c_event_state-new_page.
          rs_handled-page = VALUE #( name = c_page_repo
                                     repo = ls_repository-ucomm ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD call_page.
    APPEND ms_cur_page TO mt_stack.
    ms_cur_page = is_page.
    render( ).
  ENDMETHOD.

  METHOD back.
    DATA lv_index TYPE i.

    lv_index = lines( mt_stack ).
    IF lv_index > 0.
      READ TABLE mt_stack INTO ms_cur_page INDEX lv_index.
      DELETE mt_stack INDEX lv_index.
    ENDIF.
* abapGit reports an empty stack as an exit and leaves the program. Leaving the
* transaction belongs to the host here, so the first page just renders again.
    render( ).
  ENDMETHOD.

  METHOD render.
    DATA lt_document TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lv_document TYPE string.

    IF ms_cur_page-name = c_page_repo.
      lv_document = render_repository( ).
    ELSE.
      lv_document = render_home( ).
    ENDIF.
    publish_status( ).

* abapGit caches every rendered document as an asset and shows the viewer its
* URL. load_data adds to the document the control already holds, so the page
* being replaced is closed before the next one is loaded.
    APPEND lv_document TO lt_document.
    mo_viewer->close_document( ).
    mo_viewer->load_data( CHANGING data_table = lt_document ).
  ENDMETHOD.

  METHOD publish_status.
    DATA ls_status TYPE zif_gg_session_types_v1=>ty_gui_status.
    DATA lt_breadcrumbs TYPE zif_gg_session_types_v1=>ty_breadcrumbs.
    DATA lt_repositories TYPE ty_repositories.
    DATA ls_repository TYPE ty_repository.

    IF mo_session IS NOT BOUND.
      RETURN.
    ENDIF.

    APPEND VALUE #( label   = 'Repositories'
                    target  = c_page_home
                    current = xsdbool( ms_cur_page-name = c_page_home ) )
      TO lt_breadcrumbs.

    IF ms_cur_page-name = c_page_repo.
      lt_repositories = repositories( ).
      READ TABLE lt_repositories INTO ls_repository
        WITH KEY ucomm = ms_cur_page-repo.
      APPEND VALUE #( label   = ls_repository-name
                      target  = c_page_repo
                      current = abap_true ) TO lt_breadcrumbs.
      ls_status = VALUE #(
        status       = 'REPOSITORY'
        active_ucomm = VALUE #( ( c_action-stage ) ( c_action-refresh ) ( c_action-go_back ) )
        icon_bar     = VALUE #(
          ( ucomm = c_action-stage label = 'Stage changes' icon = 'save' )
          ( ucomm = c_action-refresh label = 'Refresh page' icon = 'refresh' )
          ( ucomm     = c_action-go_back
            label     = 'Back to repositories'
            icon      = 'arrow-left'
            separator = abap_true ) ) ).
    ELSE.
      ls_status = VALUE #( status       = 'OVERVIEW'
                           active_ucomm = VALUE #( ( c_action-refresh ) )
                           icon_bar     = VALUE #( ( ucomm = c_action-refresh
                                                     label = 'Refresh page'
                                                     icon  = 'refresh' ) ) ).
      lt_repositories = repositories( ).
      LOOP AT lt_repositories INTO ls_repository.
        APPEND ls_repository-ucomm TO ls_status-active_ucomm.
        APPEND VALUE #( ucomm = ls_repository-ucomm
                        label = |Open { ls_repository-name }|
                        icon  = 'folder' ) TO ls_status-icon_bar.
      ENDLOOP.
    ENDIF.

    mo_session->get_list( )->set_status( ls_status ).
    mo_session->get_list( )->set_breadcrumbs( lt_breadcrumbs ).
  ENDMETHOD.

  METHOD render_home.
    DATA lt_repositories TYPE ty_repositories.
    DATA ls_repository TYPE ty_repository.
    DATA lv_rows TYPE string.

    lt_repositories = repositories( ).
    LOOP AT lt_repositories INTO ls_repository.
* One sapevent anchor per row, exactly where abapGit puts it.
      lv_rows = lv_rows &&
        |<tr><th scope="row">{ sapevent( iv_action = ls_repository-ucomm
                                         iv_label  = ls_repository-name ) }</th>| &&
        |<td>{ cl_gui_control=>escape_html( ls_repository-branch ) }</td>| &&
        |<td>{ ls_repository-objects }</td></tr>|.
    ENDLOOP.

    rv_html = page_document(
      iv_title = 'Repositories'
      iv_body  = |<table><caption>Repositories of this example</caption>| &&
                 |<thead><tr><th scope="col">Package</th>| &&
                 |<th scope="col">Branch</th><th scope="col">Objects</th></tr></thead>| &&
                 |<tbody>{ lv_rows }</tbody></table>| &&
                 |<p>{ sapevent( iv_action = c_action-refresh
                                 iv_label  = 'Refresh' ) }</p>| ).
  ENDMETHOD.

  METHOD render_repository.
    DATA lt_repositories TYPE ty_repositories.
    DATA ls_repository TYPE ty_repository.
    DATA lv_name TYPE string.
    DATA lv_state TYPE string.

    lt_repositories = repositories( ).
    READ TABLE lt_repositories INTO ls_repository
      WITH KEY ucomm = ms_cur_page-repo.
    IF sy-subrc <> 0.
      rv_html = page_document( iv_title = 'Repository'
                               iv_body  = '<p>This repository is no longer known.</p>' ).
      RETURN.
    ENDIF.

    lv_name = cl_gui_control=>escape_html( ls_repository-name ).
    lv_state = COND string( WHEN mv_staged = abap_true THEN 'staged' ELSE 'not staged' ).
    rv_html = page_document(
      iv_title = ls_repository-name
      iv_body  = |<dl><dt>Branch</dt><dd>{ cl_gui_control=>escape_html( ls_repository-branch ) }</dd>| &&
                 |<dt>Objects</dt><dd>{ ls_repository-objects }</dd>| &&
                 |<dt>Staging</dt><dd>{ lv_state }</dd></dl>| &&
                 |<table><caption>Changed objects</caption>| &&
                 |<thead><tr><th scope="col">Type</th><th scope="col">Name</th>| &&
                 |<th scope="col">State</th></tr></thead><tbody>| &&
                 |<tr><th scope="row">CLAS</th><td>{ lv_name }_APP</td><td>{ lv_state }</td></tr>| &&
                 |<tr><th scope="row">PROG</th><td>{ lv_name }_START</td><td>{ lv_state }</td></tr>| &&
                 |</tbody></table>| &&
                 |<p>{ sapevent( iv_action = c_action-stage
                                 iv_label  = 'Stage changes' ) } | &&
                 |{ sapevent( iv_action = c_action-refresh
                              iv_label  = 'Refresh' ) } | &&
                 |{ sapevent( iv_action = c_action-go_back
                              iv_label  = 'Back to repositories' ) }</p>| ).
  ENDMETHOD.

  METHOD page_document.
* One complete document per page, as the render method of an abapGit page
* produces. The host escapes it into the srcdoc of the sandboxed iframe, so
* every value taken from the data above is escaped before it gets here.
    rv_html = |<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">| &&
      |<title>{ cl_gui_control=>escape_html( iv_title ) }</title><style>| &&
      |body\{margin:0;font:13px Arial;color:#123b64;background:#fff\}| &&
      |header\{padding:8px 12px;font-weight:700;background:#e1ebf6;| &&
      |border-bottom:1px solid #b8c9dc\}| &&
      |main\{padding:12px\}table\{border-collapse:collapse;margin:0 0 12px\}| &&
      |caption\{padding:0 0 4px;text-align:left;font-weight:700\}| &&
      |th,td\{padding:4px 10px;text-align:left;border:1px solid #c1d2e0\}| &&
      |dt\{font-weight:700\}dd\{margin:0 0 6px\}| &&
      |</style></head><body><header>{ cl_gui_control=>escape_html( iv_title ) }</header>| &&
      |<main>{ iv_body }</main></body></html>|.
  ENDMETHOD.

  METHOD sapevent.
    DATA lv_action TYPE string.

    lv_action = iv_action.
    CONDENSE lv_action.
    rv_html = |<a class="gg-action" href="sapevent:{ cl_gui_control=>escape_html( lv_action ) }">| &&
      |{ cl_gui_control=>escape_html( iv_label ) }</a>|.
  ENDMETHOD.

  METHOD repositories.
    rt_repositories = VALUE #(
      ( ucomm   = c_action-open_alpha
        name    = '$ZDEMO_ALPHA'
        branch  = 'main'
        objects = 12 )
      ( ucomm   = c_action-open_beta
        name    = '$ZDEMO_BETA'
        branch  = 'release'
        objects = 34 )
      ( ucomm   = c_action-open_gamma
        name    = '$ZDEMO_GAMMA'
        branch  = 'main'
        objects = 7 ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    ro_list_processing = me.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~get_settings.
    rs_settings = VALUE #( title  = 'ZCL_GG_EX_151 HTML viewer shell'
                           status = 'OVERVIEW' ).
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~end_of_page.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page_during_line_sel.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_line_selection.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~load_of_program.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_logical_database.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~initialization.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_field.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_end_of.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_block.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_radio.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_value_req.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_help_req.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_exit.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get_late.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~end_of_selection.
    RETURN.
  ENDMETHOD.

ENDCLASS.
