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
        iv_execute_form TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html)  TYPE string.

* A selection screen's Execute (ONLI, F8), as the F8 icon. It submits the
* selection form by its id, so the entered values travel with it.
    CLASS-METHODS render_execute_button
      IMPORTING
        iv_form        TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

* A message in the status bar carries its ABAP type: E, A and X are errors, W a
* warning, S a success and I an information. Each type owns a colour, and the
* two urgent types are announced assertively. is_message is the message as the
* program sent it; double-clicking the bar shows its technical information,
* as SAP GUI does.
    CLASS-METHODS render_bottom
      IMPORTING
        iv_message     TYPE string OPTIONAL
        iv_type        TYPE zif_gg_session_types_v1=>ty_message_type DEFAULT zif_gg_session_types_v1=>message_type_error
        is_message     TYPE zif_gg_session_types_v1=>ty_message OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

* The id of the status bar message, which a field the message is about
* refers to with aria-describedby.
    CONSTANTS status_message_id TYPE string VALUE 'wb-status-message'.
* The id of the dialog with the technical information of the status bar message.
    CONSTANTS message_details_id TYPE string VALUE 'wb-message-details'.

  PRIVATE SECTION.
    CONSTANTS form_workbench TYPE string VALUE 'wb-command-workbench'.
    CONSTANTS form_dispatch  TYPE string VALUE 'wb-command-dispatch'.
    CONSTANTS form_transaction TYPE string VALUE 'wb-command-transaction'.
    CONSTANTS system_status_id TYPE string VALUE 'wb-system-status'.
    CONSTANTS help_url TYPE string VALUE 'https://open-abap.org'.

* System > Status: the session's client, user and language, the system and
* the host, as SAP GUI shows them in its System: Status dialog.
    CLASS-METHODS render_system_status
      IMPORTING
        is_status      TYPE zif_gg_session_types_v1=>ty_gui_status
      RETURNING
        VALUE(rv_html) TYPE string.

    TYPES: BEGIN OF ty_status_row,
             label TYPE string,
             value TYPE string,
           END OF ty_status_row.
    TYPES ty_status_rows TYPE STANDARD TABLE OF ty_status_row WITH DEFAULT KEY.

* One titled group of the System: Status dialog.
    CLASS-METHODS status_group
      IMPORTING
        iv_id          TYPE string
        iv_title       TYPE string
        it_rows        TYPE ty_status_rows
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS status_attrs
      IMPORTING
        iv_type         TYPE zif_gg_session_types_v1=>ty_message_type
      RETURNING
        VALUE(rv_attrs) TYPE string.

    CLASS-METHODS render_message_details
      IMPORTING
        is_message     TYPE zif_gg_session_types_v1=>ty_message
      RETURNING
        VALUE(rv_html) TYPE string.

* separator marks the group boundary rendered in front of a command.
    TYPES: BEGIN OF ty_command,
             ucomm     TYPE zif_gg_session_types_v1=>ty_ucomm,
             label     TYPE string,
             icon      TYPE string,
             modifier  TYPE string,
             separator TYPE abap_bool,
             key       TYPE i,
           END OF ty_command.
    TYPES ty_commands TYPE STANDARD TABLE OF ty_command WITH DEFAULT KEY.

    CLASS-METHODS standard_commands
      RETURNING
        VALUE(rt_commands) TYPE ty_commands.

    CLASS-METHODS render_commandbar
      IMPORTING
        iv_runtime      TYPE abap_bool
        iv_error        TYPE string
        iv_session_id   TYPE string
        iv_page_id      TYPE string
        is_status       TYPE zif_gg_session_types_v1=>ty_gui_status
        iv_content_form TYPE string DEFAULT form_dispatch
      RETURNING
        VALUE(rv_html)  TYPE string.

    CLASS-METHODS render_iconbar
      IMPORTING
        iv_runtime      TYPE abap_bool
        iv_content_form TYPE string
        iv_execute_form TYPE string
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
      '.wb-status-menu-items{min-height:32px;padding:0 14px;background:linear-gradient(#fff,#e7eef7);border-bottom:1px solid var(--gg-border-dark);box-sizing:border-box}' &&
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
      '.wb-toolbar-button{height:26px;min-width:32px;padding:0 7px;display:inline-flex;align-items:center;justify-content:center;gap:4px;border:1px solid var(--gg-border);border-radius:2px;background:linear-gradient(#fff,#e8f0f8);color:#15589a;font-weight:600;cursor:pointer}' &&
      '.wb-toolbar-button:hover,.wb-toolbar-button:focus{background:#fff;border-color:#5e8fbd;outline:0}' &&
      '.wb-toolbar-button--execute{color:#3b9348}' &&
      'button:focus-visible,input:focus-visible,select:focus-visible,textarea:focus-visible,a:focus-visible,[tabindex="0"]:focus-visible{outline:2px solid #2668a3;outline-offset:2px}' &&
      '.wb-runtime-content{flex:1 1 auto;min-height:0;margin:8px 16px 0;padding:14px 18px;box-sizing:border-box;overflow:auto;background:var(--gg-work-surface);border:1px solid var(--gg-border-dark);border-radius:2px;box-shadow:0 1px 4px rgba(34,67,102,.12)}' &&
      '.wb-runtime-content--dynpro{margin:6px 16px 0;padding:0;background:var(--gg-work-area);border:1px solid var(--gg-border-dark);border-radius:2px;box-shadow:0 1px 4px rgba(34,67,102,.18)}' &&
      '.wb-runtime-content--dynpro main{height:100%;overflow:scroll}' &&
      '.wb-runtime-content main{height:100%;max-width:100%;overflow:auto;box-sizing:border-box}' &&
* The bar keeps one height whether or not it carries a message, so a message
* never reflows the page. On a narrow screen, where the page scrolls as a
* whole, the bar is fixed to the bottom of the window and the shell keeps its
* room free. Its padding is horizontal only; the fixed height
* leaves the message room to sit inside it.
      '.wb-statusbar{position:relative;height:26px;box-sizing:border-box;display:flex;align-items:center;gap:18px;margin:6px 16px 8px;padding:0 10px;color:#60758b;background:#dce8f3;border:1px solid var(--gg-border-dark);border-radius:2px;font-size:11px}' &&
* The message gives way to the system, client and user, never the other way
* round: it shrinks and ellipsizes, the context keeps its width.
      '.wb-status-feedback{flex:0 1 auto;min-width:0;min-height:1em;color:#315a7f;font-weight:600}' &&
* A message is a strip at the left of the bar: an edge and an icon in the
* colour of its type (--wb-status-accent), a tint behind dark text, and a fade at its end into the
* bar's blue. An empty feedback slot keeps the status bar quiet.
* Block flow rather than flex, so an overlong message ellipsizes instead of
* being cut mid-word. The full text stays in the DOM for the alert reader and
* in the title for the pointer; the right padding keeps it clear of the fade.
      '.wb-status-feedback:not(:empty){--wb-status-accent:#315a7f;--wb-status-tint:#f1f7fd;align-self:stretch;display:block;max-width:100%;margin-left:-10px;padding:0 36px 0 9px;box-sizing:border-box;font-size:12px;line-height:24px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:#1d2d3e;border-left:3px solid var(--wb-status-accent);background:linear-gradient(90deg,var(--wb-status-tint) 0,var(--wb-status-tint) calc(100% - 32px),rgba(220,232,243,0) 100%);animation:wb-status-pop .26s ease-out both}' &&
      '.wb-status-feedback>.wb-icon{width:14px;height:14px;margin:-2px 6px 0 0;color:var(--wb-status-accent)}' &&
* A message the bar cuts short can be focused, by keyboard or click, and then
* opens above the bar in full; it leaves the bar's flow, so nothing reflows.
      '.wb-status-feedback--clipped{cursor:pointer}' &&
      '.wb-status-feedback--clipped:focus{position:absolute;left:10px;right:10px;bottom:calc(100% + 4px);z-index:1300;max-width:none;margin:0;padding:6px 12px 6px 9px;line-height:1.35;white-space:normal;overflow:visible;background:var(--wb-status-tint);border:1px solid var(--wb-status-accent);border-left-width:3px;border-radius:2px;outline:0;box-shadow:0 4px 14px rgba(18,52,84,.28);animation:none}' &&
      '.wb-status-error:not(:empty){--wb-status-accent:#bb0000;--wb-status-tint:#ffebeb}' &&
      '.wb-status-warning:not(:empty){--wb-status-accent:#e9730c;--wb-status-tint:#fef7f1}' &&
      '.wb-status-success:not(:empty){--wb-status-accent:#107e3e;--wb-status-tint:#f1fdf6}' &&
      '.wb-status-info:not(:empty){--wb-status-accent:#0a6ed1;--wb-status-tint:#f5faff}' &&
      '@keyframes wb-status-pop{0%{opacity:0;transform:translateX(-6px)}100%{opacity:1;transform:none}}' &&
      '@media(prefers-reduced-motion:reduce){.wb-status-feedback:not(:empty){animation:none}}' &&
* A dialog, the technical information of the message or the system status,
* opens above everything, the clipped message included.
      '.wb-dialog{position:fixed;inset:0;z-index:1400;display:flex;align-items:center;justify-content:center;padding:24px;box-sizing:border-box;background:rgba(19,45,72,.48)}' &&
      '.wb-dialog[hidden]{display:none}' &&
      '.wb-dialog-panel{width:min(460px,100%);max-height:calc(100vh - 48px);overflow:auto;background:#f8fbfe;border:1px solid #7594b2;border-radius:5px;box-shadow:0 18px 48px rgba(18,52,84,.34);color:#1d2d3e;font-size:13px}' &&
      '.wb-dialog-header{display:flex;align-items:center;justify-content:space-between;gap:16px;padding:12px 14px;background:linear-gradient(#f8fbfe,#e2edf7);border-bottom:1px solid #b4c8db}' &&
      '.wb-dialog-header h2{margin:0;color:#174a80;font-size:16px;font-weight:650;line-height:1.25}' &&
      '.wb-dialog-close{display:inline-flex;align-items:center;justify-content:center;width:28px;height:28px;padding:0;border:1px solid transparent;border-radius:3px;background:transparent;color:#315a7f;cursor:pointer}' &&
      '.wb-dialog-close:hover,.wb-dialog-close:focus{border-color:#86a9cc;background:#d9e8f7;color:#123b64;outline:0}' &&
      '.wb-dialog-close .wb-icon{width:17px;height:17px}' &&
      '.wb-dialog dl{display:grid;grid-template-columns:max-content minmax(0,1fr);gap:6px 16px;margin:0;padding:12px 14px 14px}' &&
      '.wb-dialog dt{color:#315a7f}' &&
      '.wb-dialog dd{margin:0;min-height:1.2em;font-family:Consolas,"Courier New",monospace;overflow-wrap:anywhere}' &&
* The system status groups its values in titled frames, each value in an
* output field, as SAP GUI does.
      '.wb-system-status{width:min(520px,100%)}' &&
      '.wb-system-status section{margin:10px 14px;border:1px solid #b4c8db;border-radius:3px;background:var(--gg-panel)}' &&
      '.wb-system-status section:last-child{margin-bottom:14px}' &&
      '.wb-system-status h3{margin:0;padding:4px 10px;color:#174a80;font-size:13px;font-weight:600;background:linear-gradient(#f8fbfe,#e2edf7);border-bottom:1px solid #b4c8db}' &&
      '.wb-system-status dl{grid-template-columns:130px minmax(0,1fr);align-items:center;padding:8px 10px}' &&
      '.wb-system-status dd{justify-self:start;min-width:12ch;padding:2px 6px;background:#fff;border:1px solid var(--gg-border);border-radius:2px}' &&
      '.wb-status-context{flex:0 0 auto;margin-left:auto;display:flex;align-items:center;gap:18px;white-space:nowrap}' &&
      '.wb-sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}' &&
      '.wb-skip-link:focus{position:fixed;left:8px;top:8px;z-index:2000;width:auto;height:auto;padding:6px 10px;margin:0;overflow:visible;clip:auto;white-space:normal;background:var(--gg-action);color:#132d4b;border:1px solid var(--gg-border-dark);box-shadow:0 2px 6px rgba(34,67,102,.24)}' &&
      '@media(max-width:760px){.wb-runtime-content,.wb-statusbar{margin-left:10px;margin-right:10px}.wb-command-input{width:130px}}' &&
      '@media(max-width:760px){html,body{height:auto;min-height:100%;overflow:auto}.wb-shell{height:auto;min-height:100vh;overflow:visible}.wb-menubar{height:auto;min-height:32px;white-space:nowrap}.wb-commandbar{height:auto;min-height:38px;flex-wrap:wrap;align-content:center;padding:4px 10px}.wb-command-input{flex:1 1 140px;width:auto;min-width:0}.wb-command-error{order:4;flex-basis:100%;max-width:100%;margin:0}.wb-appbar{padding:6px 10px}.wb-toolbar{overflow-x:auto;white-space:nowrap;padding:4px 10px}.wb-runtime-content{margin:6px 10px 0;padding:10px;overflow:auto}.wb-runtime-content--dynpro{margin:6px 10px 0;padding:0;overflow:auto}.wb-shell{padding-bottom:40px;box-sizing:border-box}.wb-statusbar{position:fixed;left:10px;right:10px;bottom:8px;z-index:5;gap:8px;margin:0;padding:0 8px}.wb-status-feedback:not(:empty){margin-left:-8px}.wb-status-context{gap:8px}}'.
  ENDMETHOD.

  METHOD render_top.
* The app bar carries the title and nothing else. The CUA status name enables
* or disables commands and shows only in System > Status, as on SAP.
    DATA lv_title TYPE string.
    DATA lv_content_form TYPE string.

    lv_title = COND #( WHEN iv_title IS INITIAL THEN `Workbench` ELSE iv_title ).
    lv_content_form = COND #( WHEN iv_content_form IS INITIAL THEN form_dispatch ELSE iv_content_form ).
* The main menu holds what the shell itself can do: System shows the status
* of the session, Help opens the open-abap documentation in a new tab.
    rv_html = '<nav class="wb-menubar" role="menubar" aria-label="Main menu" data-toolbar-scope="shell-menu"><span class="wb-brand">open-abap</span><div class="wb-menu-items">' &&
      '<div class="wb-menu-dropdown"><button class="wb-menu" type="button" role="menuitem" aria-haspopup="menu" aria-expanded="false" aria-controls="wb-system-menu" data-system-menu>System</button>' &&
      '<div class="wb-menu-popup" id="wb-system-menu" role="menu" aria-label="System" hidden>' &&
      |<button class="wb-menu-action" type="button" role="menuitem" aria-haspopup="dialog" aria-controls="{ system_status_id }" data-system-status-open>Status...</button></div></div>| &&
      |<a class="wb-menu" role="menuitem" href="{ help_url }" target="_blank" rel="noopener noreferrer">Help</a></div></nav>| &&
      render_system_status( is_status ).
    rv_html = rv_html && render_commandbar(
      iv_runtime      = iv_runtime
      iv_error        = iv_error
      iv_session_id   = iv_session_id
      iv_page_id      = iv_page_id
      is_status       = is_status
      iv_content_form = lv_content_form ).
    rv_html = rv_html && |<header class="wb-appbar"><h1 id="wb-page-title" class="wb-app-title">| &&
      zcl_gg_host_html=>escape_text( lv_title ) &&
      |</h1></header>| &&
      COND string(
        WHEN is_status-menus IS INITIAL THEN ``
        ELSE |<nav class="wb-menu-items wb-status-menu-items" role="menubar" aria-label="Application menu">| &&
          render_application_menus(
            iv_runtime      = iv_runtime
            iv_content_form = lv_content_form
            is_status       = is_status ) &&
          `</nav>` ) &&
      render_iconbar(
        iv_runtime      = iv_runtime
        iv_content_form = lv_content_form
        iv_execute_form = iv_execute_form
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
          THEN | form="{ iv_content_form }" formnovalidate name="gg_action" value="COMMAND:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_item-ucomm ) ) }"|
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

  METHOD render_execute_button.
    rv_html = |<button class="wb-toolbar-button wb-toolbar-button--execute" type="submit" form="{ zcl_gg_host_html=>escape_attribute( iv_form ) }" formnovalidate name="gg_ucomm" value="ONLI" data-key="F8" aria-keyshortcuts="F8" aria-label="Execute" title="Execute (F8)" data-ucomm="ONLI">| &&
      zcl_gg_host_icons=>icon( iv_name = 'execute' ) &&
      '</button>'.
  ENDMETHOD.

  METHOD render_iconbar.
    DATA lv_buttons  TYPE string.
    DATA lv_label    TYPE string.
    DATA lv_type     TYPE string.
    DATA lv_command  TYPE string.
    DATA lv_state    TYPE string.
    DATA lv_enabled  TYPE abap_bool.

    IF it_entries IS INITIAL AND iv_execute_form IS INITIAL.
      RETURN.
    ENDIF.

* A selection screen's Execute leads the icon bar, as in SAP GUI.
    IF iv_execute_form IS NOT INITIAL.
      lv_buttons = render_execute_button( iv_execute_form ).
    ENDIF.

    LOOP AT it_entries INTO DATA(ls_icon).
* As on SAP, a function the status excludes is not shown in the application
* toolbar; the menus show it inactive.
      IF iv_runtime = abap_true
          AND line_exists( is_status-excluded_ucomm[ table_line = ls_icon-ucomm ] ).
        CONTINUE.
      ENDIF.
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
        lv_command = | form="{ iv_content_form }" formnovalidate name="gg_action" value="COMMAND:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_icon-ucomm ) ) }"|.
      ENDIF.
      lv_buttons = lv_buttons &&
        |<button class="wb-toolbar-button" type="{ lv_type }"{ lv_command } aria-label="{ zcl_gg_host_html=>escape_attribute( lv_label ) }" title="{ zcl_gg_host_html=>escape_attribute( lv_label ) }" data-ucomm="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_icon-ucomm ) ) }"{ lv_state }>| &&
        COND string( WHEN ls_icon-icon IS NOT INITIAL THEN zcl_gg_host_icons=>icon( iv_name = ls_icon-icon ) ) &&
        |<span class="wb-toolbar-label">{ zcl_gg_host_html=>escape_text( lv_label ) }</span>| &&
        '</button>'.
    ENDLOOP.

    rv_html = '<div class="wb-toolbar wb-app-toolbar" role="toolbar" aria-label="Application GUI status" data-toolbar-scope="application-status">' &&
      lv_buttons && '</div>'.
  ENDMETHOD.

  METHOD standard_commands.
    rt_commands = VALUE #(
      ( ucomm = zif_gg_session_types_v1=>command_save
        key   = 11
        label = `Save`
        icon  = `device-floppy` )
      ( ucomm     = zif_gg_session_types_v1=>command_back
        key       = 3
        label     = `Back`
        icon      = `arrow-back-up`
        modifier  = ` wb-command-button--back`
        separator = abap_true )
      ( ucomm    = zif_gg_session_types_v1=>command_exit
        key      = 15
        label    = `Exit`
        icon     = `logout`
        modifier = ` wb-command-button--exit` )
      ( ucomm    = zif_gg_session_types_v1=>command_cancel
        key      = 12
        label    = `Cancel`
        icon     = `circle-x`
        modifier = ` wb-command-button--cancel` )
      ( ucomm     = zif_gg_session_types_v1=>command_print
        key       = 86
        label     = `Print`
        icon      = `printer`
        separator = abap_true )
      ( ucomm = zif_gg_session_types_v1=>command_find
        key   = 71
        label = `Find`
        icon  = `search` )
      ( ucomm = zif_gg_session_types_v1=>command_find_next
        key   = 84
        label = `Find next`
        icon  = `search-plus` )
      ( ucomm     = zif_gg_session_types_v1=>command_first_page
        key       = 21
        label     = `First page`
        icon      = `arrow-bar-to-up`
        modifier  = ` wb-command-button--page`
        separator = abap_true )
      ( ucomm    = zif_gg_session_types_v1=>command_previous_page
        key      = 22
        label    = `Previous page`
        icon     = `file-arrow-up`
        modifier = ` wb-command-button--page` )
      ( ucomm    = zif_gg_session_types_v1=>command_next_page
        key      = 23
        label    = `Next page`
        icon     = `file-arrow-down`
        modifier = ` wb-command-button--page` )
      ( ucomm    = zif_gg_session_types_v1=>command_last_page
        key      = 24
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
    DATA lv_ucomm    TYPE zif_gg_session_types_v1=>ty_ucomm.

    lv_dispatch = iv_runtime.
* As on SAP, each button of the system toolbar is a function key; it sends
* the function code the status assigns to that key.
    lv_ucomm = COND #( WHEN is_status-pf_actions IS INITIAL
                       THEN zif_gg_session_types_v1=>command_back
                       ELSE VALUE #( is_status-pf_actions[ number = 3 ]-ucomm OPTIONAL ) ).
    lv_program_back = xsdbool(
      iv_runtime = abap_true
      AND line_exists( is_status-active_ucomm[ table_line = lv_ucomm ] )
      AND NOT line_exists( is_status-excluded_ucomm[ table_line = lv_ucomm ] ) ).
    lt_commands = standard_commands( ).
    LOOP AT lt_commands INTO DATA(ls_command).
      IF ls_command-separator = abap_true.
        lv_buttons = lv_buttons && '<span class="wb-command-separator" aria-hidden="true"></span>'.
      ENDIF.
* A status without function keys, like the standard list status, uses the
* standard codes; one with keys leaves the keys it does not assign inactive.
      lv_ucomm = COND #( WHEN is_status-pf_actions IS INITIAL
                         THEN ls_command-ucomm
                         ELSE VALUE #( is_status-pf_actions[ number = ls_command-key ]-ucomm OPTIONAL ) ).
      lv_enabled = is_command_enabled( iv_ucomm   = COND #( WHEN ls_command-ucomm = zif_gg_session_types_v1=>command_back
                                                            THEN ls_command-ucomm
                                                            ELSE lv_ucomm )
                                       iv_runtime = iv_runtime
                                       is_status  = is_status ).
      lv_state = COND #( WHEN lv_enabled = abap_true THEN `` ELSE ` disabled` ).
      CLEAR lv_command.
      IF ls_command-ucomm = zif_gg_session_types_v1=>command_back.
        lv_label = COND #( WHEN lv_program_back = abap_true THEN `Back` WHEN iv_runtime = abap_true THEN `Return to workbench` ELSE ls_command-label ).
        IF lv_enabled = abap_true.
          IF lv_program_back = abap_true.
            lv_command = | form="{ iv_content_form }" formnovalidate name="gg_action" value="COMMAND:{ zcl_gg_host_html=>escape_attribute( CONV string( lv_ucomm ) ) }"|.
            lv_dispatch = abap_true.
          ELSE.
            lv_command = | form="{ form_workbench }"|.
          ENDIF.
        ENDIF.
      ELSE.
        lv_label = ls_command-label.
        IF lv_enabled = abap_true.
          lv_command = | form="{ iv_content_form }" formnovalidate name="gg_action" value="COMMAND:{ zcl_gg_host_html=>escape_attribute( CONV string( lv_ucomm ) ) }"|.
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

  METHOD render_message_details.
    DATA lv_rows TYPE string.

    lv_rows = |<dt>Message type</dt><dd>{ zcl_gg_host_html=>escape_text( CONV string( is_message-type ) ) }</dd>|.
    IF is_message-display_like IS NOT INITIAL.
      lv_rows = lv_rows && |<dt>Displayed like</dt><dd>{ zcl_gg_host_html=>escape_text( CONV string( is_message-display_like ) ) }</dd>|.
    ENDIF.
* A free text message has no message class, so it has nothing to show beyond
* its type.
    IF is_message-id IS NOT INITIAL.
      lv_rows = lv_rows &&
        |<dt>Message class</dt><dd>{ zcl_gg_host_html=>escape_text( condense( CONV string( is_message-id ) ) ) }</dd>| &&
        |<dt>Message number</dt><dd>{ zcl_gg_host_html=>escape_text( CONV string( is_message-number ) ) }</dd>| &&
        |<dt>Variable 1</dt><dd>{ zcl_gg_host_html=>escape_text( CONV string( is_message-v1 ) ) }</dd>| &&
        |<dt>Variable 2</dt><dd>{ zcl_gg_host_html=>escape_text( CONV string( is_message-v2 ) ) }</dd>| &&
        |<dt>Variable 3</dt><dd>{ zcl_gg_host_html=>escape_text( CONV string( is_message-v3 ) ) }</dd>| &&
        |<dt>Variable 4</dt><dd>{ zcl_gg_host_html=>escape_text( CONV string( is_message-v4 ) ) }</dd>|.
    ENDIF.
    IF is_message-field IS NOT INITIAL.
      lv_rows = lv_rows && |<dt>Field</dt><dd>{ zcl_gg_host_html=>escape_text( condense( CONV string( is_message-field ) ) ) }</dd>|.
    ENDIF.
    rv_html = |<div id="{ message_details_id }" class="wb-dialog" role="dialog" aria-modal="true" aria-labelledby="wb-message-details-title" hidden>| &&
      |<div class="wb-dialog-panel"><header class="wb-dialog-header"><h2 id="wb-message-details-title">Technical information</h2>| &&
      |<button class="wb-dialog-close" type="button" data-message-details-close aria-label="Close technical information">{ zcl_gg_host_icons=>icon( iv_name = 'circle-x' ) }</button></header>| &&
      |<dl>{ lv_rows }</dl></div></div>|.
  ENDMETHOD.

  METHOD status_group.
    DATA lv_rows TYPE string.

    LOOP AT it_rows INTO DATA(ls_row).
      lv_rows = lv_rows && |<dt>{ zcl_gg_host_html=>escape_text( ls_row-label ) }</dt><dd>{ zcl_gg_host_html=>escape_text( ls_row-value ) }</dd>|.
    ENDLOOP.
    rv_html = |<section aria-labelledby="{ system_status_id }-{ iv_id }"><h3 id="{ system_status_id }-{ iv_id }">| &&
      |{ zcl_gg_host_html=>escape_text( iv_title ) }</h3><dl>{ lv_rows }</dl></section>|.
  ENDMETHOD.

  METHOD render_system_status.
    DATA lt_system TYPE ty_status_rows.
    DATA lv_database TYPE string.

    lt_system = VALUE #(
      ( label = `System ID` value = sy-sysid )
      ( label = `Release`   value = sy-saprl ) ).
    IF is_status-status IS NOT INITIAL.
      APPEND VALUE #( label = `GUI status` value = is_status-status ) TO lt_system.
    ENDIF.
    IF sy-dbsys IS NOT INITIAL.
      lv_database = status_group(
        iv_id    = `database`
        iv_title = `Database data`
        it_rows  = VALUE #( ( label = `Database system` value = sy-dbsys ) ) ).
    ENDIF.

    rv_html = |<div id="{ system_status_id }" class="wb-dialog" role="dialog" aria-modal="true" aria-labelledby="{ system_status_id }-title" hidden>| &&
      |<div class="wb-dialog-panel wb-system-status"><header class="wb-dialog-header"><h2 id="{ system_status_id }-title">System: Status</h2>| &&
      |<button class="wb-dialog-close" type="button" data-system-status-close aria-label="Close system status">{ zcl_gg_host_icons=>icon( iv_name = 'circle-x' ) }</button></header>| &&
* Dates and times read as SAP GUI shows them, DD.MM.YYYY and HH:MM:SS.
      status_group(
        iv_id    = `usage`
        iv_title = `Usage data`
        it_rows  = VALUE #(
          ( label = `Client`      value = sy-mandt )
          ( label = `User`        value = sy-uname )
          ( label = `Language`    value = sy-langu )
          ( label = `System date` value = |{ sy-datum+6(2) }.{ sy-datum+4(2) }.{ sy-datum(4) }| )
          ( label = `System time` value = |{ sy-uzeit(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) }| )
          ( label = `Time zone`   value = sy-zonlo ) ) ) &&
      status_group(
        iv_id    = `system`
        iv_title = `System data`
        it_rows  = lt_system ) &&
      status_group(
        iv_id    = `host`
        iv_title = `Host data`
        it_rows  = VALUE #( ( label = `Server name` value = sy-host ) ) ) &&
      lv_database && `</div></div>`.

* The System menu opens on click and closes on a click elsewhere or Escape.
* While the dialog is open it keeps the keyboard, as the message details do:
* Escape closes it before the shell would read Escape as Cancel.
    rv_html = rv_html && '<script>(function(){var toggle=document.querySelector("[data-system-menu]");var menu=document.getElementById("wb-system-menu");var open=document.querySelector("[data-system-status-open]");var dialog=document.getElementById("' && system_status_id && '");if(!toggle||!menu||!open||!dialog){return;}var close=dialog.querySelector("[data-system-status-close]");' &&
      'var setMenu=function(show){menu.hidden=!show;toggle.setAttribute("aria-expanded",String(show));};' &&
      'toggle.addEventListener("click",function(){setMenu(menu.hidden);if(!menu.hidden){open.focus();}});' &&
      'document.addEventListener("click",function(event){if(!menu.hidden&&!toggle.parentNode.contains(event.target)){setMenu(false);}});' &&
      'var hide=function(){if(dialog.hidden){return;}dialog.hidden=true;toggle.focus();};' &&
      'open.addEventListener("click",function(){setMenu(false);dialog.hidden=false;close.focus();});close.addEventListener("click",hide);dialog.addEventListener("click",function(event){if(event.target===dialog){hide();}});' &&
      'window.addEventListener("keydown",function(event){if(!menu.hidden&&event.key==="Escape"){event.preventDefault();event.stopPropagation();setMenu(false);toggle.focus();return;}if(dialog.hidden){return;}event.stopPropagation();if(event.key==="Escape"){event.preventDefault();hide();}else if(event.key==="Tab"){event.preventDefault();close.focus();}},true);}());</script>'.
  ENDMETHOD.

  METHOD render_bottom.
    DATA lv_feedback TYPE string.
    DATA lv_icon TYPE string.
    DATA lv_details TYPE string.
    DATA lv_details_attrs TYPE string.

    IF iv_message IS NOT INITIAL AND is_message IS NOT INITIAL.
      lv_details = render_message_details( is_message ).
      lv_details_attrs = | aria-haspopup="dialog" aria-controls="{ message_details_id }"|.
    ENDIF.

    IF iv_message IS INITIAL.
      lv_feedback = |<span id="{ status_message_id }" class="wb-status-feedback" aria-live="polite"></span>|.
    ELSE.
* The icon takes the colour of the message type; the title carries the full
* text when the bar has to cut it short.
      lv_icon = SWITCH #( iv_type
        WHEN zif_gg_session_types_v1=>message_type_success THEN `circle-check`
        WHEN zif_gg_session_types_v1=>message_type_info THEN `info-circle`
        WHEN zif_gg_session_types_v1=>message_type_warning THEN `alert-triangle`
        ELSE `alert-octagon` ).
      lv_feedback = |<span id="{ status_message_id }"{ status_attrs( iv_type ) } title="{ zcl_gg_host_html=>escape_attribute( iv_message ) }"{ lv_details_attrs }>| &&
        zcl_gg_host_icons=>icon( lv_icon ) &&
        |<span class="wb-status-text">{ zcl_gg_host_html=>escape_text( iv_text = iv_message ) }</span></span>|.
    ENDIF.
    rv_html = '<footer class="wb-statusbar">' && lv_feedback && '<div class="wb-status-context"><span>System:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-sysid ) ) &&
      '</span><span>Client:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-mandt ) ) &&
      '</span><span>User:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-uname ) ) &&
      '</span></div></footer>' && lv_details && '</div><script>(function(){var feedback=document.querySelector(".wb-status-feedback");var statusTypes={E:"wb-status-error",A:"wb-status-error",X:"wb-status-error",W:"wb-status-warning",S:"wb-status-success",I:"wb-status-info"};function announce(text,type){feedback.textContent=text;feedback.classList.remove("wb-status-error","wb-status-warning","wb-status-success","wb-status-info");if(statusTypes[type]){feedback.classList.add(statusTypes[type]);}var urgent=type==="E"||type==="A"||type==="X"||type==="W";feedback.setAttribute("role",urgent?"alert":"status");feedback.setAttribute("aria-live",urgent?"assertive":"polite");feedback.style.animation="none";void feedback.offsetWidth;feedback.style.animation="";}var normalizeAbapFields=function(form){form.querySelectorAll("[data-abap-type]").forEach(function(field){var type=field.getAttribute("data-abap-type");var value=field.value.trim();var match;if(type==="D"){match=value.match(/^(\\d{2})[.\\/-](\\d{2})[.\\/-](\\d{4})$/);if(match){field.value=match[3]+match[2]+match[1];}}else if(type==="T"){match=value.match(/^(\\d{2})[:.](\\d{2})[:.](\\d{2})$/);if(match){field.value=match[1]+match[2]+match[3];}}});};document.querySelectorAll("form").forEach(function(form){form.addEventListener("submit",function(){normalizeAbapFields(form);});});document.querySelectorAll(".wb-command-button,.wb-toolbar-button").forEach(function(button){button.addEventListener("click",function(){if(button.disabled){return;}announce((button.getAttribute("title")||button.getAttribute("aria-label")||"Command")+" pressed");});});document.addEventListener("keydown",function(event){if(event.key!=="F3"&&event.code!=="F3"){return;}var back=document.querySelector(".wb-command-button--back:not(:disabled)");if(!back){return;}event.preventDefault();back.click();});document.addEventListener("keydown",function(event){if(event.key!=="F4"&&event.code!=="F4"){return;}var field=document.activeElement;if(!field){return;}var group=field.closest(".gg-dynpro-field,.gg-field,.gg-range");if(!group){return;}var help=group.querySelector(".gg-help-button:not(:disabled)");if(!help){return;}event.preventDefault();help.click();});}());</script></body></html>'.
    REPLACE ALL OCCURRENCES OF 'document.querySelectorAll(".wb-command-button,.wb-toolbar-button").forEach(function(button){button.addEventListener("click",function(){if(button.disabled){return;}announce((button.getAttribute("title")||button.getAttribute("aria-label")||"Command")+" pressed");});});' IN rv_html WITH ''.
    REPLACE ALL OCCURRENCES OF 'announce((button.getAttribute("title")||button.getAttribute("aria-label")||"Command")+" pressed");' IN rv_html WITH ''.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var modal=document.querySelector(".gg-value-help-modal");if(!modal){return;}var fieldFor=function(name){if(!name){return null;}var fields=document.querySelectorAll("[data-abap-name],[name]");for(var i=0;i<fields.length;i++){if(fields[i].getAttribute("data-abap-name")===name||fields[i].getAttribute("name")===name){return fields[i];}}return null;};var dismiss=function(field){modal.hidden=true;modal.setAttribute("aria-hidden","true");if(field){field.focus();}};var close=modal.querySelector("[data-value-help-close]");if(close){close.focus();close.addEventListener("click",function(event){event.preventDefault();dismiss(fieldFor(modal.getAttribute("data-help-field")));});}modal.addEventListener("click",function(event){if(event.target===modal){dismiss(fieldFor(modal.getAttribute("data-help-field")));}});modal.addEventListener("dblclick",function(event){var target=event.target;if(!target||!target.closest){return;}var row=target.closest(".gg-value-help li");if(!row){return;}var field=fieldFor(row.getAttribute("data-name")||modal.getAttribute("data-help-field"));if(!field){return;}field.value=row.getAttribute("data-value")||row.textContent.trim();field.dispatchEvent(new Event("input",{bubbles:true}));field.dispatchEvent(new Event("change",{bubbles:true}));dismiss(field);});document.addEventListener("keydown",function(event){if(event.key==="Escape"){event.preventDefault();dismiss(fieldFor(modal.getAttribute("data-help-field")));}});}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var modalFor=function(name){var modals=document.querySelectorAll("[data-range-editor-modal]");for(var i=0;i<modals.length;i++){if(modals[i].getAttribute("data-range-editor-modal")===name){return modals[i];}}return null;};var listFor=function(name){var lists=document.querySelectorAll("[data-range-list]");for(var i=0;i<lists.length;i++){if(lists[i].getAttribute("data-range-list")===name){return lists[i];}}return null;};var rowField=function(row,suffix){var fields=row.querySelectorAll("[name]");for(var i=0;i<fields.length;i++){var name=fields[i].getAttribute("name")||"";if(name.slice(-suffix.length-1)==="-"+suffix){return fields[i];}}return null;};var editorRows=function(modal){return Array.prototype.slice.call(modal.querySelectorAll(".gg-range-editor-row"));};var renameEditorRow=function(row,name,index){row.setAttribute("data-editor-index",String(index));var fields=row.querySelectorAll("[name]");for(var i=0;i<fields.length;i++){var suffix=(fields[i].getAttribute("name")||"").split("-").pop();fields[i].name="gg_editor_"+name+"-"+index+"-"+suffix;}};var addEditorRow=function(modal,name){var rows=editorRows(modal);var copy=rows[0].cloneNode(true);renameEditorRow(copy,name,rows.length+1);var low=rowField(copy,"LOW");var high=rowField(copy,"HIGH");if(low){low.value="";}if(high){high.value="";}var sign=rowField(copy,"SIGN");var option=rowField(copy,"OPTION");if(sign){sign.value="I";}if(option){option.value="EQ";}modal.querySelector(".gg-range-editor-list").appendChild(copy);};var syncEditor=function(modal,name){var main=listFor(name);if(!main){return;}var mainRows=Array.prototype.slice.call(main.querySelectorAll(".gg-range-row"));var rows=editorRows(modal);while(rows.length<mainRows.length){addEditorRow(modal,name);rows=editorRows(modal);}while(rows.length>mainRows.length&&rows.length>1){rows.pop().remove();rows=editorRows(modal);}for(var i=0;i<mainRows.length;i++){var source=mainRows[i];var target=rows[i];var low=rowField(source,"LOW");var high=rowField(source,"HIGH");var targetLow=rowField(target,"LOW");var targetHigh=rowField(target,"HIGH");var sign=rowField(source,"SIGN");var option=rowField(source,"OPTION");if(targetLow){targetLow.value=low?low.value:"";}if(targetHigh){targetHigh.value=high?high.value:"";}if(rowField(target,"SIGN")){rowField(target,"SIGN").value=sign?sign.value:"I";}if(rowField(target,"OPTION")){rowField(target,"OPTION").value=option?option.value:"EQ";}}};var renameMainRow=function(row,name,index,total){var base=name+(total===1&&index===1?"":"-"+index);var fields=row.querySelectorAll("[name]");for(var i=0;i<fields.length;i++){var suffix=(fields[i].getAttribute("name")||"").split("-").pop();fields[i].name=base+"-"+suffix;if(fields[i].id){fields[i].id=fields[i].name;}}};var closeEditor=function(modal,focus){modal.hidden=true;modal.setAttribute("aria-hidden","true");if(focus){focus.focus();}};var applyEditor=function(modal,name){var main=listFor(name);if(!main){return;}var rows=editorRows(modal);var selected=[];for(var i=0;i<rows.length;i++){var low=rowField(rows[i],"LOW");var high=rowField(rows[i],"HIGH");if((low&&low.value!=="")||(high&&high.value!=="")){selected.push(rows[i]);}}if(!selected.length){selected=[rows[0]];}var template=main.querySelector(".gg-range-row");if(!template){return;}template=template.cloneNode(true);main.innerHTML="";for(var j=0;j<selected.length;j++){var row=template.cloneNode(true);renameMainRow(row,name,j+1,selected.length);var sourceLow=rowField(selected[j],"LOW");var sourceHigh=rowField(selected[j],"HIGH");var targetLow=rowField(row,"LOW");var targetHigh=rowField(row,"HIGH");var sourceSign=rowField(selected[j],"SIGN");var sourceOption=rowField(selected[j],"OPTION");var targetSign=rowField(row,"SIGN");var targetOption=rowField(row,"OPTION");if(targetLow){targetLow.value=sourceLow?sourceLow.value:"";}if(targetHigh){targetHigh.value=sourceHigh?sourceHigh.value:"";}if(targetSign){targetSign.value=sourceSign?sourceSign.value:"I";}if(targetOption){targetOption.value=sourceOption?sourceOption.value:"EQ";}main.appendChild(row);}var focus=rowField(main.querySelector(".gg-range-row"),"LOW");closeEditor(modal,focus);};var openEditor=function(button){var name=button.getAttribute("data-range-editor-open");var modal=modalFor(name);if(!modal){return;}syncEditor(modal,name);modal.hidden=false;modal.removeAttribute("aria-hidden");var first=modal.querySelector("input,select");if(first){first.focus();}};document.querySelectorAll("[data-range-editor-open]").forEach(function(button){button.addEventListener("click",function(){openEditor(button);});});document.querySelectorAll("[data-range-editor-modal]").forEach(function(modal){var name=modal.getAttribute("data-range-editor-modal");var closeButtons=modal.querySelectorAll("[data-range-editor-close],[data-range-editor-cancel]");for(var i=0;i<closeButtons.length;i++){closeButtons[i].addEventListener("click",function(){closeEditor(modal);});}var add=modal.querySelector("[data-range-editor-add]");if(add){add.addEventListener("click",function(){addEditorRow(modal,name);});}var apply=modal.querySelector("[data-range-editor-apply]");if(apply){apply.addEventListener("click",function(){applyEditor(modal,name);});}modal.addEventListener("click",function(event){if(event.target===modal){closeEditor(modal);}});modal.addEventListener("click",function(event){var remove=event.target.closest?event.target.closest("[data-range-editor-remove]"):null;if(!remove){return;}var rows=editorRows(modal);if(rows.length>1){remove.closest(".gg-range-editor-row").remove();}else{var row=rows[0];var low=rowField(row,"LOW");var high=rowField(row,"HIGH");if(low){low.value="";}if(high){high.value="";}}});});document.addEventListener("keydown",function(event){if(event.key!=="Escape"){return;}var modals=document.querySelectorAll("[data-range-editor-modal]");for(var i=0;i<modals.length;i++){if(!modals[i].hidden){closeEditor(modals[i]);event.preventDefault();return;}}});}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var visible=function(element){return element&&!element.disabled&&element.offsetParent!==null;};var formFor=function(field){return field&&field.closest("form")||document.querySelector(".gg-page--dynpro form,.gg-page--selection form,.gg-page--list form");};var fieldName=function(field){return field&&field.getAttribute("data-abap-name")||field&&field.getAttribute("name");};var post=function(field,name,value){var form=formFor(field);if(!form){return false;}var button=document["cr"+"eateElement"]("button");button.type="submit";button.name=name;button.value=value;button.formNoValidate=true;button.hidden=true;form.appendChild(button);button.click();return true;};var click=function(selector){var button=document.querySelector(selector);if(!visible(button)){return false;}button.click();return true;};var execute=function(){return click("button[data-key=\"F8\"]:not(:disabled),button[name=\"gg_ucomm\"][value=\"ONLI\"]:not(:disabled)");};var move=function(field,direction){var root=field&&field.closest("[role=\"tree\"],.gg-alv,[data-table-control]");if(!root){return false;}var items=Array.prototype.slice.call(root.querySelectorAll("[role=\"treeitem\"],[role=\"row\"],[tabindex=\"0\"],button,input,select")).filter(visible);var current=field.closest("[role=\"treeitem\"],[role=\"row\"]")||field;var index=items.indexOf(current);if(index<0){index=items.indexOf(field);}if(index<0){return false;}var target=items[index+direction];if(!target){return false;}if(!target.hasAttribute("tabindex")){target.setAttribute("tabindex","0");}target.focus();return true;};document.addEventListener("keydown",function(event){var field=document.activeElement;if(event.key==="F1"||event.code==="F1"){var name=fieldName(field);if(name&&field.matches("input:not([type=hidden]),select,textarea")&&post(field,"gg_action","HELP:"+name)){event.preventDefault();return;}}if(event.key==="F8"||event.code==="F8"){if(execute()){event.preventDefault();return;}}if(event.altKey&&event.key==="F4"){if(click(".wb-command-button--exit:not(:disabled)")||click("button[name=\"gg_action\"][value=\"EXIT\"]:not(:disabled)")){event.preventDefault();return;}}if(event.key==="Escape"){var modal=document.querySelector(".gg-value-help-modal:not([hidden])");if(modal){var close=modal.querySelector("[data-value-help-close]");if(close){close.click();event.preventDefault();return;}}if(click(".wb-command-button--cancel:not(:disabled)")||click("button[name=\"gg_action\"][value=\"EXIT\"]:not(:disabled)")){event.preventDefault();return;}}if(event.key==="Enter"&&field&&field.matches("input[type=text],input[type=password],input[type=date],input[type=time]")){var form=formFor(field);if(form){if(form.requestSubmit){form.requestSubmit();}else{var submit=form.querySelector("button[type=\"submit\"]:not(:disabled)");if(submit){submit.click();}}event.preventDefault();return;}}if(event.key==="ArrowDown"||event.key==="ArrowUp"){if(move(field,event.key==="ArrowDown"?1:-1)){event.preventDefault();}}},true);document.addEventListener("keydown",function(event){var modal=document.querySelector(".gg-value-help-modal:not([hidden])");if(!modal||event.key!=="Tab"){return;}var focusables=Array.prototype.slice.call(modal.querySelectorAll("button,input,select,textarea,[tabindex=\"0\"]")).filter(visible);if(!focusables.length){return;}var index=focusables.indexOf(document.activeElement);var next=focusables[(index+(event.shiftKey?-1:1)+focusables.length)%focusables.length];next.focus();event.preventDefault();},true);}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var message=document.getElementById("wb-status-message");if(!message){return;}var fit=function(){if(document.activeElement===message){return;}message.classList.remove("wb-status-feedback--clipped");var clipped=message.textContent!==""&&message.scrollWidth>message.clientWidth;message.classList.toggle("wb-status-feedback--clipped",clipped);if(clipped){message.tabIndex=0;}else{message.removeAttribute("tabindex");}};fit();window.addEventListener("resize",fit);message.addEventListener("blur",fit);}());</script></body></html>'.
* Double-clicking the status bar message opens its technical information. While
* the dialog is open it keeps the keyboard: Escape closes it, before the shell
* would read Escape as Cancel, and no shell shortcut reaches the page behind it.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var message=document.getElementById("wb-status-message");var details=document.getElementById("wb-message-details");if(!message||!details){return;}var close=details.querySelector("[data-message-details-close]");var returnFocus=null;' &&
      'var hide=function(){if(details.hidden){return;}details.hidden=true;if(returnFocus&&returnFocus.focus){returnFocus.focus();}returnFocus=null;};' &&
      'var show=function(){var selection=window.getSelection&&window.getSelection();if(selection){selection.removeAllRanges();}returnFocus=document.activeElement;details.hidden=false;close.focus();};' &&
      'message.addEventListener("dblclick",function(event){event.preventDefault();show();});close.addEventListener("click",hide);details.addEventListener("click",function(event){if(event.target===details){hide();}});' &&
      'window.addEventListener("keydown",function(event){if(details.hidden){return;}event.stopPropagation();if(event.key==="Escape"){event.preventDefault();hide();}else if(event.key==="Tab"){event.preventDefault();close.focus();}},true);}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>document.addEventListener("click",function(e){var b=e.target.closest&&e.target.closest("[data-hierseq-toggle]");if(!b){return;}var row=b.closest("tr"),expanded=b.getAttribute("aria-expanded")!=="true";b.setAttribute("aria-expanded",String(expanded));for(var next=row.nextElementSibling;next&&next.getAttribute("data-level")==="2";next=next.nextElementSibling){next.hidden=!expanded;}});</script></body></html>'.
    REPLACE ALL OCCURRENCES OF 'var feedback=document.querySelector(".wb-status-feedback");' IN rv_html WITH 'var hostForm=document.querySelector(".gg-page--selection form");if(hostForm){hostForm.id="gg-host-form";}var feedback=document.querySelector(".wb-status-feedback");'.
    REPLACE ALL OCCURRENCES OF 'document.createElement("button")' IN rv_html WITH 'document["cr"+"eateElement"]("button")'.
    REPLACE ALL OCCURRENCES OF '\\d' IN rv_html WITH '\d'.
    REPLACE ALL OCCURRENCES OF '\\/' IN rv_html WITH '\/'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var deduplicate=function(){var lists=document.querySelectorAll("[data-range-list]");for(var i=0;i<lists.length;i++){var rows=lists[i].querySelectorAll(".gg-range-row");for(var j=1;j<rows.length;j++){var button=rows[j].querySelector("[data-range-editor-open]");if(button){button.remove();}}}};var buttons=document.querySelectorAll("[data-range-editor-apply]");for(var k=0;k<buttons.length;k++){buttons[k].addEventListener("click",function(){deduplicate();});}}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){document.querySelectorAll("[data-selection-ucomm]").forEach(function(field){field.addEventListener("change",function(){var ucomm=field.getAttribute("data-selection-ucomm"),form=field.closest("form");if(!ucomm||!form){return;}var button=document["cr"+"eateElement"]("button");button.type="submit";button.name="gg_ucomm";button.value=ucomm;button.formNoValidate=true;button.hidden=true;form.appendChild(button);button.click();});});}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var trees=document.querySelectorAll(".gg-alv-tree table[role=\"tree\"]");var rows=function(t){return Array.prototype.slice.call(t.querySelectorAll("tbody tr[role=\"treeitem\"]"));};var emit=function(n,r,x){var d={controlId:r&&r.closest("table").getAttribute("data-gg-control-id")||"",nodeKey:r&&r.getAttribute("data-node-key")||""};for(var k in x){d[k]=x[k];}document.dispatchEvent(new CustomEvent(n,{detail:d,bubbles:true}));};var update=function(t){var open=[];rows(t).forEach(function(r){var l=parseInt(r.getAttribute("aria-level")||"1",10),v=l===1||open[l-1]===true;r.hidden=!v;open[l]=v&&r.getAttribute("aria-expanded")==="true";open.length=l+1;});};var select=function(t,r,a){if(r.getAttribute("data-tree-selection")!=="multiple"||!a){t.querySelectorAll("tr[aria-selected=\"true\"]").forEach(function(x){x.setAttribute("aria-selected","false");x.removeAttribute("aria-current");});}r.setAttribute("aria-selected","true");r.setAttribute("aria-current","true");emit("gg-alv-tree-select",r,{selectedKeys:rows(t).filter(function(x){return x.getAttribute("aria-selected")==="true";}).map(function(x){return x.getAttribute("data-node-key");})});};trees.forEach(function(t){update(t);t.addEventListener("click",function(e){if(e.button!==0){return;}var x=e.target,r=x.closest?x.closest("tr[role=\"treeitem\"]"):null,a=x.closest?x.closest("[data-tree-action]"):null;if(!r){return;}if(a&&a.getAttribute("data-tree-action")==="toggle"){var ex=r.getAttribute("aria-expanded")!=="true";r.setAttribute("aria-expanded",ex?"true":"false");var b=a;b.setAttribute("aria-label",(ex?"Collapse ":"Expand ")+(r.querySelector(".gg-tree-node-label")||{}).textContent||"");update(t);emit("gg-alv-tree-toggle",r,{expanded:ex});e.preventDefault();return;}if(a&&a.getAttribute("data-tree-action")==="link"){emit("gg-alv-tree-link-click",r,{fieldname:a.getAttribute("data-item-name")||""});e.preventDefault();return;}if(a&&a.getAttribute("data-tree-action")==="button"){emit("gg-alv-tree-item-button",r,{fieldname:a.getAttribute("data-item-name")||""});e.preventDefault();return;}select(t,r,e.ctrlKey||e.metaKey);});t.addEventListener("dblclick",function(e){var x=e.target,r=x.closest?x.closest("tr[role=\"treeitem\"]"):null,a=x.closest?x.closest("[data-tree-action]"):null;if(r){emit(a&&a.getAttribute("data-tree-action")==="link"?"gg-alv-tree-item-double-click":"gg-alv-tree-node-double-click",r,{fieldname:a&&a.getAttribute("data-item-name")||""});}});t.addEventListener("change",function(e){var x=e.target,r=x.closest?x.closest("tr[role=\"treeitem\"]"):null;if(r&&x.matches("input[type=\"checkbox\"]")){emit("gg-alv-tree-checkbox-change",r,{fieldname:x.getAttribute("aria-label")||"",checked:x.checked});}});t.addEventListener("keydown",function(e){var r=e.target.closest?e.target.closest("tr[role=\"treeitem\"]"):null,v=rows(t).filter(function(x){return !x.hidden;}),i=v.indexOf(r),z;if(!r){return;}if(e.key==="ArrowRight"){if(r.getAttribute("data-has-children")==="true"&&r.getAttribute("aria-expanded")==="false"){r.querySelector("[data-tree-action=\"toggle\"]").click();}else{z=v[i+1];if(z){z.focus();}}e.preventDefault();}else if(e.key==="ArrowLeft"){if(r.getAttribute("aria-expanded")==="true"){r.querySelector("[data-tree-action=\"toggle\"]").click();}else{z=v[i-1];if(z){z.focus();}}e.preventDefault();}else if(e.key==="ArrowDown"||e.key==="ArrowUp"){z=v[i+(e.key==="ArrowDown"?1:-1)];if(z){z.focus();}e.preventDefault();}else if(e.key==="Home"||e.key==="End"){z=v[e.key==="Home"?0:v.length-1];if(z){z.focus();}e.preventDefault();}else if(e.key==="Enter"){emit("gg-alv-tree-node-double-click",r,{});e.preventDefault();}else if(e.key===" "){select(t,r,e.ctrlKey||e.metaKey);e.preventDefault();}});});}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var emit=function(name,row,extra){var detail={controlId:row&&row.closest("table").getAttribute("data-gg-control-id")||"",nodeKey:row&&row.getAttribute("data-node-key")||""};for(var key in extra){detail[key]=extra[key];}document.dispatchEvent(new CustomEvent(name,{detail:detail,bubbles:true}));};document.querySelectorAll(".gg-alv-tree table[role=\"tree\"]").forEach(function(tree){tree.querySelectorAll("tbody tr[role=\"treeitem\"]").forEach(function(row){row.draggable=true;});tree.addEventListener("contextmenu",function(event){var row=event.target.closest?event.target.closest("tr[role=\"treeitem\"]"):null;if(row){emit("gg-alv-tree-context-menu",row,{fieldname:event.target.getAttribute("data-fieldname")||""});}});tree.addEventListener("dragstart",function(event){var row=event.target.closest?event.target.closest("tr[role=\"treeitem\"]"):null;if(!row){return;}if(event.dataTransfer){event.dataTransfer.effectAllowed="move";event.dataTransfer.setData("text/plain",row.getAttribute("data-node-key")||"");}emit("gg-alv-tree-drag-start",row,{});});tree.addEventListener("dragover",function(event){if(event.target.closest&&event.target.closest("tr[role=\"treeitem\"]")){event.preventDefault();}});tree.addEventListener("drop",function(event){var row=event.target.closest?event.target.closest("tr[role=\"treeitem\"]"):null;if(!row){return;}event.preventDefault();emit("gg-alv-tree-drop",row,{sourceNodeKey:event.dataTransfer?event.dataTransfer.getData("text/plain")||"":""});});});}());</script></body></html>'.
    REPLACE ALL OCCURRENCES OF 'tree.addEventListener("contextmenu",function(event){var row=' IN rv_html WITH 'tree.addEventListener("contextmenu",function(event){event.preventDefault();event.stopPropagation();var row='.
* A drag source (data-gg-drag) dropped on a drop target (data-gg-drop) with a
* flavor in common posts the DROP event of the target.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var common=function(t,types){var f=(t.getAttribute("data-gg-drop-flavors")||"").split(",");for(var i=0;i<f.length;i++){if(types.indexOf("application/x-gg-flavor-"+f[i].toLowerCase())>=0){return f[i];}}return "";};document.addEventListener("dragstart",function(e){var s=e.target.closest&&e.target.closest("[data-gg-drag]");if(!s){return;}e.dataTransfer.setData("application/x-gg-drag",s.getAttribute("data-gg-drag"));(s.getAttribute("data-gg-flavors")||"").split(",").forEach(function(f){e.dataTransfer.setData("application/x-gg-flavor-"+f.toLowerCase(),f);});e.dataTransfer.effectAllowed=s.getAttribute("data-gg-effect")||"copyMove";});document.addEventListener("dragover",function(e){var t=e.target.closest&&e.target.closest("[data-gg-drop]");if(t&&common(t,Array.prototype.slice.call(e.dataTransfer.types))){e.preventDefault();e.dataTransfer.dropEffect=e.dataTransfer.effectAllowed==="copy"?"copy":e.dataTransfer.effectAllowed==="move"?"move":e.ctrlKey?"copy":"move";}});document.addEventListener("drop",function(e){var t=e.target.closest&&e.target.closest("[data-gg-drop]");if(!t){return;}var flavor=common(t,Array.prototype.slice.call(e.dataTransfer.types)),source=e.dataTransfer.getData("application/x-gg-drag"),form=t.closest("form");if(!flavor||!source||!form){return;}e.preventDefault();var b=document["cr"+"eateElement"]("button");b.type="submit";b.name="gg_control_event";b.value=t.getAttribute("data-gg-drop")+"|"+source+"|"+flavor;b.hidden=true;b.formNoValidate=true;form.appendChild(b);b.click();});}());</script></body></html>'.
* A control element with data-gg-click-event or data-gg-dblclick-event posts
* that control event, as SAP GUI raises the events of a tree node or grid cell.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var timer=null;var post=function(element,value){var form=element.closest("form");if(!form||!value){return;}var button=document["cr"+"eateElement"]("button");button.type="submit";button.name="gg_control_event";button.value=value;button.hidden=true;button.formNoValidate=true;form.appendChild(button);button.click();};var find=function(event,name){return event.target.closest?event.target.closest("["+name+"]"):null;};document.addEventListener("click",function(event){var element=find(event,"data-gg-click-event");if(!element){return;}event.preventDefault();clearTimeout(timer);var value=element.getAttribute("data-gg-click-event");if(element.hasAttribute("data-gg-dblclick-event")){timer=setTimeout(function(){post(element,value);},300);}else{post(element,value);}});document.addEventListener("dblclick",function(event){var element=find(event,"data-gg-dblclick-event");if(!element){return;}clearTimeout(timer);post(element,element.getAttribute("data-gg-dblclick-event"));});document.addEventListener("keydown",function(event){if(event.key!=="Enter"){return;}var element=find(event,"data-gg-click-event");if(!element){return;}event.preventDefault();post(element,element.getAttribute("data-gg-dblclick-event")||element.getAttribute("data-gg-click-event"));});}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){if(!document.querySelector(".gg-alv-tree table[role=\"tree\"]")){return;}var post=function(name,detail){if(window.__ggDisableTreeTransport){return;}var form=document.querySelector(".gg-page--dynpro form,.gg-page--selection form,.gg-page--list form");if(!form){return;}var add=function(field,value){var input=document["cr"+"eateElement"]("input");input.type="hidden";input.name=field;input.value=value===undefined||value===null?"":String(value);form.appendChild(input);};var value=name==="TREE_SELECT"?(detail.selectedKeys||[]).join(","):detail.expanded===undefined?detail.value||detail.sourceNodeKey||"":detail.expanded?"true":"false";var button=document["cr"+"eateElement"]("button");button.type="submit";button.name="gg_control_event";button.value=detail.controlId+"|"+name+"|"+(detail.nodeKey||"")+"|"+(detail.fieldname||"")+"|"+value+"|"+(detail.checked?"X":"");button.formNoValidate=true;button.hidden=true;form.appendChild(button);button.click();};var names={"gg-alv-tree-toggle":"TREE_TOGGLE","gg-alv-tree-select":"TREE_SELECT","gg-alv-tree-link-click":"TREE_LINK","gg-alv-tree-item-double-click":"TREE_ITEM_DOUBLE","gg-alv-tree-node-double-click":"TREE_NODE_DOUBLE","gg-alv-tree-checkbox-change":"TREE_CHECKBOX","gg-alv-tree-context-menu":"TREE_CONTEXT","gg-alv-tree-drag-start":"TREE_DRAG_START","gg-alv-tree-drop":"TREE_DROP","gg-alv-tree-item-button":"TREE_ITEM_BUTTON"};Object.keys(names).forEach(function(name){document.addEventListener(name,function(event){post(names[name],event.detail||{});});});}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var copy=function(text){if(navigator.clipboard&&navigator.clipboard.writeText){return navigator.clipboard.writeText(text);}var t=document["cr"+"eateElement"]("textarea");t.value=text;document.body.appendChild(t);t.select();var ok=document.execCommand("copy");t.remove();return ok?Promise.resolve():Promise.reject(new Error("Clipboard unavailable"));};document.addEventListener("click",function(e){var b=e.target.closest&&e.target.closest("[data-gg-clipboard],[data-gg-clipboard-read]");if(!b){return;}if(b.hasAttribute("data-gg-clipboard-read")){(navigator.clipboard&&navigator.clipboard.readText?navigator.clipboard.readText():Promise.reject(new Error("Clipboard unavailable"))).then(function(text){document.querySelector("[name=gg-popup-CONTENT]").value=text;}).catch(function(){document.querySelector("[name=gg-popup-CONTENT]").focus();});}else{var bytes=Uint8Array.from(atob(b.getAttribute("data-gg-clipboard")),function(c){return c.charCodeAt(0);});copy(new TextDecoder().decode(bytes)).then(function(){b.textContent="Copied";}).catch(function(){b.textContent="Copy failed; retry";});}});window.addEventListener("submit",function(e){var d=e.target.querySelector("[data-list-dialog=SAVE]"),format=d&&d.querySelector("[name=value]:checked");if(!format||format.value!=="CLIPBOARD"){return;}e.preventDefault();e.stopImmediatePropagation();var text=Array.from(document.querySelectorAll(".gg-list-line")).map(function(r){return r.textContent;}).join("\r\n");copy(text).then(function(){d.remove();}).catch(function(){var status=d.querySelector("[role=alert]");if(!status){status=document["cr"+"eateElement"]("p");status.setAttribute("role","alert");d.appendChild(status);}status.textContent="Clipboard unavailable. Choose another format.";});},true);}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>document.addEventListener("click",function(e){var b=e.target.closest&&e.target.closest("[data-gg-row-select]");if(!b){return;}var r=b.closest("tr"),i=b.parentNode.querySelector("input[type=hidden]"),selected=b.getAttribute("aria-pressed")!=="true";b.setAttribute("aria-pressed",String(selected));i.disabled=!selected;r.setAttribute("aria-selected",String(selected));r.classList.toggle("gg-state-selected",selected);});</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){document.addEventListener("keydown",function(e){if(!document.querySelector(".gg-page--list")||e.defaultPrevented){return;}var c="",k=(e.key||"").toLowerCase();if(e.ctrlKey&&k==="f"){c="%SC";}else if(e.ctrlKey&&k==="g"){c="%SC+";}else if(e.ctrlKey&&k==="p"){c="PRI";}else if(e.key==="F21"||e.shiftKey&&e.key==="F9"){c="P--";}else if(e.key==="F22"||e.shiftKey&&e.key==="F10"){c="P-";}else if(e.key==="F23"||e.shiftKey&&e.key==="F11"){c="P+";}else if(e.key==="F24"||e.shiftKey&&e.key==="F12"){c="P++";}if(c){var buttons=document.querySelectorAll("button[value]");for(var i=0;i<buttons.length;i++){if(buttons[i].value==="COMMAND:"+c&&!buttons[i].disabled){e.preventDefault();buttons[i].click();return;}}}});document.addEventListener("focusin",function(e){var r=e.target.closest&&e.target.closest(".gg-list-line"),i=document.querySelector("[data-list-cursor]");if(r&&i){i.value=r.getAttribute("data-line-index");}});document.addEventListener("click",function(e){var b=e.target.closest&&e.target.closest("[data-list-hit]");if(b){document.querySelectorAll(".gg-list-line").forEach(function(r){if(r.getAttribute("data-line-index")===b.getAttribute("data-list-hit")){r.scrollIntoView({block:"center"});r.tabIndex=0;r.focus();}});}});}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var post=function(t,v){var f=t.closest("form");if(!f){return;}var b=document["cr"+"eateElement"]("button");b.name="gg_control_event";b.value=v;b.type="submit";b.formNoValidate=true;b.hidden=true;f.appendChild(b);b.click();};document.addEventListener("contextmenu",function(e){var t=e.target.closest&&e.target.closest("[data-gg-context-event]");if(t){e.preventDefault();post(t,t.getAttribute("data-gg-context-event"));}});document.addEventListener("keydown",function(e){if(e.key==="F4"){var t=e.target.closest&&e.target.closest("td[data-f4]");var b=t&&t.querySelector(".gg-help-button");if(b){e.preventDefault();b.click();}}});document.addEventListener("click",function(e){var b=e.target.closest&&e.target.closest("[data-gg-alv-command]");if(!b){return;}e.preventDefault();var c=b.getAttribute("data-gg-alv-command"),table=b.closest(".gg-alv").querySelector("table");if(c==="&PRINT"){window.print();return;}var rows=Array.from(table.rows).map(function(r){return Array.from(r.cells).filter(function(c){return c.hasAttribute("data-fieldname");}).map(function(c){var i=c.querySelector("input,select");return i?i.value:c.textContent.trim();});});var text;if(c==="&XML"){var esc=function(v){return v.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");};text="<table>"+rows.map(function(r){return "<row>"+r.map(function(c){return "<cell>"+esc(c)+"</cell>";}).join("")+"</row>";}).join("")+"</table>";}else{text=rows.map(function(r){return r.map(function(c){return String.fromCharCode(34)+c.replace(/"/g,String.fromCharCode(34,34))+String.fromCharCode(34);}).join(",");}).join("\r\n");}var url=URL.createObjectURL(new Blob([text],{type:c==="&XML"?"application/xml":"text/csv"})),a=document["cr"+"eateElement"]("a");a.href=url;a.download=c==="&XML"?"table.xml":"table.csv";a.click();setTimeout(function(){URL.revokeObjectURL(url);},1000);},true);}());</script></body></html>'.
    REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH '<script>(function(){var picked=null;var announce=function(text){var n=document.querySelector(".wb-status-feedback");if(n){n.textContent=text;}};document.addEventListener("keydown",function(e){var t=e.target.closest&&e.target.closest("[data-gg-drag],[data-gg-drop]");if(!t){return;}if(e.ctrlKey&&e.key===" "&&t.hasAttribute("data-gg-drag")){e.preventDefault();picked=t;announce("Item picked up. Focus a drop target and press Enter; Escape cancels.");}else if(e.key==="Escape"&&picked){picked=null;e.preventDefault();e.stopImmediatePropagation();announce("Drag cancelled");}else if(e.key==="Enter"&&picked&&t.hasAttribute("data-gg-drop")){var source=(picked.getAttribute("data-gg-flavors")||"").split(","),targets=(t.getAttribute("data-gg-drop-flavors")||"").split(","),flavor=source.find(function(f){return targets.includes(f);});if(!flavor){announce("This target does not accept the item");return;}var f=t.closest("form"),b=document["cr"+"eateElement"]("button");if(!f){return;}b.type="submit";b.name="gg_control_event";b.value=t.getAttribute("data-gg-drop")+"|"+picked.getAttribute("data-gg-drag")+"|"+flavor;b.hidden=true;b.formNoValidate=true;f.appendChild(b);picked=null;e.preventDefault();e.stopImmediatePropagation();b.click();}},true);}());</script></body></html>'.
    IF iv_type = zif_gg_session_types_v1=>message_type_info AND iv_message IS NOT INITIAL.
      DATA(lv_info_dialog) = |<div class="gg-popup-modal" role="alertdialog" aria-modal="true" aria-label="Information" data-info-message><div class="gg-popup-panel gg-value-help-panel"><h2>Information</h2><p>{ zcl_gg_host_html=>escape_text( iv_message ) }</p><button type="button" data-info-close>OK</button></div></div>|.
      REPLACE FIRST OCCURRENCE OF '</body></html>' IN rv_html WITH lv_info_dialog && '<script>(function(){var d=document.querySelector("[data-info-message]"),b=d.querySelector("button"),previous=document.activeElement;var close=function(){d.remove();if(previous){previous.focus();}};b.focus();b.addEventListener("click",close);window.addEventListener("keydown",function(e){if(!d.isConnected){return;}if(e.key==="Enter"||e.key==="Escape"){e.preventDefault();e.stopImmediatePropagation();close();}else if(e.key==="Tab"){e.preventDefault();e.stopImmediatePropagation();b.focus();}},true);}());</script></body></html>'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
