CLASS zcl_gg_workbench_utility DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS render_top
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_bottom
      RETURNING
        VALUE(rv_html) TYPE string.

ENDCLASS.

CLASS zcl_gg_workbench_utility IMPLEMENTATION.

  METHOD render_top.
    rv_html = '<nav class="wb-menubar" role="menubar" aria-label="Main menu"><span class="wb-brand">open-abap</span><div class="wb-menu-items">' &&
      '<button class="wb-menu" type="button" role="menuitem">Applications</button><button class="wb-menu" type="button" role="menuitem">Edit</button><button class="wb-menu" type="button" role="menuitem">Favorites</button><button class="wb-menu" type="button" role="menuitem">Tools</button><button class="wb-menu" type="button" role="menuitem">System</button><button class="wb-menu" type="button" role="menuitem">Help</button></div></nav>'.
    rv_html = rv_html && '<section class="wb-commandbar" aria-label="Command bar"><label class="wb-sr-only" for="wb-command">Command</label><input class="wb-command-input" id="wb-command" type="text" placeholder="Command" autocomplete="off"><button class="wb-command-button" type="button" aria-label="Save" title="Save">' &&
      zcl_gg_host_icons=>icon( iv_name = `device-floppy` ) &&
      '</button><span class="wb-command-separator" aria-hidden="true"></span><button class="wb-command-button wb-command-button--back" type="button" aria-label="Back" title="Back">' &&
      zcl_gg_host_icons=>icon( iv_name = `arrow-back-up` ) &&
      '</button><button class="wb-command-button wb-command-button--exit" type="button" aria-label="Exit" title="Exit">' &&
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
  ENDMETHOD.

  METHOD render_bottom.
    rv_html = '<footer class="wb-statusbar"><span class="wb-status-feedback" aria-live="polite"></span><div class="wb-status-context"><span>System:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-sysid ) ) &&
      '</span><span>Client:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-mandt ) ) &&
      '</span><span>User:&nbsp;' &&
      zcl_gg_host_html=>escape_text( CONV string( sy-uname ) ) &&
      '</span></div></footer></div><script>(function(){var feedback=document.querySelector(".wb-status-feedback");document.querySelectorAll(".wb-command-button,.wb-toolbar-button").forEach(function(button){button.addEventListener("click",function(){feedback.textContent=(button.getAttribute("aria-label")||button.getAttribute("title")||"Command")+" pressed";});});}());</script></body></html>'.
  ENDMETHOD.

ENDCLASS.
