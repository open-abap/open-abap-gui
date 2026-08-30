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

    CLASS-METHODS render_logo
      RETURNING
        VALUE(rv_html) TYPE string.
ENDCLASS.

CLASS zcl_gg_workbench IMPLEMENTATION.

  METHOD zif_gg_raw_html_v1~get_html.
    DATA lt_report_classes TYPE string_table.
    DATA lt_dynpro_classes TYPE string_table.
    DATA lv_class_name TYPE string.

    lt_report_classes = get_implementations( 'ZIF_GG_REPORT_V1' ).
    lt_dynpro_classes = get_implementations( 'ZIF_GG_DYNPRO_V1' ).

    rv_html = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>open-abap GUI</title><style>' &&
      'html,body{margin:0;height:100%;min-height:100%;overflow:hidden;font-family:Inter,Segoe UI,Tahoma,Arial,sans-serif;font-size:13px;color:#1d2d3e;background:#e9f0f8}' &&
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
      '.wb-app-title{font-size:20px;font-weight:600;letter-spacing:-.3px}' &&
      '.wb-toolbar{margin:0;padding:7px 18px;display:flex;gap:5px;background:#dce8f3;border:0;border-bottom:1px solid #a8bfd6;border-radius:0}' &&
      '.wb-toolbar-button{height:28px;min-width:32px;border:1px solid #91adca;border-radius:3px;background:linear-gradient(#fff,#e8f0f8);color:#15589a;font-weight:600;cursor:pointer}' &&
      '.wb-toolbar-button:hover,.wb-toolbar-button:focus{background:#fff;border-color:#5e8fbd;outline:0}' &&
      '.wb-workspace{display:flex;flex:1 1 auto;min-height:0;margin:16px 28px 0;border:1px solid #aebfd2;border-radius:5px;overflow:hidden;background:#fff;box-shadow:0 2px 8px rgba(34,67,102,.12)}' &&
      '.wb-tree-panel{width:305px;flex:0 0 305px;min-height:0;border-right:1px solid #aebfd2;background:#f4f8fc;overflow:auto}' &&
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
      '.wb-content{flex:1;min-width:0;min-height:0;padding:0;background:#fff;overflow:hidden}' &&
      '.wb-logo-only{height:100%;min-height:0;display:flex;align-items:center;justify-content:center;box-sizing:border-box;overflow:hidden}' &&
      '.wb-welcome-art{flex:1 1 auto;width:100%;height:100%;min-width:0;min-height:0;display:flex;flex-direction:column;gap:12px;align-items:center;justify-content:center;position:relative;overflow:hidden;border-radius:0;background:linear-gradient(135deg,#f6f9fc 0%,#e1ebf6 58%,#c6d8e9 100%);border:0}' &&
      '.wb-logo-mark{display:block;width:min(42vw,280px);max-width:72%;max-height:64%;height:auto;filter:drop-shadow(0 8px 8px rgba(23,74,128,.18))}' &&
      '.wb-wordmark{position:relative;z-index:1;padding:8px 12px;color:#174a80;font:bold clamp(24px,4vw,48px) Arial;text-shadow:0 1px 1px #fff;border-bottom:clamp(3px,.4vw,6px) solid #4d82b6}' &&
      '.wb-statusbar{display:flex;align-items:center;gap:18px;margin:10px 28px 12px;padding:6px 10px;color:#60758b;background:#dce8f3;border:1px solid #b8c9dc;border-radius:4px;font-size:11px}' &&
      '.wb-status-feedback{min-height:1em;color:#315a7f;font-weight:600}' &&
      '.wb-status-context{margin-left:auto;display:flex;align-items:center;gap:18px}.wb-sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}' &&
      '@media(max-width:760px){.wb-tree-panel{width:220px;flex-basis:220px}.wb-workspace,.wb-statusbar{margin-left:10px;margin-right:10px}.wb-command-input{width:130px}}' &&
      '</style></head><body><div class="wb-shell">' &&
      zcl_gg_host_icons=>sprite( ).
    rv_html = rv_html && zcl_gg_workbench_utility=>render_top(
      it_icon_bar = VALUE #(
        ( label = `Create`           icon = `plus` )
        ( label = `Open`             icon = `folder-open` )
        ( label = `Add to favorites` icon = `star` )
        ( label = `Edit`             icon = `edit` )
        ( label = `Refresh`          icon = `refresh` ) ) ).
    rv_html = rv_html && '<div class="wb-workspace"><aside class="wb-tree-panel"><div class="wb-tree-heading">Applications</div><nav class="wb-tree" aria-label="Application tree"><ul role="tree"><li role="treeitem"><details open><summary><span class="wb-twist" aria-hidden="true"></span>' &&
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
    rv_html = rv_html && '<main class="wb-content" id="main-content"><section class="wb-logo-only" aria-label="open-abap">' &&
      render_logo( ) &&
      '</section></main></div>'.
    rv_html = rv_html && zcl_gg_workbench_utility=>render_bottom( ).
  ENDMETHOD.

  METHOD render_logo.
    rv_html = '<div class="wb-welcome-art" role="img" aria-label="open-abap"><svg class="wb-logo-mark" viewBox="0 0 108 108" aria-hidden="true" focusable="false">' &&
      '<g stroke="#6f8faa" stroke-width="1.5" stroke-linejoin="round">' &&
      '<path fill="#6d98bf" d="M7.63 52.06 79.82 11.12v55.36L7.63 77.42Z" />' &&
      '<path fill="#a9c0d7" d="m7.63 77.42 72.19-10.94L101 95.99 28.1 91.59Z" />' &&
      '<path fill="#c6d8e9" d="m79.82 11.12 21.18 43v41.87L79.82 66.48Z" />' &&
      '<path fill="#174a80" d="m7.63 52.06 20.47 17.43v22.1L7.63 77.42Z" />' &&
      '<path fill="#f4f8fc" d="m28.1 69.49 72.9-15.37v41.87l-72.9-4.4Z" />' &&
      '<path fill="#4d82b6" d="M7.63 52.06 79.82 11.12 101 54.12 28.1 69.49Z" />' &&
      '</g></svg><span class="wb-wordmark">open-abap</span></div>'.
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
