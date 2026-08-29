CLASS zcl_gg_workbench DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_raw_html_v1.

  PRIVATE SECTION.
    CLASS-DATA mt_report_classes TYPE string_table.
    CLASS-DATA mt_dynpro_classes TYPE string_table.

    CLASS-METHODS get_implementations
      IMPORTING
        iv_interface  TYPE string
      RETURNING
        VALUE(result) TYPE string_table.
ENDCLASS.

CLASS zcl_gg_workbench IMPLEMENTATION.

  METHOD zif_gg_raw_html_v1~get_html.
    DATA lt_report_classes TYPE string_table.
    DATA lt_dynpro_classes TYPE string_table.
    DATA lv_class_name TYPE string.

    lt_report_classes = get_implementations( 'ZIF_GG_REPORT_V1' ).
    lt_dynpro_classes = get_implementations( 'ZIF_GG_DYNPRO_V1' ).

    rv_html = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>open-abap GUI</title><style>' &&
      'html,body{margin:0;min-height:100%;font-family:Inter,Segoe UI,Tahoma,Arial,sans-serif;font-size:13px;color:#1d2d3e;background:#e9f0f8}' &&
      '.wb-shell{min-height:100vh;display:flex;flex-direction:column;background:#e9f0f8}' &&
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
      '.wb-workspace{display:flex;flex:1;min-height:430px;margin:16px 28px 0;border:1px solid #aebfd2;border-radius:5px;overflow:hidden;background:#fff;box-shadow:0 2px 8px rgba(34,67,102,.12)}' &&
      '.wb-tree-panel{width:305px;flex:0 0 305px;border-right:1px solid #aebfd2;background:#f4f8fc;overflow:auto}' &&
      '.wb-tree-heading{padding:11px 14px;color:#164b80;font-weight:700;background:#e1ebf6;border-bottom:1px solid #b8c9dc}' &&
      '.wb-tree{margin:0;padding:9px 10px 22px;list-style:none}' &&
      '.wb-tree ul{margin:0;padding:0 0 0 18px;list-style:none}' &&
      '.wb-tree details{margin:0;padding:0}' &&
      '.wb-tree summary{display:flex;align-items:center;min-height:27px;list-style:none;color:#174a80;cursor:pointer;white-space:nowrap;border-radius:3px}' &&
      '.wb-tree summary::-webkit-details-marker{display:none}' &&
      '.wb-tree summary:hover,.wb-tree summary:focus{background:#dce9f6;outline:0}' &&
      '.wb-twist{display:inline-block;width:15px;color:#506f91;font-size:11px}' &&
      '.wb-tree details[open]>summary .wb-twist:before{content:"-"}' &&
      '.wb-tree details:not([open])>summary .wb-twist:before{content:"+"}' &&
      '.wb-tree summary>.wb-icon{width:16px;height:16px;margin-right:7px;color:#b47d18}' &&
      '.wb-tree-link>.wb-icon{width:16px;height:16px;margin:0 8px 0 2px}' &&
      '.wb-tree-link>.wb-icon.wb-icon-star{color:#c48b32}' &&
      '.wb-tree-link{display:flex;align-items:center;min-height:27px;border-radius:3px;color:#064b99;text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}' &&
      '.wb-tree-link:hover,.wb-tree-link:focus{background:#dce9f6;color:#073b78;text-decoration:underline;outline:0}' &&
      '.wb-content{flex:1;min-width:0;padding:22px 26px;background:#fff;overflow:auto}' &&
      '.wb-content-header{display:flex;align-items:center;gap:13px;padding-bottom:16px;border-bottom:1px solid #d9e2e4}' &&
      '.wb-content-icon{display:flex;align-items:center;justify-content:center;width:48px;height:38px;border-radius:5px;background:#3679b7;color:#fff;font:bold 11px Arial;box-shadow:0 2px 4px rgba(35,86,132,.2)}' &&
      '.wb-content-icon .wb-icon{width:23px;height:23px}' &&
      '.wb-content h1{margin:0;color:#1b4e80;font-size:23px;font-weight:600}.wb-content-header p{margin:4px 0 0;color:#66798d}' &&
      '.wb-welcome{display:flex;gap:24px;margin-top:24px;padding:22px;border:1px solid #c5d5e5;border-radius:6px;background:#f5f9fd}' &&
      '.wb-welcome-art{flex:0 0 230px;min-height:155px;display:flex;align-items:center;justify-content:center;position:relative;overflow:hidden;border-radius:5px;background:radial-gradient(ellipse at 50% 40%,#d8f1ff 0,#78c3ed 28%,#2e82bd 63%,#175181 100%);border:1px solid #4d8fbe}' &&
      '.wb-welcome-art:before,.wb-welcome-art:after{content:"";position:absolute;width:330px;height:90px;border:8px solid rgba(239,255,255,.36);border-radius:50%;transform:rotate(-17deg)}' &&
      '.wb-welcome-art:after{width:280px;height:52px;border-width:4px;transform:rotate(18deg)}' &&
      '.wb-wordmark{position:relative;z-index:1;padding:8px 12px;color:#fff;font:bold 24px Arial;text-shadow:0 1px 2px #175181;border-bottom:3px solid #fff}' &&
      '.wb-welcome-copy h2{margin:4px 0 8px;color:#1b4e80;font-size:18px}.wb-welcome-copy p{max-width:560px;margin:0 0 16px;line-height:1.5;color:#526b82}' &&
      '.wb-hint{padding:10px 12px;border-left:4px solid #4d93c8;border-radius:0 4px 4px 0;background:#e4f0fa;color:#315a7f}' &&
      '.wb-statusbar{display:flex;align-items:center;gap:18px;margin:10px 28px 12px;padding:6px 10px;color:#60758b;background:#dce8f3;border:1px solid #b8c9dc;border-radius:4px;font-size:11px}' &&
      '.wb-status-feedback{min-height:1em;color:#315a7f;font-weight:600}' &&
      '.wb-status-context{margin-left:auto;display:flex;align-items:center;gap:18px}.wb-sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}' &&
      '@media(max-width:760px){.wb-tree-panel{width:220px;flex-basis:220px}.wb-workspace,.wb-statusbar{margin-left:10px;margin-right:10px}.wb-welcome{flex-direction:column}.wb-welcome-art{flex-basis:auto}.wb-command-input{width:130px}}' &&
      '</style></head><body><div class="wb-shell">' &&
      zcl_gg_host_icons=>sprite( ).
    rv_html = rv_html && zcl_gg_workbench_utility=>render_top( ).
    rv_html = rv_html && '<div class="wb-workspace"><aside class="wb-tree-panel"><div class="wb-tree-heading">Applications</div><nav class="wb-tree" aria-label="Application tree"><ul role="tree"><li role="treeitem"><details open><summary><span class="wb-twist" aria-hidden="true"></span>' &&
      zcl_gg_host_icons=>icon( iv_name = `folder-open` ) &&
      'Favorites</summary><ul role="group"><li role="treeitem"><a class="wb-tree-link" href="/ZCL_GG_INTEGRATION_HTML_REPORT">' &&
      zcl_gg_host_icons=>icon( iv_name = `star` ) &&
      'ZCL_GG_INTEGRATION_HTML_REPORT</a></li><li role="treeitem"><a class="wb-tree-link" href="/ZCL_GG_INTEGRATION_DYNPRO">' &&
      zcl_gg_host_icons=>icon( iv_name = `star` ) &&
      'ZCL_GG_INTEGRATION_DYNPRO</a></li></ul></details></li>'.
    rv_html = rv_html && '<li role="treeitem"><details open><summary><span class="wb-twist" aria-hidden="true"></span>' &&
      zcl_gg_host_icons=>icon( iv_name = `folder-open` ) &&
      'Application Menu</summary><ul role="group"><li role="treeitem"><details open><summary><span class="wb-twist" aria-hidden="true"></span>' &&
      zcl_gg_host_icons=>icon( iv_name = `folder-open` ) &&
      'ABAP Reports</summary><ul role="group">'.
    LOOP AT lt_report_classes INTO lv_class_name.
      IF lv_class_name CP 'ZCL_GG_*'.
        rv_html = rv_html && |<li role="treeitem"><a class="wb-tree-link" href="/{ zcl_gg_host_html=>escape_attribute( lv_class_name ) }">| &&
          zcl_gg_host_icons=>icon( iv_name = `file-code` ) &&
          |{ zcl_gg_host_html=>escape_text( lv_class_name ) }</a></li>|.
      ENDIF.
    ENDLOOP.
    rv_html = rv_html && '</ul></details></li><li role="treeitem"><details open><summary><span class="wb-twist" aria-hidden="true"></span>' &&
      zcl_gg_host_icons=>icon( iv_name = `folder-open` ) &&
      'Dynpro Applications</summary><ul role="group">'.
    LOOP AT lt_dynpro_classes INTO lv_class_name.
      IF lv_class_name CP 'ZCL_GG_*'.
        rv_html = rv_html && |<li role="treeitem"><a class="wb-tree-link" href="/{ zcl_gg_host_html=>escape_attribute( lv_class_name ) }">| &&
          zcl_gg_host_icons=>icon( iv_name = `file-code` ) &&
          |{ zcl_gg_host_html=>escape_text( lv_class_name ) }</a></li>|.
      ENDIF.
    ENDLOOP.
    rv_html = rv_html && '</ul></details></li><li role="treeitem"><details open><summary><span class="wb-twist" aria-hidden="true"></span>' &&
      zcl_gg_host_icons=>icon( iv_name = `folder-open` ) &&
      'Utilities</summary><ul role="group"><li role="treeitem"><a class="wb-tree-link" href="/ZCL_GG_DB_HELPER">' &&
      zcl_gg_host_icons=>icon( iv_name = `database` ) &&
      'ZCL_GG_DB_HELPER</a></li></ul></details></li></ul></details></li></ul></nav></aside>'.
    rv_html = rv_html && '<main class="wb-content" id="main-content"><header class="wb-content-header"><span class="wb-content-icon">' &&
      zcl_gg_host_icons=>icon( iv_name = `device-desktop` iv_label = `Application` ) &&
      '</span><div><h1>ABAP examples and integration classes</h1><p>Select an application from the tree to start it.</p></div></header><section class="wb-welcome" aria-label="Welcome"><div class="wb-welcome-art" aria-hidden="true"><span class="wb-wordmark">open-abap</span></div><div class="wb-welcome-copy"><h2>Welcome to open-abap GUI</h2><p>This launchpad exposes the executable ABAP examples, dynpro applications, and integration fixtures through the HTML host.</p><p class="wb-hint">Use the application tree on the left, or enter a command above, to open a page.</p></div></section></main></div>'.
    rv_html = rv_html && zcl_gg_workbench_utility=>render_bottom( ).
  ENDMETHOD.

  METHOD get_implementations.
    TYPES:
      BEGIN OF ty_s_impl,
        clsname    TYPE c LENGTH 30,
        refclsname TYPE c LENGTH 30,
      END OF ty_s_impl,
      BEGIN OF ty_s_key,
        intkey TYPE c LENGTH 30,
      END OF ty_s_key,
      BEGIN OF ty_source,
        progname TYPE c LENGTH 40,
        data     TYPE string,
      END OF ty_source.
    DATA obj TYPE REF TO object.
    DATA lt_implementation_names TYPE string_table.
    DATA lv_fm TYPE string.
    DATA lt_impl TYPE STANDARD TABLE OF ty_s_impl WITH DEFAULT KEY.
    DATA ls_key TYPE ty_s_key.
    DATA lt_sources TYPE STANDARD TABLE OF ty_source WITH DEFAULT KEY.
    DATA lv_interface TYPE string.
    DATA ls_source TYPE ty_source.
    DATA lv_source TYPE string.
    DATA lv_class_name TYPE string.
    DATA lr_impl TYPE REF TO ty_s_impl.
    FIELD-SYMBOLS <any> TYPE any.
    FIELD-SYMBOLS <class_name> TYPE string.

    IF iv_interface = 'ZIF_GG_REPORT_V1' AND mt_report_classes IS NOT INITIAL.
      result = mt_report_classes.
      RETURN.
    ELSEIF iv_interface = 'ZIF_GG_DYNPRO_V1' AND mt_dynpro_classes IS NOT INITIAL.
      result = mt_dynpro_classes.
      RETURN.
    ENDIF.

    TRY.
        CALL METHOD ('XCO_CP_ABAP')=>interface
          EXPORTING
            iv_name      = iv_interface
          RECEIVING
            ro_interface = obj.

        ASSIGN obj->('IF_XCO_AO_INTERFACE~IMPLEMENTATIONS') TO <any>.
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE cx_sy_dyn_call_illegal_class.
        ENDIF.
        obj = <any>.

        ASSIGN obj->('IF_XCO_INTF_IMPLEMENTATIONS_FC~ALL') TO <any>.
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE cx_sy_dyn_call_illegal_class.
        ENDIF.
        obj = <any>.

        CALL METHOD obj->('IF_XCO_INTF_IMPLEMENTATIONS~GET').

        CALL METHOD obj->('IF_XCO_INTF_IMPLEMENTATIONS~GET_NAMES')
          RECEIVING
            rt_names = lt_implementation_names.

        result = lt_implementation_names.

      CATCH cx_sy_dyn_call_illegal_class.
        lv_fm = `SEO_INTERFACE_IMPLEM_GET_ALL`.
        TRY.
            ls_key-intkey = iv_interface.

            CALL FUNCTION lv_fm
              EXPORTING
                intkey       = ls_key
              IMPORTING
                impkeys      = lt_impl
              EXCEPTIONS
                not_existing = 1
                OTHERS       = 2.

            LOOP AT lt_impl REFERENCE INTO lr_impl.
              INSERT CONV #( lr_impl->clsname ) INTO TABLE result.
            ENDLOOP.
          CATCH cx_root.
            lv_interface = iv_interface.
            TRANSLATE lv_interface TO UPPER CASE.
            SELECT progname, data FROM reposrc
              INTO TABLE @lt_sources
              ORDER BY progname.
            LOOP AT lt_sources INTO ls_source.
              lv_source = ls_source-data.
              TRANSLATE lv_source TO UPPER CASE.
              IF lv_source CS |INTERFACES { lv_interface }|.
                lv_class_name = CONV string( ls_source-progname ).
                SHIFT lv_class_name RIGHT DELETING TRAILING space.
                INSERT lv_class_name INTO TABLE result.
              ENDIF.
            ENDLOOP.
        ENDTRY.
    ENDTRY.

    LOOP AT result ASSIGNING <class_name>.
      TRANSLATE <class_name> TO UPPER CASE.
      SHIFT <class_name> RIGHT DELETING TRAILING space.
    ENDLOOP.
    SORT result.
    DELETE ADJACENT DUPLICATES FROM result.
    CASE iv_interface.
      WHEN 'ZIF_GG_REPORT_V1'.
        mt_report_classes = result.
      WHEN 'ZIF_GG_DYNPRO_V1'.
        mt_dynpro_classes = result.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
