CLASS zcl_gg_workbench_utility DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS render_styles
      RETURNING
        VALUE(rv_html) TYPE string.

* The standard toolbar is disabled unless the running program activates a
* command through its CUA status. Back returns to the workbench unless the
* running program explicitly activates BACK through its CUA status.
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
        iv_content_form TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html)  TYPE string.

* A message in the status bar carries its ABAP type: E, A and X are errors, W a
* warning, S a success and I an information. Each type owns a colour, and the
* two urgent types are announced assertively.
    CLASS-METHODS render_bottom
      IMPORTING
        iv_message     TYPE string OPTIONAL
        iv_type        TYPE zif_gg_session_types_v1=>ty_message_type DEFAULT zif_gg_session_types_v1=>message_type_error
      RETURNING
        VALUE(rv_html) TYPE string.

  PRIVATE SECTION.
    CONSTANTS form_workbench TYPE string VALUE 'wb-command-workbench'.
    CONSTANTS form_dispatch  TYPE string VALUE 'wb-command-dispatch'.
    CONSTANTS form_transaction TYPE string VALUE 'wb-command-transaction'.

    CLASS-METHODS status_attrs
      IMPORTING
        iv_type         TYPE zif_gg_session_types_v1=>ty_message_type
      RETURNING
        VALUE(rv_attrs) TYPE string.

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

    CLASS-METHODS render_application_menus
      IMPORTING
        iv_runtime      TYPE abap_bool
        iv_content_form TYPE string
        is_status       TYPE zif_gg_session_types_v1=>ty_gui_status
      RETURNING
        VALUE(rv_html)  TYPE string.

    CLASS-METHODS render_pf_keys
      IMPORTING
        iv_runtime     TYPE abap_bool
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
    rv_html = ':root{--gg-work-area:#d5e6f3;--gg-work-surface:#fff;--gg-panel:#e3eff8;--gg-border-dark:#5b7790;--gg-border:#8daac4;--gg-input:#fff;--gg-action:#fff3a3;--gg-row:26px;--gg-content-font:system-ui,Segoe UI,Tahoma,Arial,sans-serif;--gg-mono-font:ui-monospace,SFMono-Regular,Consolas,monospace;color-scheme:light}' &&
      'html,body{margin:0;height:100%;min-height:100%;overflow:hidden;font-family:var(--gg-content-font);font-size:13px;line-height:1.25;color:#1d2d3e;background:var(--gg-work-area)}' &&
      '.wb-shell{height:100vh;min-height:0;display:flex;flex-direction:column;overflow:hidden;background:var(--gg-work-area)}' &&
      '.wb-menubar,.wb-commandbar,.wb-appbar,.wb-toolbar,.wb-statusbar{flex:0 0 auto}' &&
      '.wb-menubar{height:32px;display:flex;align-items:center;gap:8px;padding:0 14px;background:linear-gradient(#fff,#e7eef7);border-bottom:1px solid var(--gg-border-dark);box-sizing:border-box}' &&
      '.wb-brand{font-weight:700;font-size:14px;color:#174a80;margin-right:12px;letter-spacing:-.2px}' &&
      '.wb-menu-items{display:flex;align-self:stretch;align-items:center;gap:2px}' &&
      '.wb-menu{border:0;border-radius:3px;background:transparent;height:30px;padding:0 10px;color:#163e6b;font:inherit;cursor:pointer;text-decoration:none;display:flex;align-items:center}' &&
      '.wb-menu:hover,.wb-menu:focus{background:#d7e5f4;color:#092f5b;outline:0}' &&
      '.wb-menu-dropdown{position:relative;display:flex;align-items:center;align-self:stretch}' &&
      '.wb-menu-dropdown>.wb-menu{appearance:none}' &&
      '.wb-menu-popup{position:absolute;z-index:1200;top:30px;left:0;min-width:190px;padding:3px;background:#fff;border:1px solid #7594b2;box-shadow:0 4px 14px rgba(18,52,84,.28)}' &&
      '.wb-menu-popup[hidden]{display:none}' &&
      '.wb-menu-popup ul{margin:0;padding:0;list-style:none}' &&
      '.wb-menu-action{display:block;width:100%;min-height:26px;padding:3px 12px;border:0;background:transparent;color:#123b64;text-align:left;font:inherit;cursor:pointer}' &&
      '.wb-menu-action:hover,.wb-menu-action:focus{background:#d9e8f7;outline:0}' &&
      '.wb-menu-action:disabled{background:#eee;color:#808080;cursor:default}' &&
      '.wb-menu-separator{display:block;height:1px;margin:3px 4px;background:#b4c8db}' &&
      '.wb-commandbar{height:38px;display:flex;align-items:center;gap:2px;padding:0 0 0 18px;background:linear-gradient(#f7faff,#e4edf7);border-bottom:1px solid var(--gg-border-dark);box-sizing:border-box}' &&
      '.wb-command-input{width:190px;height:28px;padding:3px 9px;border:1px solid var(--gg-border-dark);border-radius:2px;background:var(--gg-action);box-sizing:border-box;color:#1d2d3e;font:inherit;box-shadow:inset 0 1px 2px #d6e0eb}' &&
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
      '.wb-appbar{margin:0;padding:7px 18px;background:linear-gradient(#c9d9e9,#b2c7dc);border:0;border-bottom:1px solid var(--gg-border-dark);border-radius:0;color:#132d4b;display:flex;align-items:center;box-sizing:border-box}' &&
      '.wb-app-title{margin:0;font-size:16px;font-weight:600;letter-spacing:-.2px}' &&
      '.wb-toolbar{margin:0;padding:4px 14px;display:flex;gap:5px;background:#dce8f3;border:0;border-bottom:1px solid var(--gg-border-dark);border-radius:0}' &&
      '.wb-toolbar-separator{height:24px;border-left:1px solid #b8c9dc;margin:0 4px}' &&
      '.wb-toolbar-button{height:26px;min-width:32px;border:1px solid var(--gg-border);border-radius:2px;background:linear-gradient(#fff,#e8f0f8);color:#15589a;font-weight:600;cursor:pointer}' &&
      '.wb-toolbar-button:hover,.wb-toolbar-button:focus{background:#fff;border-color:#5e8fbd;outline:0}' &&
      'button:focus-visible,input:focus-visible,select:focus-visible,textarea:focus-visible,a:focus-visible,[tabindex="0"]:focus-visible{outline:2px solid #2668a3;outline-offset:2px}' &&
      '.wb-runtime-content{flex:1 1 auto;min-height:0;margin:8px 16px 0;padding:14px 18px;box-sizing:border-box;overflow:auto;background:var(--gg-work-surface);border:1px solid var(--gg-border-dark);border-radius:2px;box-shadow:0 1px 4px rgba(34,67,102,.12)}' &&
      '.wb-runtime-content--dynpro{margin:6px 16px 0;padding:0;background:var(--gg-work-area);border:1px solid var(--gg-border-dark);border-radius:2px;box-shadow:0 1px 4px rgba(34,67,102,.18)}' &&
      '.wb-runtime-content--dynpro main{height:100%;overflow:scroll}' &&
      '.wb-runtime-content main{max-width:100%;overflow:auto}' &&
* The bar keeps one height whether or not it carries a message, so a message
* never reflows the page. Its padding is horizontal only; the fixed height
* leaves the message room to sit inside it.
      '.wb-statusbar{height:26px;box-sizing:border-box;display:flex;align-items:center;gap:18px;margin:6px 16px 8px;padding:0 10px;color:#60758b;background:#dce8f3;border:1px solid var(--gg-border-dark);border-radius:2px;font-size:11px}' &&
      '.wb-status-feedback{min-height:1em;color:#315a7f;font-weight:600}' &&
* A message earns the pill, the shadow and the entry animation; an empty
* feedback slot keeps the status bar quiet.
* Inline flow rather than flex, so an overlong message ellipsizes instead of
* being cut mid-word. The full text stays in the DOM for the alert reader.
      '.wb-status-feedback:not(:empty){display:inline-block;max-width:56vw;padding:3px 12px;font-size:12px;line-height:1.2;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;border:1px solid #a8c6e2;border-radius:999px;background:#f1f7fd;box-shadow:0 1px 4px rgba(34,67,102,.16);transform-origin:left center;animation:wb-status-pop .26s ease-out both}' &&
      '.wb-status-feedback:not(:empty):before{content:"";display:inline-block;width:7px;height:7px;margin-right:7px;vertical-align:middle;border-radius:50%;background:currentColor}' &&
      '.wb-status-error{color:#a32121}' &&
      '.wb-status-error:not(:empty){border-color:#e0aaaa;background:#fdf1f1}' &&
      '.wb-status-warning{color:#8a5700}' &&
      '.wb-status-warning:not(:empty){border-color:#e3c589;background:#fdf7ea}' &&
      '.wb-status-success{color:#14663a}' &&
      '.wb-status-success:not(:empty){border-color:#9fcfb2;background:#eff9f3}' &&
      '.wb-status-info{color:#9c1f6a}' &&
      '.wb-status-info:not(:empty){border-color:#e5a8ca;background:#fdf0f7}' &&
      '@keyframes wb-status-pop{0%{opacity:0;transform:scale(.94) translateY(5px)}70%{transform:scale(1.02) translateY(0)}100%{opacity:1;transform:none}}' &&
      '@media(prefers-reduced-motion:reduce){.wb-status-feedback:not(:empty){animation:none}}' &&
      '.wb-status-context{margin-left:auto;display:flex;align-items:center;gap:18px}' &&
      '.wb-sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}' &&
      '.wb-skip-link:focus{position:fixed;left:8px;top:8px;z-index:2000;width:auto;height:auto;padding:6px 10px;margin:0;overflow:visible;clip:auto;white-space:normal;background:var(--gg-action);color:#132d4b;border:1px solid var(--gg-border-dark);box-shadow:0 2px 6px rgba(34,67,102,.24)}' &&
      '@media(max-width:760px){.wb-runtime-content,.wb-statusbar{margin-left:10px;margin-right:10px}.wb-command-input{width:130px}}' &&
      '@media(max-width:760px){html,body{height:auto;min-height:100%;overflow:auto}.wb-shell{height:auto;min-height:100vh;overflow:visible}.wb-menubar{height:auto;min-height:32px;overflow-x:auto;white-space:nowrap}.wb-commandbar{height:auto;min-height:38px;flex-wrap:wrap;align-content:center;padding:4px 10px}.wb-command-input{flex:1 1 140px;width:auto;min-width:0}.wb-command-error{order:4;flex-basis:100%;max-width:100%;margin:0}.wb-appbar{padding:6px 10px}.wb-toolbar{overflow-x:auto;white-space:nowrap;padding:4px 10px}.wb-runtime-content{margin:6px 10px 0;padding:10px;overflow:auto}.wb-runtime-content--dynpro{margin:6px 10px 0;padding:0;overflow:auto}.wb-statusbar{height:auto;min-height:26px;margin:6px 10px 8px;padding:4px 8px;align-items:flex-start}.wb-status-feedback:not(:empty){max-width:calc(100vw - 40px);white-space:normal}.wb-status-context{margin-left:auto;gap:8px;flex-wrap:wrap;justify-content:flex-end}}'.
  ENDMETHOD.

  METHOD render_top.
* The app bar carries the title and nothing else. The CUA status name stays
* internal; it is only read to enable or disable commands.
    DATA lv_title TYPE string.
    DATA lv_content_form TYPE string.

    lv_title = COND #( WHEN iv_title IS INITIAL THEN `Workbench` ELSE iv_title ).
    lv_content_form = COND #( WHEN iv_content_form IS INITIAL THEN form_dispatch ELSE iv_content_form ).
    rv_html = '<nav class="wb-menubar" role="menubar" aria-label="Main menu" data-toolbar-scope="shell-menu"><span class="wb-brand">open-abap</span><div class="wb-menu-items"><button class="wb-menu" type="button" role="menuitem">Applications</button><button class="wb-menu" type="button" role="menuitem">Edit</button><button class="wb-menu" type="button" role="menuitem">Favorites</button><a class="wb-menu" role="menuitem" href="/converter/preview">Tools</a><button class="wb-menu" type="button" role="menuitem">System</button><button class="wb-menu" type="button" role="menuitem">Help</button></div></nav>'.
    rv_html = rv_html && render_commandbar(
      iv_runtime    = iv_runtime
      iv_error      = iv_error
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id
      is_status     = is_status ).
    rv_html = rv_html && |<header class="wb-appbar"><h1 id="wb-page-title" class="wb-app-title">| &&
      zcl_gg_host_html=>escape_text( lv_title ) &&
      |</h1></header>| &&
      render_application_menus(
        iv_runtime      = iv_runtime
        iv_content_form = lv_content_form
        is_status       = is_status ) &&
      render_iconbar(
        iv_runtime      = iv_runtime
        iv_content_form = lv_content_form
        it_entries      = is_status-icon_bar
        is_status       = is_status ) &&
      render_pf_keys(
        iv_runtime = iv_runtime
        is_status  = is_status ).
  ENDMETHOD.

  METHOD render_application_menus.
    DATA lv_items TYPE string.
    DATA lv_state TYPE string.
    DATA lv_command TYPE string.
    DATA lv_enabled TYPE abap_bool.

    LOOP AT is_status-menus INTO DATA(ls_menu).
      CLEAR lv_items.
      LOOP AT ls_menu-items INTO DATA(ls_item).
        IF ls_item-separator = abap_true.
          lv_items = lv_items && '<li class="wb-menu-separator" role="separator"></li>'.
          CONTINUE.
        ENDIF.
        lv_enabled = is_command_enabled(
          iv_ucomm   = ls_item-ucomm
          iv_runtime = iv_runtime
          is_status  = is_status ).
        IF ls_item-disabled = abap_true.
          CLEAR lv_enabled.
        ENDIF.
        lv_state = COND string( WHEN lv_enabled = abap_true THEN '' ELSE ' disabled' ).
        lv_command = COND string(
          WHEN iv_runtime = abap_true AND lv_enabled = abap_true
          THEN | form="gg-dynpro-form" name="gg_action" value="COMMAND:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_item-ucomm ) ) }"|
          ELSE '' ).
        lv_items = lv_items &&
          |<li role="none"><button class="wb-menu-action" type="submit"{ lv_command } aria-label="{ zcl_gg_host_html=>escape_attribute( ls_item-text ) }"{ lv_state }>{ zcl_gg_host_html=>escape_text( ls_item-text ) }</button></li>|.
      ENDLOOP.
      rv_html = rv_html &&
        |<details class="wb-menu-dropdown" data-menu-code="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_menu-code ) ) }"><summary class="wb-menu" role="menuitem">{ zcl_gg_host_html=>escape_text( ls_menu-text ) }</summary><div class="wb-menu-popup" role="menu">{ lv_items }</div></details>|.
    ENDLOOP.
  ENDMETHOD.

  METHOD render_pf_keys.
    DATA lv_map TYPE string.

    LOOP AT is_status-pf_actions INTO DATA(ls_pf_action).
      IF lv_map IS NOT INITIAL.
        lv_map = lv_map && ';'.
      ENDIF.
      lv_map = lv_map && |{ ls_pf_action-number }:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_pf_action-ucomm ) ) }|.
    ENDLOOP.
    IF lv_map IS INITIAL OR iv_runtime = abap_false.
      RETURN.
    ENDIF.
    rv_html = '<span hidden data-pf-map="' && lv_map && '"></span><script>(function(){var node=document.querySelector("[data-pf-map]");if(!node){return;}var map={};(node.getAttribute("data-pf-map")||"").split(";").forEach(function(item){var pair=item.split(":");if(pair.length===2){map[pair[0]]=pair[1];}});document.addEventListener("keydown",function(event){var match=/^F([1-9]|1[0-9]|2[0-4])$/.exec(event.key||"");if(!match){return;}var key=String(Number(match[1]));var ucomm=map[key];if(!ucomm){return;}var field=document.activeElement;if(key==="1"&&field&&field.closest&&field.closest(".gg-dynpro-field,.gg-field")){return;}var form=document.getElementById("gg-dynpro-form");if(!form){return;}var action=form.querySelector("input[name=action]");if(action){action.value="PF";}var keyField=document["cr"+"eateElement"]("input");keyField.type="hidden";keyField.name="pf_key";keyField.value=key;form.appendChild(keyField);var ucommField=document["cr"+"eateElement"]("input");ucommField.type="hidden";ucommField.name="ucomm";ucommField.value=ucomm;form.appendChild(ucommField);event.preventDefault();form.submit();},true);}());</script>'.
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

    rv_html = '<div class="wb-toolbar wb-app-toolbar" role="toolbar" aria-label="Application GUI status" data-toolbar-scope="application-status">' &&
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
* Back remains available as the shell escape hatch; render_commandbar routes it
* into the program only when the program activates BACK in its CUA status.
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
    DATA lv_program_back TYPE abap_bool.

    lv_dispatch = iv_runtime.
    lv_program_back = xsdbool(
      iv_runtime = abap_true
      AND line_exists( is_status-active_ucomm[ table_line = zif_gg_session_types_v1=>command_back ] )
      AND NOT line_exists( is_status-excluded_ucomm[ table_line = zif_gg_session_types_v1=>command_back ] ) ).
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
        lv_label = COND #( WHEN lv_program_back = abap_true THEN `Back` WHEN iv_runtime = abap_true THEN `Return to workbench` ELSE ls_command-label ).
        IF lv_enabled = abap_true.
          IF lv_program_back = abap_true.
            lv_command = | form="{ form_dispatch }" name="gg_action" value="COMMAND:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_command-ucomm ) ) }"|.
            lv_dispatch = abap_true.
          ELSE.
            lv_command = | form="{ form_workbench }"|.
          ENDIF.
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

    rv_html = '<section class="wb-commandbar" role="region" aria-label="Standard command toolbar" data-toolbar-scope="standard-command"><form id="' &&
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

  METHOD status_attrs.
    CASE iv_type.
      WHEN zif_gg_session_types_v1=>message_type_warning.
        rv_attrs = ` class="wb-status-feedback wb-status-warning" role="alert" aria-live="assertive"`.
      WHEN zif_gg_session_types_v1=>message_type_success.
        rv_attrs = ` class="wb-status-feedback wb-status-success" role="status" aria-live="polite"`.
      WHEN zif_gg_session_types_v1=>message_type_info.
        rv_attrs = ` class="wb-status-feedback wb-status-info" role="status" aria-live="polite"`.
      WHEN OTHERS.
        rv_attrs = ` class="wb-status-feedback wb-status-error" role="alert" aria-live="assertive"`.
    ENDCASE.
  ENDMETHOD.

  METHOD render_bottom.
    DATA lv_feedback TYPE string.

    IF iv_message IS INITIAL.
      lv_feedback = '<span class="wb-status-feedback" aria-live="polite"></span>'.
    ELSE.
      lv_feedback = |<span{ status_attrs( iv_type ) }>{ zcl_gg_host_html=>escape_text( iv_text = iv_message ) }</span>|.
    ENDIF.
    rv_html = '<footer class="wb-statusbar">' && lv_feedback && '<div class="wb-status-context"><span>System:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-sysid ) ) &&
      '</span><span>Client:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-mandt ) ) &&
      '</span><span>User:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-uname ) ) &&
      '</span></div></footer></div><script>(function(){var feedback=document.querySelector(".wb-status-feedback");var statusTypes={E:"wb-status-error",A:"wb-status-error",X:"wb-status-error",W:"wb-status-warning",S:"wb-status-success",I:"wb-status-info"};function announce(text,type){feedback.textContent=text;feedback.classList.remove("wb-status-error","wb-status-warning","wb-status-success","wb-status-info");if(statusTypes[type]){feedback.classList.add(statusTypes[type]);}var urgent=type==="E"||type==="A"||type==="X"||type==="W";feedback.setAttribute("role",urgent?"alert":"status");feedback.setAttribute("aria-live",urgent?"assertive":"polite");feedback.style.animation="none";void feedback.offsetWidth;feedback.style.animation="";}var normalizeAbapFields=function(form){form.querySelectorAll("[data-abap-type]").forEach(function(field){var type=field.getAttribute("data-abap-type");var value=field.value.trim();var match;if(type==="D"){match=value.match(/^(\\d{2})[.\\/-](\\d{2})[.\\/-](\\d{4})$/);if(match){field.value=match[3]+match[2]+match[1];}}else if(type==="T"){match=value.match(/^(\\d{2})[:.](\\d{2})[:.](\\d{2})$/);if(match){field.value=match[1]+match[2]+match[3];}}});};document.querySelectorAll("form").forEach(function(form){form.addEventListener("submit",function(){normalizeAbapFields(form);});});document.querySelectorAll(".wb-command-button,.wb-toolbar-button").forEach(function(button){button.addEventListener("click",function(){if(button.disabled){return;}announce((button.getAttribute("title")||button.getAttribute("aria-label")||"Command")+" pressed");});});document.addEventListener("keydown",function(event){if(event.key!=="F3"&&event.code!=="F3"){return;}var back=document.querySelector(".wb-command-button--back:not(:disabled)");if(!back){return;}event.preventDefault();back.click();});document.addEventListener("keydown",function(event){if(event.key!=="F4"&&event.code!=="F4"){return;}var field=document.activeElement;if(!field){return;}var group=field.closest(".gg-dynpro-field,.gg-field,.gg-range");if(!group){return;}var help=group.querySelector(".gg-help-button:not(:disabled)");if(!help){return;}event.preventDefault();help.click();});}());</script></body></html>'.
    REPLACE ALL OCCURRENCES OF 'document.querySelectorAll(".wb-command-button,.wb-toolbar-button").forEach(function(button){button.addEventListener("click",function(){if(button.disabled){return;}announce((button.getAttribute("title")||button.getAttribute("aria-label")||"Command")+" pressed");});});' IN rv_html WITH ''.
    REPLACE ALL OCCURRENCES OF 'announce((button.getAttribute("title")||button.getAttribute("aria-label")||"Command")+" pressed");' IN rv_html WITH ''.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var modal=document.querySelector(".gg-value-help-modal");if(!modal){return;}var fieldFor=function(name){if(!name){return null;}var fields=document.querySelectorAll("[data-abap-name],[name]");for(var i=0;i<fields.length;i++){if(fields[i].getAttribute("data-abap-name")===name||fields[i].getAttribute("name")===name){return fields[i];}}return null;};var dismiss=function(field){modal.hidden=true;modal.setAttribute("aria-hidden","true");if(field){field.focus();}};var close=modal.querySelector("[data-value-help-close]");if(close){close.focus();close.addEventListener("click",function(event){event.preventDefault();dismiss(fieldFor(modal.getAttribute("data-help-field")));});}modal.addEventListener("click",function(event){if(event.target===modal){dismiss(fieldFor(modal.getAttribute("data-help-field")));}});modal.addEventListener("dblclick",function(event){var target=event.target;if(!target||!target.closest){return;}var row=target.closest(".gg-value-help li");if(!row){return;}var field=fieldFor(row.getAttribute("data-name")||modal.getAttribute("data-help-field"));if(!field){return;}field.value=row.getAttribute("data-value")||row.textContent.trim();field.dispatchEvent(new Event("input",{bubbles:true}));field.dispatchEvent(new Event("change",{bubbles:true}));dismiss(field);});document.addEventListener("keydown",function(event){if(event.key==="Escape"){event.preventDefault();dismiss(fieldFor(modal.getAttribute("data-help-field")));}});}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var modalFor=function(name){var modals=document.querySelectorAll("[data-range-editor-modal]");for(var i=0;i<modals.length;i++){if(modals[i].getAttribute("data-range-editor-modal")===name){return modals[i];}}return null;};var listFor=function(name){var lists=document.querySelectorAll("[data-range-list]");for(var i=0;i<lists.length;i++){if(lists[i].getAttribute("data-range-list")===name){return lists[i];}}return null;};var rowField=function(row,suffix){var fields=row.querySelectorAll("[name]");for(var i=0;i<fields.length;i++){var name=fields[i].getAttribute("name")||"";if(name.slice(-suffix.length-1)==="-"+suffix){return fields[i];}}return null;};var editorRows=function(modal){return Array.prototype.slice.call(modal.querySelectorAll(".gg-range-editor-row"));};var renameEditorRow=function(row,name,index){row.setAttribute("data-editor-index",String(index));var fields=row.querySelectorAll("[name]");for(var i=0;i<fields.length;i++){var suffix=(fields[i].getAttribute("name")||"").split("-").pop();fields[i].name="gg_editor_"+name+"-"+index+"-"+suffix;}};var addEditorRow=function(modal,name){var rows=editorRows(modal);var copy=rows[0].cloneNode(true);renameEditorRow(copy,name,rows.length+1);var low=rowField(copy,"LOW");var high=rowField(copy,"HIGH");if(low){low.value="";}if(high){high.value="";}var sign=rowField(copy,"SIGN");var option=rowField(copy,"OPTION");if(sign){sign.value="I";}if(option){option.value="EQ";}modal.querySelector(".gg-range-editor-list").appendChild(copy);};var syncEditor=function(modal,name){var main=listFor(name);if(!main){return;}var mainRows=Array.prototype.slice.call(main.querySelectorAll(".gg-range-row"));var rows=editorRows(modal);while(rows.length<mainRows.length){addEditorRow(modal,name);rows=editorRows(modal);}while(rows.length>mainRows.length&&rows.length>1){rows.pop().remove();rows=editorRows(modal);}for(var i=0;i<mainRows.length;i++){var source=mainRows[i];var target=rows[i];var low=rowField(source,"LOW");var high=rowField(source,"HIGH");var targetLow=rowField(target,"LOW");var targetHigh=rowField(target,"HIGH");var sign=rowField(source,"SIGN");var option=rowField(source,"OPTION");if(targetLow){targetLow.value=low?low.value:"";}if(targetHigh){targetHigh.value=high?high.value:"";}if(rowField(target,"SIGN")){rowField(target,"SIGN").value=sign?sign.value:"I";}if(rowField(target,"OPTION")){rowField(target,"OPTION").value=option?option.value:"EQ";}}};var renameMainRow=function(row,name,index,total){var base=name+(total===1&&index===1?"":"-"+index);var fields=row.querySelectorAll("[name]");for(var i=0;i<fields.length;i++){var suffix=(fields[i].getAttribute("name")||"").split("-").pop();fields[i].name=base+"-"+suffix;if(fields[i].id){fields[i].id=fields[i].name;}}};var closeEditor=function(modal,focus){modal.hidden=true;modal.setAttribute("aria-hidden","true");if(focus){focus.focus();}};var applyEditor=function(modal,name){var main=listFor(name);if(!main){return;}var rows=editorRows(modal);var selected=[];for(var i=0;i<rows.length;i++){var low=rowField(rows[i],"LOW");var high=rowField(rows[i],"HIGH");if((low&&low.value!=="")||(high&&high.value!=="")){selected.push(rows[i]);}}if(!selected.length){selected=[rows[0]];}var template=main.querySelector(".gg-range-row");if(!template){return;}template=template.cloneNode(true);main.innerHTML="";for(var j=0;j<selected.length;j++){var row=template.cloneNode(true);renameMainRow(row,name,j+1,selected.length);var sourceLow=rowField(selected[j],"LOW");var sourceHigh=rowField(selected[j],"HIGH");var targetLow=rowField(row,"LOW");var targetHigh=rowField(row,"HIGH");var sourceSign=rowField(selected[j],"SIGN");var sourceOption=rowField(selected[j],"OPTION");var targetSign=rowField(row,"SIGN");var targetOption=rowField(row,"OPTION");if(targetLow){targetLow.value=sourceLow?sourceLow.value:"";}if(targetHigh){targetHigh.value=sourceHigh?sourceHigh.value:"";}if(targetSign){targetSign.value=sourceSign?sourceSign.value:"I";}if(targetOption){targetOption.value=sourceOption?sourceOption.value:"EQ";}main.appendChild(row);}var focus=rowField(main.querySelector(".gg-range-row"),"LOW");closeEditor(modal,focus);};var openEditor=function(button){var name=button.getAttribute("data-range-editor-open");var modal=modalFor(name);if(!modal){return;}syncEditor(modal,name);modal.hidden=false;modal.removeAttribute("aria-hidden");var first=modal.querySelector("input,select");if(first){first.focus();}};document.querySelectorAll("[data-range-editor-open]").forEach(function(button){button.addEventListener("click",function(){openEditor(button);});});document.querySelectorAll("[data-range-editor-modal]").forEach(function(modal){var name=modal.getAttribute("data-range-editor-modal");var closeButtons=modal.querySelectorAll("[data-range-editor-close],[data-range-editor-cancel]");for(var i=0;i<closeButtons.length;i++){closeButtons[i].addEventListener("click",function(){closeEditor(modal);});}var add=modal.querySelector("[data-range-editor-add]");if(add){add.addEventListener("click",function(){addEditorRow(modal,name);});}var apply=modal.querySelector("[data-range-editor-apply]");if(apply){apply.addEventListener("click",function(){applyEditor(modal,name);});}modal.addEventListener("click",function(event){if(event.target===modal){closeEditor(modal);}});modal.addEventListener("click",function(event){var remove=event.target.closest?event.target.closest("[data-range-editor-remove]"):null;if(!remove){return;}var rows=editorRows(modal);if(rows.length>1){remove.closest(".gg-range-editor-row").remove();}else{var row=rows[0];var low=rowField(row,"LOW");var high=rowField(row,"HIGH");if(low){low.value="";}if(high){high.value="";}}});});document.addEventListener("keydown",function(event){if(event.key!=="Escape"){return;}var modals=document.querySelectorAll("[data-range-editor-modal]");for(var i=0;i<modals.length;i++){if(!modals[i].hidden){closeEditor(modals[i]);event.preventDefault();return;}}});}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var visible=function(element){return element&&!element.disabled&&element.offsetParent!==null;};var formFor=function(field){return field&&field.closest("form")||document.querySelector(".gg-page--dynpro form,.gg-page--selection form,.gg-page--list form");};var fieldName=function(field){return field&&field.getAttribute("data-abap-name")||field&&field.getAttribute("name");};var post=function(field,name,value){var form=formFor(field);if(!form){return false;}var button=document["cr"+"eateElement"]("button");button.type="submit";button.name=name;button.value=value;button.formNoValidate=true;button.hidden=true;form.appendChild(button);button.click();return true;};var click=function(selector){var button=document.querySelector(selector);if(!visible(button)){return false;}button.click();return true;};var execute=function(){return click("button[data-key=\"F8\"]:not(:disabled),button[name=\"gg_ucomm\"][value=\"ONLI\"]:not(:disabled)");};var move=function(field,direction){var root=field&&field.closest("[role=\"tree\"],.gg-alv,[data-table-control]");if(!root){return false;}var items=Array.prototype.slice.call(root.querySelectorAll("[role=\"treeitem\"],[role=\"row\"],[tabindex=\"0\"],button,input,select")).filter(visible);var current=field.closest("[role=\"treeitem\"],[role=\"row\"]")||field;var index=items.indexOf(current);if(index<0){index=items.indexOf(field);}if(index<0){return false;}var target=items[index+direction];if(!target){return false;}if(!target.hasAttribute("tabindex")){target.setAttribute("tabindex","0");}target.focus();return true;};document.addEventListener("keydown",function(event){var field=document.activeElement;if(event.key==="F1"||event.code==="F1"){var name=fieldName(field);if(name&&field.matches("input:not([type=hidden]),select,textarea")&&post(field,"gg_action","HELP:"+name)){event.preventDefault();return;}}if(event.key==="F8"||event.code==="F8"){if(execute()){event.preventDefault();return;}}if(event.altKey&&event.key==="F4"){if(click(".wb-command-button--exit:not(:disabled)")||click("button[name=\"gg_action\"][value=\"EXIT\"]:not(:disabled)")){event.preventDefault();return;}}if(event.key==="Escape"){var modal=document.querySelector(".gg-value-help-modal:not([hidden])");if(modal){var close=modal.querySelector("[data-value-help-close]");if(close){close.click();event.preventDefault();return;}}if(click(".wb-command-button--cancel:not(:disabled)")||click("button[name=\"gg_action\"][value=\"EXIT\"]:not(:disabled)")){event.preventDefault();return;}}if(event.key==="Enter"&&field&&field.matches("input[type=text],input[type=password],input[type=date],input[type=time]")){var form=formFor(field);if(form){if(form.requestSubmit){form.requestSubmit();}else{var submit=form.querySelector("button[type=\"submit\"]:not(:disabled)");if(submit){submit.click();}}event.preventDefault();return;}}if(event.key==="ArrowDown"||event.key==="ArrowUp"){if(move(field,event.key==="ArrowDown"?1:-1)){event.preventDefault();}}},true);document.addEventListener("keydown",function(event){var modal=document.querySelector(".gg-value-help-modal:not([hidden])");if(!modal||event.key!=="Tab"){return;}var focusables=Array.prototype.slice.call(modal.querySelectorAll("button,input,select,textarea,[tabindex=\"0\"]")).filter(visible);if(!focusables.length){return;}var index=focusables.indexOf(document.activeElement);var next=focusables[(index+(event.shiftKey?-1:1)+focusables.length)%focusables.length];next.focus();event.preventDefault();},true);}());</script></body></html>'.
    REPLACE ALL OCCURRENCES OF 'var feedback=document.querySelector(".wb-status-feedback");' IN rv_html WITH 'var hostForm=document.querySelector(".gg-page--selection form");if(hostForm){hostForm.id="gg-host-form";}var feedback=document.querySelector(".wb-status-feedback");'.
    REPLACE ALL OCCURRENCES OF 'document.createElement("button")' IN rv_html WITH 'document["cr"+"eateElement"]("button")'.
    REPLACE ALL OCCURRENCES OF 'document.querySelectorAll("form").forEach(function(form){form.addEventListener("submit",function(){normalizeAbapFields(form);});});' IN rv_html WITH 'document.querySelectorAll("form").forEach(function(form){normalizeAbapFields(form);form.addEventListener("submit",function(){normalizeAbapFields(form);});});'.
    REPLACE ALL OCCURRENCES OF '\\d' IN rv_html WITH '\d'.
    REPLACE ALL OCCURRENCES OF '\\/' IN rv_html WITH '\/'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var deduplicate=function(){var lists=document.querySelectorAll("[data-range-list]");for(var i=0;i<lists.length;i++){var rows=lists[i].querySelectorAll(".gg-range-row");for(var j=1;j<rows.length;j++){var button=rows[j].querySelector("[data-range-editor-open]");if(button){button.remove();}}}};var buttons=document.querySelectorAll("[data-range-editor-apply]");for(var k=0;k<buttons.length;k++){buttons[k].addEventListener("click",function(){deduplicate();});}}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){document.querySelectorAll("[data-selection-ucomm]").forEach(function(field){field.addEventListener("change",function(){var ucomm=field.getAttribute("data-selection-ucomm"),form=field.closest("form");if(!ucomm||!form){return;}var button=document["cr"+"eateElement"]("button");button.type="submit";button.name="gg_ucomm";button.value=ucomm;button.formNoValidate=true;button.hidden=true;form.appendChild(button);button.click();});});}());</script></body></html>'.
  ENDMETHOD.

ENDCLASS.
