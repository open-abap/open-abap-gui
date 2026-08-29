CLASS zcl_gg_workbench_utility DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS render_styles
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_top
      IMPORTING
        iv_runtime     TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_bottom
      RETURNING
        VALUE(rv_html) TYPE string.

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
    DATA lv_navigation_aria TYPE string.

    lv_navigation_aria = COND #( WHEN iv_runtime = abap_true THEN `Global command` ELSE `Back` ).
    rv_html = '<nav class="wb-menubar" role="menubar" aria-label="Main menu"><span class="wb-brand">open-abap</span><div class="wb-menu-items">' &&
      '<button class="wb-menu" type="button" role="menuitem">Applications</button><button class="wb-menu" type="button" role="menuitem">Edit</button><button class="wb-menu" type="button" role="menuitem">Favorites</button><button class="wb-menu" type="button" role="menuitem">Tools</button><button class="wb-menu" type="button" role="menuitem">System</button><button class="wb-menu" type="button" role="menuitem">Help</button></div></nav>'.
    rv_html = rv_html && '<section class="wb-commandbar" aria-label="Command bar"><label class="wb-sr-only" for="wb-command">Command</label><input class="wb-command-input" id="wb-command" type="text" placeholder="Command" autocomplete="off"><button class="wb-command-button" type="button" aria-label="Save" title="Save">' &&
      zcl_gg_host_icons=>icon( iv_name = `device-floppy` ) &&
      '</button><span class="wb-command-separator" aria-hidden="true"></span><button class="wb-command-button wb-command-button--back" type="button" aria-label="' && lv_navigation_aria && '" title="Back">' &&
      zcl_gg_host_icons=>icon( iv_name = `arrow-back-up` ) &&
      '</button><button class="wb-command-button wb-command-button--exit" type="button" aria-label="' && COND string( WHEN iv_runtime = abap_true THEN `Global command` ELSE `Exit` ) && '" title="Exit">' &&
      zcl_gg_host_icons=>icon( iv_name = `logout` ) &&
      '</button><button class="wb-command-button wb-command-button--cancel" type="button" aria-label="Cancel" title="Cancel">' &&
      zcl_gg_host_icons=>icon( iv_name = `circle-x` ) &&
      '</button><span class="wb-command-separator" aria-hidden="true"></span><button class="wb-command-button" type="button" aria-label="Print" title="Print">' &&
      zcl_gg_host_icons=>icon( iv_name = `printer` ) &&
      '</button><button class="wb-command-button" type="button" aria-label="Find" title="Find">' &&
      zcl_gg_host_icons=>icon( iv_name = `search` ) &&
      '</button><button class="wb-command-button" type="button" aria-label="Find next" title="Find next">' &&
      zcl_gg_host_icons=>icon( iv_name = `search-plus` ) &&
      '</button><span class="wb-command-separator" aria-hidden="true"></span><button class="wb-command-button wb-command-button--page" type="button" aria-label="First page" title="First page">' &&
      zcl_gg_host_icons=>icon( iv_name = `arrow-bar-to-up` ) &&
      '</button><button class="wb-command-button wb-command-button--page" type="button" aria-label="Previous page" title="Previous page">' &&
      zcl_gg_host_icons=>icon( iv_name = `file-arrow-up` ) &&
      '</button><button class="wb-command-button wb-command-button--page" type="button" aria-label="Next page" title="Next page">' &&
      zcl_gg_host_icons=>icon( iv_name = `file-arrow-down` ) &&
      '</button><button class="wb-command-button wb-command-button--page" type="button" aria-label="Last page" title="Last page">' &&
      zcl_gg_host_icons=>icon( iv_name = `arrow-bar-to-down` ) &&
      '</button></section>'.
    rv_html = rv_html && '<header class="wb-appbar"><span class="wb-app-title">Workbench</span></header><div class="wb-toolbar" aria-label="Application toolbar"><button class="wb-toolbar-button" type="button" title="Create">' &&
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
    IF iv_runtime = abap_true.
      REPLACE ALL OCCURRENCES OF 'aria-label="Save"' IN rv_html WITH 'aria-label="Global command"'.
      REPLACE ALL OCCURRENCES OF 'aria-label="Cancel"' IN rv_html WITH 'aria-label="Global command"'.
      REPLACE ALL OCCURRENCES OF 'aria-label="Print"' IN rv_html WITH 'aria-label="Global command"'.
      REPLACE ALL OCCURRENCES OF 'aria-label="Find"' IN rv_html WITH 'aria-label="Global command"'.
      REPLACE ALL OCCURRENCES OF 'aria-label="Find next"' IN rv_html WITH 'aria-label="Global command"'.
      REPLACE ALL OCCURRENCES OF 'aria-label="First page"' IN rv_html WITH 'aria-label="Global command"'.
      REPLACE ALL OCCURRENCES OF 'aria-label="Previous page"' IN rv_html WITH 'aria-label="Global command"'.
      REPLACE ALL OCCURRENCES OF 'aria-label="Next page"' IN rv_html WITH 'aria-label="Global command"'.
      REPLACE ALL OCCURRENCES OF 'aria-label="Last page"' IN rv_html WITH 'aria-label="Global command"'.
    ENDIF.
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
