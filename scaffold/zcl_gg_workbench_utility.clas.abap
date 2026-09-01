CLASS zcl_gg_workbench_utility DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS render_styles
      RETURNING
        VALUE(rv_html) TYPE string.

* The standard toolbar is disabled unless the running program activates a
* command through its CUA status. Back is the exception: it always leaves the
* running program and returns to the workbench.
* Programs supply plain title text; this renderer exclusively owns its markup
* and presentation.
    CLASS-METHODS render_top
      IMPORTING
        iv_runtime      TYPE abap_bool DEFAULT abap_false
        iv_title        TYPE string DEFAULT `Workbench`
        iv_error        TYPE string OPTIONAL
        iv_session_id   TYPE string OPTIONAL
        iv_page_id      TYPE string OPTIONAL
        is_status       TYPE zif_gg_session_types_v1=>ty_gui_status OPTIONAL
        it_breadcrumbs  TYPE zif_gg_session_types_v1=>ty_breadcrumbs OPTIONAL
        iv_content_form TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html)  TYPE string.

    CLASS-METHODS render_bottom
      IMPORTING
        iv_message     TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

  PRIVATE SECTION.
    CONSTANTS form_workbench TYPE string VALUE 'wb-command-workbench'.
    CONSTANTS form_dispatch  TYPE string VALUE 'wb-command-dispatch'.
    CONSTANTS form_transaction TYPE string VALUE 'wb-command-transaction'.

* separator marks the group boundary rendered in front of a command.
    TYPES: BEGIN OF ty_command,
             ucomm     TYPE zif_gg_session_types_v1=>ty_ucomm,
             label     TYPE string,
             icon      TYPE string,
             modifier  TYPE string,
             separator TYPE abap_bool,
           END OF ty_command.
    TYPES ty_commands TYPE STANDARD TABLE OF ty_command WITH DEFAULT KEY.

    CLASS-METHODS standard_commands
      RETURNING
        VALUE(rt_commands) TYPE ty_commands.

    CLASS-METHODS render_commandbar
      IMPORTING
        iv_runtime     TYPE abap_bool
        iv_error       TYPE string
        iv_session_id  TYPE string
        iv_page_id     TYPE string
        is_status      TYPE zif_gg_session_types_v1=>ty_gui_status
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_iconbar
      IMPORTING
        iv_runtime      TYPE abap_bool
        iv_content_form TYPE string
        it_entries      TYPE zif_gg_session_types_v1=>ty_icon_bar
        is_status       TYPE zif_gg_session_types_v1=>ty_gui_status
      RETURNING
        VALUE(rv_html)  TYPE string.

    CLASS-METHODS render_breadcrumbs
      IMPORTING
        it_breadcrumbs TYPE zif_gg_session_types_v1=>ty_breadcrumbs
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS is_command_enabled
      IMPORTING
        iv_ucomm          TYPE zif_gg_session_types_v1=>ty_ucomm
        iv_runtime        TYPE abap_bool
        is_status         TYPE zif_gg_session_types_v1=>ty_gui_status
      RETURNING
        VALUE(rv_enabled) TYPE abap_bool.

ENDCLASS.

CLASS zcl_gg_workbench_utility IMPLEMENTATION.

  METHOD render_styles.
    rv_html = 'html,body{margin:0;height:100%;min-height:100%;overflow:hidden;font-family:Inter,Segoe UI,Tahoma,Arial,sans-serif;font-size:13px;color:#1d2d3e;background:#e9f0f8}' &&
      '.wb-shell{height:100vh;min-height:0;display:flex;flex-direction:column;overflow:hidden;background:#e9f0f8}' &&
      '.wb-menubar,.wb-commandbar,.wb-appbar,.wb-toolbar,.wb-statusbar{flex:0 0 auto}' &&
      '.wb-menubar{height:40px;display:flex;align-items:center;gap:8px;padding:0 18px;background:linear-gradient(#fff,#e7eef7);border-bottom:1px solid #b8c9dc;box-sizing:border-box}' &&
      '.wb-brand{font-weight:700;font-size:14px;color:#174a80;margin-right:12px;letter-spacing:-.2px}' &&
      '.wb-menu-items{display:flex;align-self:stretch;align-items:center;gap:2px}' &&
      '.wb-menu{border:0;border-radius:3px;background:transparent;height:30px;padding:0 10px;color:#163e6b;font:inherit;cursor:pointer}' &&
      '.wb-menu:hover,.wb-menu:focus{background:#d7e5f4;color:#092f5b;outline:0}' &&
      '.wb-commandbar{height:48px;display:flex;align-items:center;gap:2px;padding:0 0 0 18px;background:linear-gradient(#f7faff,#e4edf7);border-bottom:1px solid #afc2d8;box-sizing:border-box}' &&
      '.wb-command-input{width:190px;height:30px;padding:3px 9px;border:1px solid #829fbe;border-radius:2px;background:#fff;box-sizing:border-box;color:#1d2d3e;font:inherit;box-shadow:inset 0 1px 2px #d6e0eb}' &&
      '.wb-command-input:focus{outline:2px solid #8db5df;outline-offset:0}' &&
      '.wb-command-error{color:#a32121;font-weight:600;margin-left:12px;max-width:48vw}' &&
      '.wb-command-button{height:30px;min-width:28px;padding:0 5px;border:1px solid transparent;border-radius:3px;background:transparent;color:#15589a;font-weight:600;cursor:pointer}' &&
      '.wb-command-button:hover,.wb-command-button:focus{border-color:#86a9cc;background:#d9e8f7;outline:0}' &&
      '.wb-command-button:not(:disabled):active,.wb-toolbar-button:not(:disabled):active{transform:translateY(1px);border-color:#5e8fbd;background:#c7dced;box-shadow:inset 0 1px 3px rgba(29,63,96,.28)}' &&
      '.wb-command-button:disabled,.wb-command-button:disabled:hover,.wb-command-button:disabled:active{transform:none;border-color:transparent;background:transparent;box-shadow:none;color:#a8afb6;cursor:default}' &&
      '.wb-command-button--back{color:#3b9348}' &&
      '.wb-command-button--exit{color:#e2a100}' &&
      '.wb-command-button--cancel{color:#d63b3b}' &&
      '.wb-command-button--page{color:#15589a}' &&
      '.wb-command-separator{height:24px;border-left:1px solid #b8c9dc;margin:0 4px}' &&
      '.wb-icon-sprite{position:absolute;width:0;height:0;overflow:hidden}' &&
      '.wb-icon{display:inline-block;width:16px;height:16px;flex:0 0 auto;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;vertical-align:middle}' &&
      '.wb-command-button .wb-icon{width:17px;height:17px}' &&
      '.wb-toolbar-button .wb-icon{width:17px;height:17px}' &&
      '.wb-appbar{margin:0;padding:12px 18px;background:linear-gradient(#c9d9e9,#b2c7dc);border:0;border-bottom:1px solid #8da9c5;border-radius:0;color:#132d4b;display:flex;align-items:center;box-sizing:border-box}' &&
      '.wb-app-title{margin:0;font-size:20px;font-weight:600;letter-spacing:-.3px}' &&
      '.wb-breadcrumbs{padding:5px 18px;background:#eef4fa;border-bottom:1px solid #c5d5e5;color:#4d667f}' &&
      '.wb-breadcrumbs ol{display:flex;gap:0;margin:0;padding:0;list-style:none}' &&
      '.wb-breadcrumbs li+li:before{content:"/";padding:0 8px;color:#8ba1b6}' &&
      '.wb-breadcrumbs span{white-space:nowrap}' &&
      '.wb-toolbar{margin:0;padding:7px 18px;display:flex;gap:5px;background:#dce8f3;border:0;border-bottom:1px solid #a8bfd6;border-radius:0}' &&
      '.wb-toolbar-separator{height:24px;border-left:1px solid #b8c9dc;margin:0 4px}' &&
      '.wb-toolbar-button{height:28px;min-width:32px;border:1px solid #91adca;border-radius:3px;background:linear-gradient(#fff,#e8f0f8);color:#15589a;font-weight:600;cursor:pointer}' &&
      '.wb-toolbar-button:hover,.wb-toolbar-button:focus{background:#fff;border-color:#5e8fbd;outline:0}' &&
      'button:focus-visible,input:focus-visible,select:focus-visible,textarea:focus-visible,a:focus-visible,[tabindex="0"]:focus-visible{outline:2px solid #2668a3;outline-offset:2px}' &&
      '.wb-runtime-content{flex:1 1 auto;min-height:0;margin:16px 28px 0;padding:22px 26px;box-sizing:border-box;overflow:auto;background:#fff;border:1px solid #aebfd2;border-radius:5px;box-shadow:0 2px 8px rgba(34,67,102,.12)}' &&
      '.wb-runtime-content--dynpro{margin:8px 26px 0;padding:0;background:#d5e6f3;border:1px solid #9ab3c8;border-radius:2px;box-shadow:0 1px 4px rgba(34,67,102,.18)}' &&
      '.wb-runtime-content--dynpro main{height:100%;overflow:scroll}' &&
      '.wb-runtime-content main{max-width:100%;overflow:auto}' &&
* The bar keeps one height whether or not it carries a message, so a message
* never reflows the page. Its padding is horizontal only; the fixed height
* leaves the message room to sit inside it.
      '.wb-statusbar{height:29px;box-sizing:border-box;display:flex;align-items:center;gap:18px;margin:10px 28px 12px;padding:0 10px;color:#60758b;background:#dce8f3;border:1px solid #b8c9dc;border-radius:4px;font-size:11px}' &&
      '.wb-status-feedback{min-height:1em;color:#315a7f;font-weight:600}' &&
* A message earns the pill, the shadow and the entry animation; an empty
* feedback slot keeps the status bar quiet.
* Inline flow rather than flex, so an overlong message ellipsizes instead of
* being cut mid-word. The full text stays in the DOM for the alert reader.
      '.wb-status-feedback:not(:empty){display:inline-block;max-width:56vw;padding:3px 12px;font-size:12px;line-height:1.2;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;border:1px solid #a8c6e2;border-radius:999px;background:#f1f7fd;box-shadow:0 1px 4px rgba(34,67,102,.16);transform-origin:left center;animation:wb-status-pop .26s ease-out both}' &&
      '.wb-status-feedback:not(:empty):before{content:"";display:inline-block;width:7px;height:7px;margin-right:7px;vertical-align:middle;border-radius:50%;background:currentColor}' &&
      '.wb-status-error{color:#a32121}' &&
      '.wb-status-error:not(:empty){border-color:#e0aaaa;background:#fdf1f1}' &&
      '@keyframes wb-status-pop{0%{opacity:0;transform:scale(.94) translateY(5px)}70%{transform:scale(1.02) translateY(0)}100%{opacity:1;transform:none}}' &&
      '@media(prefers-reduced-motion:reduce){.wb-status-feedback:not(:empty){animation:none}}' &&
      '.wb-status-context{margin-left:auto;display:flex;align-items:center;gap:18px}' &&
      '.wb-sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}' &&
      '@media(max-width:760px){.wb-runtime-content,.wb-statusbar{margin-left:10px;margin-right:10px}.wb-command-input{width:130px}}'.
  ENDMETHOD.

  METHOD render_top.
* The app bar carries the title and nothing else. The CUA status name stays
* internal; it is only read to enable or disable commands.
    DATA lv_title TYPE string.
    DATA lv_content_form TYPE string.

    lv_title = COND #( WHEN iv_title IS INITIAL THEN `Workbench` ELSE iv_title ).
    lv_content_form = COND #( WHEN iv_content_form IS INITIAL THEN form_dispatch ELSE iv_content_form ).
    rv_html = '<nav class="wb-menubar" role="menubar" aria-label="Main menu"><span class="wb-brand">open-abap</span><div class="wb-menu-items"><button class="wb-menu" type="button" role="menuitem">Applications</button><button class="wb-menu" type="button" role="menuitem">Edit</button><button class="wb-menu" type="button" role="menuitem">Favorites</button><button class="wb-menu" type="button" role="menuitem">Tools</button><button class="wb-menu" type="button" role="menuitem">System</button><button class="wb-menu" type="button" role="menuitem">Help</button></div></nav>'.
    rv_html = rv_html && render_commandbar(
      iv_runtime    = iv_runtime
      iv_error      = iv_error
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id
      is_status     = is_status ).
    rv_html = rv_html && |<header class="wb-appbar"><h1 class="wb-app-title">| &&
      zcl_gg_host_html=>escape_text( lv_title ) &&
      |</h1></header>| &&
      render_breadcrumbs( it_breadcrumbs ) &&
      render_iconbar(
        iv_runtime      = iv_runtime
        iv_content_form = lv_content_form
        it_entries      = is_status-icon_bar
        is_status       = is_status ).
  ENDMETHOD.

  METHOD render_iconbar.
    DATA lv_buttons  TYPE string.
    DATA lv_label    TYPE string.
    DATA lv_type     TYPE string.
    DATA lv_command  TYPE string.
    DATA lv_state    TYPE string.
    DATA lv_enabled  TYPE abap_bool.

    IF it_entries IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_entries INTO DATA(ls_icon).
      IF ls_icon-separator = abap_true.
        lv_buttons = lv_buttons && '<span class="wb-toolbar-separator" aria-hidden="true"></span>'.
      ENDIF.
      lv_label = COND #( WHEN ls_icon-label IS INITIAL THEN CONV string( ls_icon-ucomm ) ELSE ls_icon-label ).
      lv_enabled = abap_true.
      IF iv_runtime = abap_true AND ls_icon-ucomm IS NOT INITIAL.
        lv_enabled = is_command_enabled(
          iv_ucomm   = ls_icon-ucomm
          iv_runtime = iv_runtime
          is_status  = is_status ).
      ENDIF.
      lv_state = COND #( WHEN lv_enabled = abap_true THEN `` ELSE ` disabled` ).
      lv_type = COND #( WHEN iv_runtime = abap_true AND ls_icon-ucomm IS NOT INITIAL THEN `submit` ELSE `button` ).
      CLEAR lv_command.
      IF iv_runtime = abap_true AND lv_enabled = abap_true AND ls_icon-ucomm IS NOT INITIAL.
        lv_command = | form="{ iv_content_form }" name="gg_action" value="COMMAND:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_icon-ucomm ) ) }"|.
      ENDIF.
      lv_buttons = lv_buttons &&
        |<button class="wb-toolbar-button" type="{ lv_type }"{ lv_command } aria-label="{ zcl_gg_host_html=>escape_attribute( lv_label ) }" title="{ zcl_gg_host_html=>escape_attribute( lv_label ) }" data-ucomm="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_icon-ucomm ) ) }"{ lv_state }>| &&
        zcl_gg_host_icons=>icon( iv_name = ls_icon-icon ) &&
        '</button>'.
    ENDLOOP.

    rv_html = '<div class="wb-toolbar" role="toolbar" aria-label="Application icon bar">' &&
      lv_buttons && '</div>'.
  ENDMETHOD.

  METHOD standard_commands.
    rt_commands = VALUE #(
      ( ucomm = zif_gg_session_types_v1=>command_save
        label = `Save`
        icon  = `device-floppy` )
      ( ucomm     = zif_gg_session_types_v1=>command_back
        label     = `Back`
        icon      = `arrow-back-up`
        modifier  = ` wb-command-button--back`
        separator = abap_true )
      ( ucomm    = zif_gg_session_types_v1=>command_exit
        label    = `Exit`
        icon     = `logout`
        modifier = ` wb-command-button--exit` )
      ( ucomm    = zif_gg_session_types_v1=>command_cancel
        label    = `Cancel`
        icon     = `circle-x`
        modifier = ` wb-command-button--cancel` )
      ( ucomm     = zif_gg_session_types_v1=>command_print
        label     = `Print`
        icon      = `printer`
        separator = abap_true )
      ( ucomm = zif_gg_session_types_v1=>command_find
        label = `Find`
        icon  = `search` )
      ( ucomm = zif_gg_session_types_v1=>command_find_next
        label = `Find next`
        icon  = `search-plus` )
      ( ucomm     = zif_gg_session_types_v1=>command_first_page
        label     = `First page`
        icon      = `arrow-bar-to-up`
        modifier  = ` wb-command-button--page`
        separator = abap_true )
      ( ucomm    = zif_gg_session_types_v1=>command_previous_page
        label    = `Previous page`
        icon     = `file-arrow-up`
        modifier = ` wb-command-button--page` )
      ( ucomm    = zif_gg_session_types_v1=>command_next_page
        label    = `Next page`
        icon     = `file-arrow-down`
        modifier = ` wb-command-button--page` )
      ( ucomm    = zif_gg_session_types_v1=>command_last_page
        label    = `Last page`
        icon     = `arrow-bar-to-down`
        modifier = ` wb-command-button--page` ) ).
  ENDMETHOD.

  METHOD is_command_enabled.
* Back always leaves the running program, everything else needs a CUA status
* that activates the function code and does not exclude it again.
    IF iv_ucomm = zif_gg_session_types_v1=>command_back.
      rv_enabled = iv_runtime.
      RETURN.
    ENDIF.
    IF iv_runtime = abap_false
        OR line_exists( is_status-excluded_ucomm[ table_line = iv_ucomm ] ).
      RETURN.
    ENDIF.
    rv_enabled = xsdbool( line_exists( is_status-active_ucomm[ table_line = iv_ucomm ] ) ).
  ENDMETHOD.

  METHOD render_commandbar.
    DATA lt_commands TYPE ty_commands.
    DATA lv_buttons  TYPE string.
    DATA lv_forms    TYPE string.
    DATA lv_label    TYPE string.
    DATA lv_command  TYPE string.
    DATA lv_state    TYPE string.
    DATA lv_enabled  TYPE abap_bool.
    DATA lv_dispatch TYPE abap_bool.

    lv_dispatch = iv_runtime.
    lt_commands = standard_commands( ).
    LOOP AT lt_commands INTO DATA(ls_command).
      IF ls_command-separator = abap_true.
        lv_buttons = lv_buttons && '<span class="wb-command-separator" aria-hidden="true"></span>'.
      ENDIF.
      lv_enabled = is_command_enabled( iv_ucomm   = ls_command-ucomm
                                       iv_runtime = iv_runtime
                                       is_status  = is_status ).
      lv_state = COND #( WHEN lv_enabled = abap_true THEN `` ELSE ` disabled` ).
      CLEAR lv_command.
      IF ls_command-ucomm = zif_gg_session_types_v1=>command_back.
        lv_label = COND #( WHEN iv_runtime = abap_true THEN `Return to workbench` ELSE ls_command-label ).
        IF lv_enabled = abap_true.
          lv_command = | form="{ form_workbench }"|.
        ENDIF.
      ELSE.
        lv_label = COND #( WHEN iv_runtime = abap_true THEN `Global command` ELSE ls_command-label ).
        IF lv_enabled = abap_true.
          lv_command = | form="{ form_dispatch }" name="gg_action" value="COMMAND:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_command-ucomm ) ) }"|.
          lv_dispatch = abap_true.
        ENDIF.
      ENDIF.
      lv_buttons = lv_buttons &&
        |<button class="wb-command-button{ ls_command-modifier }" type="submit"{ lv_command } aria-label="{ zcl_gg_host_html=>escape_attribute( lv_label ) }" title="{ zcl_gg_host_html=>escape_attribute( ls_command-label ) }"{ lv_state }>| &&
        zcl_gg_host_icons=>icon( iv_name = ls_command-icon ) &&
        '</button>'.
    ENDLOOP.

    IF iv_runtime = abap_true OR iv_session_id IS NOT INITIAL OR iv_page_id IS NOT INITIAL.
      lv_forms = |<form id="{ form_workbench }" method="get" action="/" hidden></form>|.
      IF lv_dispatch = abap_true.
        lv_forms = lv_forms &&
          |<form id="{ form_dispatch }" method="post" action="/dispatch" hidden>| &&
          |<input type="hidden" name="session_id" value="{ zcl_gg_host_html=>escape_attribute( iv_session_id ) }">| &&
          |<input type="hidden" name="page_id" value="{ zcl_gg_host_html=>escape_attribute( iv_page_id ) }"></form>|.
      ENDIF.
    ENDIF.

    rv_html = '<section class="wb-commandbar" aria-label="Command bar"><form id="' &&
      form_transaction && '" method="post" action="/transaction">' &&
      '<label class="wb-sr-only" for="wb-command">Command</label>' &&
*     The command field is never pre-filled. A command is consumed when it is
*     submitted, so a rejected one is not echoed back for accidental resend.
      '<input class="wb-command-input" id="wb-command" name="command" type="text" placeholder="Command" autocomplete="off" value="">'.
    IF iv_session_id IS NOT INITIAL OR iv_page_id IS NOT INITIAL.
      rv_html = rv_html &&
        |<input type="hidden" name="session_id" value="{ zcl_gg_host_html=>escape_attribute( iv_session_id ) }"><input type="hidden" name="page_id" value="{ zcl_gg_host_html=>escape_attribute( iv_page_id ) }">|.
    ENDIF.
    rv_html = rv_html && '</form>' &&
      COND string( WHEN iv_error IS INITIAL THEN `` ELSE |<div id="wb-command-error" class="wb-command-error" role="alert" aria-live="assertive">{ zcl_gg_host_html=>escape_text( iv_error ) }</div>| ) &&
      lv_buttons && lv_forms && '</section>'.
  ENDMETHOD.

  METHOD render_breadcrumbs.
    IF it_breadcrumbs IS INITIAL.
      RETURN.
    ENDIF.
    rv_html = '<nav class="wb-breadcrumbs" aria-label="Breadcrumb"><ol>'.
    LOOP AT it_breadcrumbs INTO DATA(ls_breadcrumb).
      IF ls_breadcrumb-current = abap_true.
        rv_html = rv_html && |<li><span aria-current="page" data-breadcrumb-target="{ zcl_gg_host_html=>escape_attribute( ls_breadcrumb-target ) }">{ zcl_gg_host_html=>escape_text( ls_breadcrumb-label ) }</span></li>|.
      ELSE.
        rv_html = rv_html && |<li><span data-breadcrumb-target="{ zcl_gg_host_html=>escape_attribute( ls_breadcrumb-target ) }">{ zcl_gg_host_html=>escape_text( ls_breadcrumb-label ) }</span></li>|.
      ENDIF.
    ENDLOOP.
    rv_html = rv_html && '</ol></nav>'.
  ENDMETHOD.

  METHOD render_bottom.
    DATA lv_feedback TYPE string.

    IF iv_message IS INITIAL.
      lv_feedback = '<span class="wb-status-feedback" aria-live="polite"></span>'.
    ELSE.
      lv_feedback = |<span class="wb-status-feedback wb-status-error" role="alert" aria-live="assertive">{ zcl_gg_host_html=>escape_text( iv_text = iv_message ) }</span>|.
    ENDIF.
    rv_html = '<footer class="wb-statusbar">' && lv_feedback && '<div class="wb-status-context"><span>System:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-sysid ) ) &&
      '</span><span>Client:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-mandt ) ) &&
      '</span><span>User:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-uname ) ) &&
      '</span></div></footer></div><script>(function(){var feedback=document.querySelector(".wb-status-feedback");function announce(text){feedback.textContent=text;feedback.classList.remove("wb-status-error");feedback.style.animation="none";void feedback.offsetWidth;feedback.style.animation="";}document.querySelectorAll(".wb-command-button,.wb-toolbar-button").forEach(function(button){button.addEventListener("click",function(){if(button.disabled){return;}announce((button.getAttribute("title")||button.getAttribute("aria-label")||"Command")+" pressed");});});document.addEventListener("keydown",function(event){if(event.key!=="F3"&&event.code!=="F3"){return;}var back=document.querySelector(".wb-command-button--back:not(:disabled)");if(!back){return;}event.preventDefault();back.click();});document.addEventListener("keydown",function(event){if(event.key!=="F4"&&event.code!=="F4"){return;}var field=document.activeElement;if(!field){return;}var group=field.closest(".gg-dynpro-field,.gg-field,.gg-range");if(!group){return;}var help=group.querySelector(".gg-help-button:not(:disabled)");if(!help){return;}event.preventDefault();help.click();});}());</script></body></html>'.
  ENDMETHOD.

ENDCLASS.
