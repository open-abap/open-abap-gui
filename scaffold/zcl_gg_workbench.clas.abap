CLASS zcl_gg_workbench DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_raw_html_v1.

    CLASS-METHODS render_error
      IMPORTING
        iv_command     TYPE string
        iv_error       TYPE string
        iv_session_id  TYPE string OPTIONAL
        iv_page_id     TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

  PRIVATE SECTION.
    CLASS-METHODS render_workbench
      IMPORTING
        iv_command     TYPE string OPTIONAL
        iv_error       TYPE string OPTIONAL
        iv_session_id  TYPE string OPTIONAL
        iv_page_id     TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_logo
      RETURNING
        VALUE(rv_html) TYPE string.
ENDCLASS.

CLASS zcl_gg_workbench IMPLEMENTATION.

  METHOD zif_gg_raw_html_v1~get_html.
    rv_html = render_workbench( ).
  ENDMETHOD.

  METHOD render_error.
    rv_html = render_workbench(
      iv_command    = iv_command
      iv_error      = iv_error
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id ).
  ENDMETHOD.

  METHOD render_workbench.
    DATA lt_transactions TYPE zcl_gg_transaction_registry=>ty_transactions.
    DATA ls_transaction TYPE zcl_gg_transaction_registry=>ty_transaction.
    DATA lv_tcode_url TYPE string.

    IF iv_error IS INITIAL.
      lt_transactions = zcl_gg_transaction_registry=>get_all( ).
    ELSE.
      TRY.
          lt_transactions = zcl_gg_transaction_registry=>get_all( ).
        CATCH zcx_gg_transaction_error.
          CLEAR lt_transactions.
      ENDTRY.
    ENDIF.

    rv_html = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>open-abap GUI</title><style>' &&
      zcl_gg_workbench_utility=>render_styles( ) &&
      '.wb-workspace{display:flex;flex:1 1 auto;min-height:0;margin:16px 28px 0;border:1px solid #aebfd2;border-radius:5px;overflow:hidden;background:#fff;box-shadow:0 2px 8px rgba(34,67,102,.12)}' &&
      '.wb-app-panel{width:305px;flex:0 0 305px;min-height:0;border-right:1px solid #aebfd2;background:#f4f8fc;overflow:auto}' &&
      '.wb-app-heading{padding:11px 14px;color:#164b80;font-weight:700;background:#e1ebf6;border-bottom:1px solid #b8c9dc}' &&
      '.wb-app-list{margin:0;padding:9px 10px 22px;list-style:none}' &&
      '.wb-app-link{display:flex;align-items:center;min-height:27px;border-radius:3px;color:#064b99;text-decoration:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}' &&
      '.wb-app-link>.wb-icon{width:16px;height:16px;margin:0 8px 0 2px}' &&
      '.wb-app-description{margin-left:8px;color:#60758b;font-size:12px;overflow:hidden;text-overflow:ellipsis}' &&
      '.wb-app-link:hover,.wb-app-link:focus{background:#dce9f6;color:#073b78;text-decoration:underline;outline:0}' &&
      '.wb-content{flex:1;min-width:0;min-height:0;padding:0;background:#fff;overflow:hidden}' &&
      '.wb-logo-only{height:100%;min-height:0;display:flex;align-items:center;justify-content:center;box-sizing:border-box;overflow:hidden}' &&
      '.wb-welcome-art{flex:1 1 auto;width:100%;height:100%;min-width:0;min-height:0;display:flex;flex-direction:column;gap:12px;align-items:center;justify-content:center;position:relative;overflow:hidden;border-radius:0;background:linear-gradient(135deg,#f6f9fc 0%,#e1ebf6 58%,#c6d8e9 100%);border:0}' &&
      '.wb-logo-mark{display:block;width:min(42vw,280px);max-width:72%;max-height:64%;height:auto;filter:drop-shadow(0 8px 8px rgba(23,74,128,.18))}' &&
      '.wb-wordmark{position:relative;z-index:1;padding:8px 12px;color:#174a80;font:bold clamp(24px,4vw,48px) Arial;text-shadow:0 1px 1px #fff;border-bottom:clamp(3px,.4vw,6px) solid #4d82b6}' &&
      '@media(max-width:760px){.wb-app-panel{width:220px;flex-basis:220px}.wb-workspace{margin-left:10px;margin-right:10px}}' &&
      '</style></head><body><div class="wb-shell">' &&
      zcl_gg_host_icons=>sprite( ).
    rv_html = rv_html && zcl_gg_workbench_utility=>render_top(
      iv_command    = iv_command
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id ).
    rv_html = rv_html && '<div class="wb-workspace"><aside class="wb-app-panel"><div class="wb-app-heading">Applications</div><nav aria-label="Applications"><ul class="wb-app-list">'.
    LOOP AT lt_transactions INTO ls_transaction.
      lv_tcode_url = cl_http_utility=>escape_url( CONV string( ls_transaction-tcode ) ).
      rv_html = rv_html && |<li><a class="wb-app-link" aria-label="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_transaction-tcode ) ) }" href="/transaction?tcode={ zcl_gg_host_html=>escape_attribute( lv_tcode_url ) }">| &&
        zcl_gg_host_icons=>icon( iv_name = `file-code` ) &&
        |<span>{ zcl_gg_host_html=>escape_text( CONV string( ls_transaction-tcode ) ) }</span><span class="wb-app-description">{ zcl_gg_host_html=>escape_text( ls_transaction-description ) }</span></a></li>|.
    ENDLOOP.
    rv_html = rv_html && '<li><a class="wb-app-link" href="/ZCL_GG_DB_HELPER">' &&
      zcl_gg_host_icons=>icon( iv_name = `database` ) &&
      'ZCL_GG_DB_HELPER</a></li></ul></nav></aside>'.
    rv_html = rv_html && '<main class="wb-content" id="main-content"><section class="wb-logo-only" aria-label="open-abap">' &&
      render_logo( ) &&
      '</section></main></div>'.
    rv_html = rv_html && zcl_gg_workbench_utility=>render_bottom( iv_message = iv_error ).
  ENDMETHOD.

  METHOD render_logo.
    rv_html = '<div class="wb-welcome-art" role="img" aria-label="open-abap"><svg class="wb-logo-mark" viewBox="0 0 108 108" aria-hidden="true" focusable="false">' &&
      '<defs><linearGradient id="wb-logo-edge-base"><stop stop-color="#174a80" offset="0" /><stop stop-color="#174a80" stop-opacity="0" offset="1" /></linearGradient><linearGradient id="wb-logo-edge" href="#wb-logo-edge-base" x1="56.318806" y1="114.51591" x2="162.49908" y2="114.51591" gradientUnits="userSpaceOnUse" gradientTransform="matrix(.98451947,0,0,.97446173,-52.524478,127.5605)" /></defs>' &&
      '<g transform="translate(-56.318804,-55.73065)" fill-rule="evenodd" stroke="url(#wb-logo-edge)" stroke-width="11.10588932" stroke-linejoin="round">' &&
      '<path fill="#24466f" d="m 63.950965,107.79279 v 25.35781 l 20.46392,14.16915 v -22.09656 z" />' &&
      '<path fill="#f7fbff" d="m 84.414885,125.22319 72.909565,-15.3697 v 41.86591 l -72.909565,-4.39965 z" />' &&
      '<path fill="#3d6fa5" d="M 63.950965,107.79279 136.1432,66.852396 157.32445,109.85349 84.414885,125.22319 Z" />' &&
      '<path fill="#96b4d1" d="M 63.950965,133.1506 136.1432,122.20665 157.32445,151.7194 84.414885,147.31975 Z" />' &&
      '<path fill="#d7e7f5" d="m 136.1432,66.852396 v 55.354254 l 21.18125,29.51275 v -41.86591 z" />' &&
      '<path fill="#6f98bf" d="M 63.950965,107.79279 136.1432,66.852396 V 122.20665 L 63.950965,133.1506 Z" />' &&
      '</g></svg><span class="wb-wordmark">open-abap</span></div>'.
  ENDMETHOD.

ENDCLASS.
