CLASS zcl_gg_workbench_utility DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS render_styles
      RETURNING
        VALUE(rv_html) TYPE string.

* The standard toolbar is disabled unless the running program activates a
* command through its CUA status. Back is the exception: it always leaves the
* running program and returns to the workbench.
    CLASS-METHODS render_top
      IMPORTING
        iv_runtime     TYPE abap_bool DEFAULT abap_false
        iv_title       TYPE string DEFAULT `Workbench`
        iv_session_id  TYPE string OPTIONAL
        iv_page_id     TYPE string OPTIONAL
        is_status      TYPE zif_gg_session_types_v1=>ty_gui_status OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_bottom
      RETURNING
        VALUE(rv_html) TYPE string.

  PRIVATE SECTION.
    CONSTANTS form_workbench TYPE string VALUE 'wb-command-workbench'.
    CONSTANTS form_dispatch  TYPE string VALUE 'wb-command-dispatch'.

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
        iv_session_id  TYPE string
        iv_page_id     TYPE string
        is_status      TYPE zif_gg_session_types_v1=>ty_gui_status
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
      '.wb-command-button{height:30px;min-width:28px;padding:0 5px;border:1px solid transparent;border-radius:3px;background:transparent;color:#15589a;font-weight:600;cursor:pointer}' &&
      '.wb-command-button:hover,.wb-command-button:focus{border-color:#86a9cc;background:#d9e8f7;outline:0}' &&
      '.wb-command-button:active,.wb-toolbar-button:active{transform:translateY(1px);border-color:#5e8fbd;background:#c7dced;box-shadow:inset 0 1px 3px rgba(29,63,96,.28)}' &&
      '.wb-command-button:disabled,.wb-command-button:disabled:hover{border-color:transparent;background:transparent;color:#a8afb6;cursor:default}' &&
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
      '.wb-app-title{font-size:20px;font-weight:600;letter-spacing:-.3px}' &&
      '.wb-toolbar{margin:0;padding:7px 18px;display:flex;gap:5px;background:#dce8f3;border:0;border-bottom:1px solid #a8bfd6;border-radius:0}' &&
      '.wb-toolbar-button{height:28px;min-width:32px;border:1px solid #91adca;border-radius:3px;background:linear-gradient(#fff,#e8f0f8);color:#15589a;font-weight:600;cursor:pointer}' &&
      '.wb-toolbar-button:hover,.wb-toolbar-button:focus{background:#fff;border-color:#5e8fbd;outline:0}' &&
      '.wb-runtime-content{flex:1 1 auto;min-height:0;margin:16px 28px 0;padding:22px 26px;box-sizing:border-box;overflow:auto;background:#fff;border:1px solid #aebfd2;border-radius:5px;box-shadow:0 2px 8px rgba(34,67,102,.12)}' &&
      '.wb-runtime-content main{max-width:100%;overflow:auto}' &&
      '.wb-statusbar{display:flex;align-items:center;gap:18px;margin:10px 28px 12px;padding:6px 10px;color:#60758b;background:#dce8f3;border:1px solid #b8c9dc;border-radius:4px;font-size:11px}' &&
      '.wb-status-feedback{min-height:1em;color:#315a7f;font-weight:600}' &&
      '.wb-status-context{margin-left:auto;display:flex;align-items:center;gap:18px}' &&
      '.wb-sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}' &&
      '@media(max-width:760px){.wb-runtime-content,.wb-statusbar{margin-left:10px;margin-right:10px}.wb-command-input{width:130px}}'.
  ENDMETHOD.

  METHOD render_top.
    DATA lv_title TYPE string.

    lv_title = COND #( WHEN iv_title IS INITIAL THEN `Workbench` ELSE iv_title ).
    rv_html = '<nav class="wb-menubar" role="menubar" aria-label="Main menu"><span class="wb-brand">open-abap</span><div class="wb-menu-items">' &&
      '<button class="wb-menu" type="button" role="menuitem">Applications</button><button class="wb-menu" type="button" role="menuitem">Edit</button><button class="wb-menu" type="button" role="menuitem">Favorites</button><button class="wb-menu" type="button" role="menuitem">Tools</button><button class="wb-menu" type="button" role="menuitem">System</button><button class="wb-menu" type="button" role="menuitem">Help</button></div></nav>'.
    rv_html = rv_html && render_commandbar(
      iv_runtime    = iv_runtime
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id
      is_status     = is_status ).
    rv_html = rv_html && '<header class="wb-appbar"><span class="wb-app-title">' &&
      zcl_gg_host_html=>escape_text( lv_title ) &&
      '</span></header><div class="wb-toolbar" aria-label="Application toolbar"><button class="wb-toolbar-button" type="button" title="Create">' &&
      zcl_gg_host_icons=>icon( iv_name = `plus` ) &&
      '</button><button class="wb-toolbar-button" type="button" title="Open">' &&
      zcl_gg_host_icons=>icon( iv_name = `folder-open` ) &&
      '</button><button class="wb-toolbar-button" type="button" title="Add to favorites">' &&
      zcl_gg_host_icons=>icon( iv_name = `star` ) &&
      '</button><button class="wb-toolbar-button" type="button" title="Edit">' &&
      zcl_gg_host_icons=>icon( iv_name = `edit` ) &&
      '</button><button class="wb-toolbar-button" type="button" title="Refresh">' &&
      zcl_gg_host_icons=>icon( iv_name = `refresh` ) &&
      '</button></div>'.
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

    IF iv_runtime = abap_true.
      lv_forms = |<form id="{ form_workbench }" method="get" action="/" hidden></form>|.
      IF lv_dispatch = abap_true.
        lv_forms = lv_forms &&
          |<form id="{ form_dispatch }" method="post" action="/dispatch" hidden>| &&
          |<input type="hidden" name="session_id" value="{ zcl_gg_host_html=>escape_attribute( iv_session_id ) }">| &&
          |<input type="hidden" name="page_id" value="{ zcl_gg_host_html=>escape_attribute( iv_page_id ) }"></form>|.
      ENDIF.
    ENDIF.

    rv_html = '<section class="wb-commandbar" aria-label="Command bar"><label class="wb-sr-only" for="wb-command">Command</label>' &&
      '<input class="wb-command-input" id="wb-command" type="text" placeholder="Command" autocomplete="off">' &&
      lv_buttons && lv_forms && '</section>'.
  ENDMETHOD.

  METHOD render_bottom.
    rv_html = '<footer class="wb-statusbar"><span class="wb-status-feedback" aria-live="polite"></span><div class="wb-status-context"><span>System:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-sysid ) ) &&
      '</span><span>Client:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-mandt ) ) &&
      '</span><span>User:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-uname ) ) &&
      '</span></div></footer></div><script>(function(){var feedback=document.querySelector(".wb-status-feedback");document.querySelectorAll(".wb-command-button,.wb-toolbar-button").forEach(function(button){button.addEventListener("click",function(){feedback.textContent=(button.getAttribute("title")||button.getAttribute("aria-label")||"Command")+" pressed";});});}());</script></body></html>'.
  ENDMETHOD.

ENDCLASS.
