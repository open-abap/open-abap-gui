CLASS zcl_gg_host_html DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Small, dependency-free HTML writer shared by the host page renderers.
* Dynamic values must enter HTML through escape_text or escape_attribute.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_attribute,
             name     TYPE string,
             value    TYPE string,
             optional TYPE abap_bool,
           END OF ty_attribute.
    TYPES ty_attributes TYPE STANDARD TABLE OF ty_attribute WITH DEFAULT KEY.

    CLASS-METHODS escape_text
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS escape_attribute
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS identifier
      IMPORTING
        iv_scope     TYPE string
        iv_program   TYPE string OPTIONAL
        iv_name      TYPE string OPTIONAL
        iv_index     TYPE i OPTIONAL
      RETURNING
        VALUE(rv_id) TYPE string.

    CLASS-METHODS attribute
      IMPORTING
        iv_name        TYPE string
        iv_value       TYPE string
        iv_optional    TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_attr) TYPE string.

    CLASS-METHODS attributes
      IMPORTING
        it_attributes   TYPE ty_attributes
      RETURNING
        VALUE(rv_attrs) TYPE string.

    CLASS-METHODS open_tag
      IMPORTING
        iv_name       TYPE string
        iv_attributes TYPE string OPTIONAL
      RETURNING
        VALUE(rv_tag) TYPE string.

    CLASS-METHODS close_tag
      IMPORTING
        iv_name       TYPE string
      RETURNING
        VALUE(rv_tag) TYPE string.

    CLASS-METHODS void_tag
      IMPORTING
        iv_name       TYPE string
        iv_attributes TYPE string OPTIONAL
      RETURNING
        VALUE(rv_tag) TYPE string.

    CLASS-METHODS text_node
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS document
      IMPORTING
        iv_session_id  TYPE string
        iv_page_id     TYPE string
        iv_kind        TYPE string
        iv_title       TYPE string
        iv_body        TYPE string
        iv_csp_nonce   TYPE string OPTIONAL
        is_status      TYPE zif_gg_session_types_v1=>ty_gui_status OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS css_class
      IMPORTING
        is_format       TYPE zif_gg_list_processing_types_v1=>ty_format
      RETURNING
        VALUE(rv_class) TYPE string.

    CLASS-METHODS message_class
      IMPORTING
        iv_type         TYPE zif_gg_session_types_v1=>ty_message_type
      RETURNING
        VALUE(rv_class) TYPE string.

    CLASS-METHODS state_class
      IMPORTING
        iv_focused      TYPE abap_bool DEFAULT abap_false
        iv_selected     TYPE abap_bool DEFAULT abap_false
        iv_changed      TYPE abap_bool DEFAULT abap_false
        iv_disabled     TYPE abap_bool DEFAULT abap_false
        iv_required     TYPE abap_bool DEFAULT abap_false
        iv_error        TYPE abap_bool DEFAULT abap_false
        iv_warning      TYPE abap_bool DEFAULT abap_false
        iv_total        TYPE abap_bool DEFAULT abap_false
        iv_subtotal     TYPE abap_bool DEFAULT abap_false
        iv_hotspot      TYPE abap_bool DEFAULT abap_false
        iv_readonly     TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_class) TYPE string.

    CLASS-METHODS format_external_value
      IMPORTING
        iv_value        TYPE string
        iv_type         TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

  PRIVATE SECTION.
    CLASS-METHODS normalize_identifier
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_gg_host_html IMPLEMENTATION.

  METHOD escape_text.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF '&' IN rv_text WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN rv_text WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN rv_text WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF `"` IN rv_text WITH '&quot;'.
    REPLACE ALL OCCURRENCES OF `'` IN rv_text WITH '&#39;'.
  ENDMETHOD.

  METHOD escape_attribute.
    rv_text = escape_text( iv_text ).
  ENDMETHOD.

  METHOD normalize_identifier.
    DATA lv_char TYPE c LENGTH 1.
    DATA lv_source TYPE string.

    lv_source = iv_text.
    DO strlen( lv_source ) TIMES.
      DATA(lv_offset) = sy-index - 1.
      lv_char = lv_source+lv_offset(1).
      IF ( lv_char >= 'A' AND lv_char <= 'Z' )
          OR ( lv_char >= 'a' AND lv_char <= 'z' )
          OR ( lv_char >= '0' AND lv_char <= '9' )
          OR lv_char = '-'
          OR lv_char = '_'.
        rv_text = rv_text && lv_char.
      ELSE.
        rv_text = rv_text && '-'.
      ENDIF.
    ENDDO.
    IF rv_text IS INITIAL.
      rv_text = 'x'.
    ENDIF.
  ENDMETHOD.

  METHOD identifier.
    rv_id = |gg-{ normalize_identifier( iv_scope ) }|.
    IF iv_program IS NOT INITIAL.
      rv_id = rv_id && |-p-{ normalize_identifier( iv_program ) }|.
    ENDIF.
    IF iv_name IS NOT INITIAL.
      rv_id = rv_id && |-n-{ normalize_identifier( iv_name ) }|.
    ENDIF.
    IF iv_index > 0.
      rv_id = rv_id && |-r-{ iv_index }|.
    ENDIF.
  ENDMETHOD.

  METHOD attribute.
    IF iv_optional = abap_true AND iv_value IS INITIAL.
      RETURN.
    ENDIF.
    rv_attr = | { normalize_identifier( iv_name ) }="{ escape_attribute( iv_value ) }"|.
  ENDMETHOD.

  METHOD attributes.
    DATA lt_attributes TYPE ty_attributes.

    lt_attributes = it_attributes.
    SORT lt_attributes BY name.
    LOOP AT lt_attributes INTO DATA(ls_attribute).
      rv_attrs = rv_attrs && attribute(
        iv_name     = ls_attribute-name
        iv_value    = ls_attribute-value
        iv_optional = ls_attribute-optional ).
    ENDLOOP.
  ENDMETHOD.

  METHOD open_tag.
    rv_tag = |<{ normalize_identifier( iv_name ) }{ iv_attributes }>|.
  ENDMETHOD.

  METHOD close_tag.
    rv_tag = |</{ normalize_identifier( iv_name ) }>|.
  ENDMETHOD.

  METHOD void_tag.
    rv_tag = |<{ normalize_identifier( iv_name ) }{ iv_attributes }>|.
  ENDMETHOD.

  METHOD text_node.
    rv_text = escape_text( iv_text ).
  ENDMETHOD.

  METHOD document.
    DATA lv_content_class TYPE string.

    lv_content_class = COND string( WHEN iv_kind = zif_gg_host_html_v1=>page_dynpro THEN ` wb-runtime-content--dynpro` ELSE `` ).
    rv_html = |<!doctype html><html lang="en"><head>|.
    rv_html = rv_html && |<meta charset="utf-8">|.
    rv_html = rv_html && |<meta name="viewport" content="width=device-width,initial-scale=1">|.
    rv_html = rv_html && |<title>{ escape_text( iv_title ) }</title>|.
    rv_html = rv_html && |<style{ attribute( iv_name     = `nonce`
                                             iv_value    = iv_csp_nonce
                                             iv_optional = abap_true ) }>|.
    rv_html = rv_html && zcl_gg_workbench_utility=>render_styles( ).
    rv_html = rv_html && |:root\{font-family:var(--gg-content-font);color-scheme:light;\}|.
    rv_html = rv_html && |body\{line-height:1.25;\}|.
    rv_html = rv_html && |main\{max-width:100%;overflow:auto;\}|.
    rv_html = rv_html && |.gg-message\{padding:.5rem;margin:.5rem 0;border:1px solid;\}|.
    rv_html = rv_html && |.gg-error\{color:#b00020;border-color:#b00020;\}|.
    rv_html = rv_html && |.gg-warning\{color:#8a5700;border-color:#8a5700;\}|.
    rv_html = rv_html && |.gg-success\{color:#146c2e;border-color:#146c2e;\}|.
    rv_html = rv_html && |.gg-list\{font-family:var(--gg-mono-font);font-size:18px;white-space:pre;overflow:auto;\}|.
    rv_html = rv_html && |.gg-list-line\{display:block;min-height:22px;line-height:22px;\}|.
    rv_html = rv_html && |.gg-list-line button\{font:inherit;color:inherit;background:none;border:0;padding:0;text-align:left;\}|.
    rv_html = rv_html && |.gg-list-page\{break-after:page;margin-bottom:1rem;\}|.
    rv_html = rv_html && |.gg-list-page-header\{display:flex;justify-content:space-between;gap:1rem;min-height:22px;margin:0;padding:0;border-bottom:1px solid var(--gg-border-dark);box-sizing:border-box;color:#075e9a;font:inherit;font-weight:400;line-height:22px;\}|.
    rv_html = rv_html && |.gg-list-page-title\{min-width:0;overflow:hidden;text-overflow:ellipsis;\}|.
    rv_html = rv_html && |.gg-list-page-number\{flex:0 0 auto;\}|.
    rv_html = rv_html && |.gg-list-fragment\{white-space:pre;\}|.
    rv_html = rv_html && |.gg-list .gg-color-heading\{background:#c7eaf2;color:#123b64;font-weight:700;\}|.
    rv_html = rv_html && |.gg-list .gg-color-key\{color:#075e9a;text-decoration:underline;text-decoration-style:dotted;\}|.
    rv_html = rv_html && |.gg-list .gg-color-positive\{color:#146c2e;\}|.
    rv_html = rv_html && |.gg-list .gg-color-negative\{background:#ff9b91;color:#7f1d1d;\}|.
    rv_html = rv_html && |.gg-list .gg-color-total\{font-weight:700;border-top:1px solid #6f879b;\}|.
    rv_html = rv_html && |.gg-list .gg-color-group\{font-weight:600;border-top:1px solid #9eb5c8;\}|.
    rv_html = rv_html && |.gg-page\{display:flex;flex-direction:column;gap:8px;max-width:100%;\}|.
    rv_html = rv_html && |.gg-page--list\{height:100%;min-height:0;\}|.
    rv_html = rv_html && |.gg-page--list>form\{display:flex;flex-direction:column;flex:1 1 auto;min-height:0;\}|.
    rv_html = rv_html && |.gg-page--list>form>.gg-work-area\{flex:1 1 auto;min-height:0;overflow:auto;\}|.
    rv_html = rv_html && |.gg-work-area--docking\{position:relative;\}|.
    rv_html = rv_html && |.gg-work-area--docking>.gg-dynpro\{margin-left:260px;\}|.
    rv_html = rv_html && |.gg-work-area--docking>.gg-dynpro>form>.gg-controls-standalone\{position:relative;left:-260px;width:calc(100% + 260px);height:100%;min-height:0;\}|.
    rv_html = rv_html && |.gg-status-region,.gg-message-region,.gg-instruction-region,.gg-work-area,.gg-action-row\{min-width:0;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-controls-standalone\{display:flow-root;pointer-events:none;\}|.
    rv_html = rv_html && |.gg-controls-standalone>.gg-control\{pointer-events:none;\}|.
    rv_html = rv_html && |.gg-controls-standalone>.gg-control[title="HTML viewer"]\{pointer-events:auto;\}|.
    rv_html = rv_html && |.gg-controls-standalone>.gg-control input,.gg-controls-standalone>.gg-control select,.gg-controls-standalone>.gg-control textarea,.gg-controls-standalone>.gg-control button,.gg-controls-standalone>.gg-control a,.gg-controls-standalone>.gg-control iframe,.gg-controls-standalone>.gg-control [role=button],.gg-controls-standalone>.gg-control [tabindex]\{pointer-events:auto;\}|.
    rv_html = rv_html && |.gg-controls-standalone .gg-external\{position:relative;z-index:1;pointer-events:auto;\}|.
    rv_html = rv_html && |.gg-controls-standalone .gg-control-toolbar\{z-index:2;\}|.
    rv_html = rv_html && |.gg-controls-standalone .gg-dialog-modeless\{z-index:2;pointer-events:none;\}|.
    rv_html = rv_html && |.gg-controls-standalone .gg-dialog-modeless *\{pointer-events:auto;\}|.
    rv_html = rv_html && |.gg-dialog-modeless\{z-index:20;display:flex;flex-direction:column;overflow:hidden;background:#fff;border:1px solid #526b91;box-shadow:4px 5px 14px rgba(24,48,78,.28);pointer-events:none;\}|.
    rv_html = rv_html && |.gg-dialog-title\{flex:0 0 25px;display:flex;align-items:center;padding:0 8px;background:linear-gradient(#8197bb,#657da9);color:#fff;font-size:12px;font-weight:600;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-dialog-body\{flex:1;min-height:0;overflow:hidden;padding:4px;background:#fff;box-sizing:border-box;pointer-events:none;\}|.
    rv_html = rv_html && |.gg-dialog-body>.gg-control\{position:relative!important;left:0!important;top:0!important;width:100%!important;height:100%!important;pointer-events:none;\}|.
    rv_html = rv_html && |.gg-message-region,.gg-instruction-region\{display:flex;flex-direction:column;gap:4px;\}|.
* Empty regions stay in the markup but take no space or flex gap.
    rv_html = rv_html && |.gg-message-region:empty,.gg-status-region:has(>.gg-selection-status:empty)\{display:none;\}|.
    rv_html = rv_html && |.gg-action-row\{position:relative;z-index:30;display:flex;align-items:center;gap:8px;min-height:28px;padding:4px 0;border-top:1px solid var(--gg-border);box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-state-focused:focus,.gg-state-focused:focus-visible\{outline:2px solid #2668a3;outline-offset:2px;\}|.
    rv_html = rv_html && |.gg-state-selected,[aria-selected=true],[aria-current=true]\{background:#c7dced;color:#102f4d;\}|.
    rv_html = rv_html && |.gg-state-changed,[data-state~="changed"]\{box-shadow:inset 3px 0 #d4a000;\}|.
    rv_html = rv_html && |.gg-state-disabled,[disabled],[aria-disabled=true]\{opacity:.62;cursor:default;\}|.
    rv_html = rv_html && |.gg-state-required,[required],[aria-required=true]\{border-color:#d4a000;\}|.
    rv_html = rv_html && |.gg-state-error,[aria-invalid=true],[data-state~="error"]\{border-color:#b00020;color:#8f001b;\}|.
    rv_html = rv_html && |.gg-state-warning,[data-state~="warning"]\{border-color:#c08100;color:#704700;\}|.
    rv_html = rv_html && |.gg-state-total\{font-weight:700;border-top:1px solid #6f879b;\}|.
    rv_html = rv_html && |.gg-state-subtotal\{font-weight:600;border-top:1px solid #9eb5c8;\}|.
    rv_html = rv_html && |.gg-state-hotspot\{color:#075e9a;text-decoration:underline;text-decoration-style:dotted;cursor:pointer;\}|.
    rv_html = rv_html && |.gg-state-readonly\{color:#4f6476;\}|.
    rv_html = rv_html && |.gg-intensified\{color:#064b99 !important;font-weight:600;\}|.
    rv_html = rv_html && |.gg-list .gg-state-selected\{background:#c7dced;\}|.
    rv_html = rv_html && |.gg-list .gg-state-changed\{border-left:3px solid #d4a000;padding-left:4px;\}|.
    rv_html = rv_html && |.gg-alv table\{border-collapse:collapse;min-width:100%;background:#fff;color:#123b64;font-size:13px;\}|.
    rv_html = rv_html && |.gg-alv\{max-width:100%;overflow:auto;\}|.
    rv_html = rv_html && |.gg-alv th,.gg-alv td\{height:28px;padding:3px 8px;border:1px solid #c1d2e0;white-space:nowrap;text-align:left;\}|.
    rv_html = rv_html && |.gg-alv th\{background:linear-gradient(#e9f3fa,#c7dae9);border-color:#8daac4;font-weight:700;\}|.
    rv_html = rv_html && |.gg-alv .gg-grid-row:nth-child(even) td\{background:#f3f8fc;\}|.
    rv_html = rv_html && |.gg-alv .gg-grid-row.gg-state-selected td\{background:#c7dced;color:#102f4d;\}|.
    rv_html = rv_html && |.gg-alv .gg-grid-cell.gg-state-total\{background:#e3eff8;font-weight:700;\}|.
    rv_html = rv_html && |.gg-alv .gg-grid-cell.gg-state-hotspot\{color:#075e9a;text-decoration:underline;text-decoration-style:dotted;\}|.
    rv_html = rv_html && |.gg-alv-tree\{display:flex;flex-direction:column;height:100%;min-height:0;max-width:100%;overflow:hidden;background:#e5eff7;color:#123b64;\}|.
    rv_html = rv_html && |.gg-alv-tree-columns\{flex:1 1 auto;min-height:0;overflow:auto;border:1px solid #9eb7cd;background:#e5eff7;\}|.
    rv_html = rv_html && |.gg-alv-tree table\{width:auto;min-width:0;border-collapse:collapse;table-layout:auto;background:#e5eff7;color:#123b64;font-size:13px;\}|.
    rv_html = rv_html && |.gg-alv-tree th,.gg-alv-tree td\{height:22px;padding:2px 6px;border:1px solid #a9bfd3;white-space:nowrap;text-align:left;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-alv-tree thead th\{height:22px;background:linear-gradient(#e9f3fa,#c7dae9);border-color:#8daac4;font-weight:700;\}|.
    rv_html = rv_html && |.gg-alv-tree tbody tr:nth-child(even) td\{background:#edf4fa;\}|.
    rv_html = rv_html && |.gg-alv-tree tbody tr.gg-state-selected td\{background:#c7dced;color:#102f4d;font-weight:600;\}|.
    rv_html = rv_html && |.gg-alv-tree tbody th\{font-weight:400;\}|.
    rv_html = rv_html && |.gg-alv-tree input[type=checkbox]\{accent-color:#6f9fc5;width:14px;height:14px;margin:0;vertical-align:middle;\}|.
    rv_html = rv_html && |.gg-alv-tree-toolbar-spacer\{flex:0 0 32px;\}|.
    rv_html = rv_html && |.gg-alv-tree [role=tree]\{margin:0;padding:0;list-style:none;\}|.
    rv_html = rv_html && |.gg-alv-tree .gg-tree-indent\{display:flex;align-items:center;gap:3px;min-height:18px;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-alv-tree .gg-tree-disclosure\{display:inline-flex;align-items:center;justify-content:center;width:12px;height:18px;padding:0;border:0;background:transparent;color:#1f4f73;font:inherit;line-height:1;cursor:pointer;\}|.
    rv_html = rv_html && |.gg-alv-tree .gg-tree-disclosure:hover,.gg-alv-tree .gg-tree-disclosure:focus\{background:#c7dced;outline:1px dotted #1f4f73;\}|.
    rv_html = rv_html && |.gg-alv-tree .gg-tree-node-icon\{display:inline-flex;align-items:center;justify-content:center;width:16px;height:16px;color:#2a6b9a;\}|.
    rv_html = rv_html && |.gg-alv-tree .gg-tree-item-link\{color:#075e9a;text-decoration:underline;text-decoration-style:dotted;\}|.
    rv_html = rv_html && |.gg-alv-tree .gg-tree-item-button\{min-height:20px;padding:1px 8px;border:1px solid #bca848;background:#fff2a8;color:#25384a;border-radius:2px;\}|.
    rv_html = rv_html && |.gg-alv-tree .gg-alv-tree-cell--number\{text-align:right;\}|.
    rv_html = rv_html && |.gg-alv-tree .gg-alv-tree-filler\{background:#e5eff7;border-right:0;\}|.
    rv_html = rv_html && |.gg-calendar-week-scroll\{max-width:100%;overflow:auto;border:1px solid #9ab0c4;background:#fff;color:#123b64;\}|.
    rv_html = rv_html && |.gg-calendar-week-grid\{border-collapse:collapse;table-layout:fixed;min-width:max-content;font:12px Arial,sans-serif;\}|.
    rv_html = rv_html && |.gg-calendar-week-grid th,.gg-calendar-week-grid td\{min-width:30px;height:24px;padding:2px 4px;border:1px solid #c5d3df;text-align:center;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-calendar-week-grid .gg-calendar-month-heading\{min-width:0;background:#e2edf6;color:#173c5e;font-weight:700;white-space:nowrap;\}|.
    rv_html = rv_html && |.gg-calendar-week-grid .gg-calendar-week-number\{background:#f0f4f7;color:#4b647a;font-weight:600;\}|.
    rv_html = rv_html && |.gg-calendar-week-grid .gg-calendar-weekday\{position:sticky;left:0;z-index:1;min-width:34px;background:#e8eef3;color:#3d586f;font-weight:600;\}|.
    rv_html = rv_html && |.gg-calendar-week-grid .gg-calendar-weekend\{background:#f5f7f9;color:#748392;\}|.
    rv_html = rv_html && |.gg-calendar-week-grid .gg-calendar-selected\{background:#c5e3f7;color:#123b64;font-weight:700;\}|.
    rv_html = rv_html && |.gg-calendar-week-grid .gg-calendar-marked\{box-shadow:inset 0 -3px #e0a126;\}|.
    rv_html = rv_html && |.gg-calendar-day-info\{display:none;\}|.
    rv_html = rv_html && |[role=tree]\{margin:0;padding:4px 8px;list-style:none;\}|.
    rv_html = rv_html && |.gg-tree-node\{display:block;min-height:22px;padding:2px 6px;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-tree-node[hidden]\{display:none;\}|.
    rv_html = rv_html && |.gg-tree-node.gg-state-selected\{background:#c7dced;color:#102f4d;font-weight:600;\}|.
    rv_html = rv_html && |.gg-control-toolbar,.gg-alv-toolbar\{display:flex;align-items:center;gap:4px;min-height:26px;padding:2px 4px;background:linear-gradient(var(--gg-panel),var(--gg-work-area));border:1px solid var(--gg-border-dark);box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-control-toolbar button,.gg-alv-toolbar button\{min-height:22px;padding:2px 8px;border:1px solid var(--gg-border);border-radius:1px;background:linear-gradient(#fff,var(--gg-panel));color:#123b64;font:inherit;cursor:pointer;\}|.
    rv_html = rv_html && |.gg-control-toolbar button,.gg-alv-toolbar button,.gg-textedit-tool-button\{display:inline-flex;align-items:center;justify-content:center;gap:3px;\}|.
    rv_html = rv_html && |.gg-alv-toolbar .gg-alv-tool-button\{width:26px;padding:2px;\}|.
    rv_html = rv_html && |.gg-textedit-tool-button\{min-width:24px;min-height:22px;padding:2px 4px;border:1px solid #8daac4;border-radius:1px;background:linear-gradient(#fff,#dceaf5);color:#123b64;cursor:pointer;\}|.
    rv_html = rv_html && |.gg-control-toolbar .wb-icon,.gg-alv-toolbar .wb-icon,.gg-textedit-toolbar .wb-icon\{width:16px;height:16px;flex:0 0 16px;\}|.
    rv_html = rv_html && |.gg-modal-backdrop\{position:fixed;inset:0;z-index:900;display:flex;align-items:center;justify-content:center;padding:24px;box-sizing:border-box;background:rgba(19,45,72,.48);backdrop-filter:blur(2px);\}|.
    rv_html = rv_html && |.gg-modal-panel\{display:flex;flex-direction:column;width:min(760px,100%);max-height:calc(100vh - 48px);overflow:auto;background:#fff;border:1px solid #7594b2;border-radius:4px;box-shadow:0 18px 48px rgba(18,52,84,.34);color:#1d2d3e;\}|.
    rv_html = rv_html && |.gg-modal-header\{display:flex;align-items:center;justify-content:space-between;gap:16px;padding:10px 14px;background:linear-gradient(#f8fbfe,#e2edf7);border-bottom:1px solid #b4c8db;color:#174a80;font-size:14px;font-weight:650;\}|.
    rv_html = rv_html && |.gg-modal-kind\{font-size:11px;font-weight:400;color:#55738f;text-transform:uppercase;\}|.
    rv_html = rv_html && |.gg-modal-panel>.gg-page\{padding:12px 14px 16px;\}|.
    rv_html = rv_html && |.gg-free-selection-modal\{position:fixed;inset:0;z-index:950;display:flex;align-items:center;justify-content:center;padding:24px;box-sizing:border-box;background:rgba(19,45,72,.48);backdrop-filter:blur(2px);\}|.
    rv_html = rv_html && |.gg-free-selection-modal--fullscreen\{align-items:stretch;justify-content:stretch;padding:12px;\}|.
    rv_html = rv_html && |.gg-free-selection-panel\{display:flex;flex-direction:column;width:min(900px,100%);max-height:calc(100vh - 48px);overflow:hidden;background:#fff;border:1px solid #7594b2;border-radius:4px;box-shadow:0 18px 48px rgba(18,52,84,.34);color:#1d2d3e;\}|.
    rv_html = rv_html && |.gg-free-selection-modal--fullscreen .gg-free-selection-panel\{width:100%;max-height:none;\}|.
    rv_html = rv_html && |.gg-free-selection-header\{display:flex;align-items:center;justify-content:space-between;gap:16px;padding:10px 14px;background:linear-gradient(#f8fbfe,#e2edf7);border-bottom:1px solid #b4c8db;color:#174a80;\}|.
    rv_html = rv_html && |.gg-free-selection-header h2\{margin:0;font-size:16px;font-weight:650;\}|.
    rv_html = rv_html && |.gg-free-selection-header span\{font-size:11px;color:#55738f;text-transform:uppercase;\}|.
    rv_html = rv_html && |.gg-free-selection-body\{display:grid;grid-template-columns:minmax(190px,.7fr) minmax(0,1.6fr);gap:0;min-height:0;overflow:auto;background:#f8fbfe;\}|.
    rv_html = rv_html && |.gg-free-selection-tree,.gg-free-selection-criteria\{padding:14px;\}|.
    rv_html = rv_html && |.gg-free-selection-tree\{border-right:1px solid #b4c8db;background:#e3eff8;\}|.
    rv_html = rv_html && |.gg-free-selection-tree h3,.gg-free-selection-criteria h3\{margin:0 0 10px;color:#174a80;font-size:13px;\}|.
    rv_html = rv_html && |.gg-free-selection-tree-item\{display:flex;align-items:center;gap:7px;min-height:28px;padding:3px 6px;border:1px solid transparent;color:#1d456c;cursor:pointer;\}|.
    rv_html = rv_html && |.gg-free-selection-tree-item:hover,.gg-free-selection-tree-item:focus-within\{border-color:#86a9cc;background:#eef6fd;\}|.
    rv_html = rv_html && |.gg-free-selection-row\{display:grid;grid-template-columns:minmax(9rem,1fr) 6.5rem 6.5rem minmax(7rem,1fr) minmax(7rem,1fr);gap:6px;align-items:center;margin-bottom:7px;\}|.
    rv_html = rv_html && |.gg-free-selection-row label\{color:#123b64;font-weight:600;\}|.
    rv_html = rv_html && |.gg-free-selection-row input,.gg-free-selection-row select\{height:26px;min-width:0;padding:2px 5px;border:1px solid #8daac4;border-radius:2px;background:#fff1a6;color:#123b64;font:inherit;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-free-selection-actions\{display:flex;align-items:center;gap:8px;padding:10px 14px;border-top:1px solid #b4c8db;background:#e3eff8;\}|.
    rv_html = rv_html && |.gg-free-selection-actions button\{min-height:28px;padding:3px 14px;border:1px solid #8c8c8c;border-radius:2px;background:linear-gradient(#fffbd2,#fff3a3);color:#2b2a13;font:inherit;cursor:pointer;\}|.
    rv_html = rv_html && |.gg-free-selection-actions button:hover,.gg-free-selection-actions button:focus\{background:#fff;border-color:#5e8fbd;outline:0;\}|.
    rv_html = rv_html && |.wb-icon-sprite\{position:absolute;width:0;height:0;overflow:hidden;\}|.
    rv_html = rv_html && |.wb-icon\{display:inline-block;width:1em;height:1em;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;vertical-align:middle;\}|.
    rv_html = rv_html && |.gg-selection\{max-width:100%;padding:0 0 16px;color:#123b64;\}|.
    rv_html = rv_html && |.gg-selection>form\{display:flex;flex-direction:column;gap:2px;\}|.
    rv_html = rv_html && |.gg-selection fieldset\{min-width:0;margin:.75rem 0;padding:.75rem;border:1px solid var(--gg-border-dark);border-radius:2px;background:linear-gradient(var(--gg-panel),var(--gg-work-area));box-shadow:0 1px 4px rgba(34,67,102,.12);\}|.
    rv_html = rv_html && |.gg-selection>form>input[type=hidden]+fieldset\{margin-top:0;\}|.
    rv_html = rv_html && |.gg-selection fieldset>legend\{padding:0 7px;color:#123b64;font-size:13px;font-weight:600;\}|.
    rv_html = rv_html && |.gg-selection-line\{display:flex;align-items:center;gap:10px;min-height:28px;padding:1px 0;\}|.
    rv_html = rv_html && |.gg-selection-line .gg-field\{display:flex;align-items:center;min-height:26px;width:auto;margin:0;padding:0;\}|.
    rv_html = rv_html && |.gg-selection-line .gg-field>label\{min-width:0;margin:0 6px 0 0;white-space:nowrap;\}|.
    rv_html = rv_html && |.gg-selection-line .gg-parameter>input[type=text]\{width:20ch;min-width:0;\}|.
    rv_html = rv_html && |.gg-selection-comment\{margin:4px 0;color:#123b64;\}|.
    rv_html = rv_html && |.gg-selection-line .gg-selection-comment\{margin:0;\}|.
    rv_html = rv_html && |.gg-selection-uline\{width:70ch;max-width:100%;margin:4px 0;border:0;border-top:1px solid #315a7f;\}|.
    rv_html = rv_html && |.gg-selection-skip\{height:12px;\}|.
    rv_html = rv_html && |.gg-field\{display:flex;gap:.5rem;align-items:center;margin:.35rem 0;\}|.
    rv_html = rv_html && |.gg-selection .gg-field\{min-height:var(--gg-row);margin:0;padding:1px 0;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-selection .gg-field label\{min-width:12rem;color:#123b64;font-weight:400;\}|.
* An input is sized by the size attribute the renderer derives from the
* declared type, so a date, an integer and a long text differ in width the way
* they do on a dynpro. Only the lower bound is fixed here.
    rv_html = rv_html && |.gg-selection .gg-parameter>input[type=text]\{width:auto;min-width:5rem;max-width:100%;\}|.
    rv_html = rv_html && |.gg-selection .gg-parameter>select\{width:auto;min-width:10rem;max-width:100%;\}|.
    rv_html = rv_html && |.gg-selection .gg-type-text,.gg-selection .gg-type-date,.gg-selection .gg-type-time\{text-align:left;\}|.
    rv_html = rv_html && |.gg-selection .gg-type-number,.gg-dynpro .gg-type-number,.gg-alv .gg-type-number\{text-align:right;\}|.
    rv_html = rv_html && |.gg-selection input[type=text],.gg-selection select\{height:var(--gg-row);padding:2px 6px;border:1px solid var(--gg-border-dark);border-radius:1px;background:var(--gg-input);color:#123b64;box-sizing:border-box;font:inherit;box-shadow:inset 0 1px 2px rgba(54,87,116,.18);\}|.
    rv_html = rv_html && |.gg-selection input[type=text]:focus,.gg-selection select:focus\{border-color:#5e8fbd;box-shadow:0 0 0 2px rgba(94,143,189,.25),inset 0 1px 2px rgba(54,87,116,.18);outline:0;\}|.
    rv_html = rv_html && |.gg-selection input[required]\{background:#fff1a6;border-color:#d4a000;\}|.
    rv_html = rv_html && |.gg-selection input:disabled,.gg-selection select:disabled\{background:#d1d1d1;color:#808080;cursor:default;\}|.
    rv_html = rv_html && |.gg-selection .gg-choice\{gap:8px;min-height:26px;padding:2px 0;\}|.
    rv_html = rv_html && |.gg-selection .gg-choice input[type=checkbox],.gg-selection .gg-choice input[type=radio]\{width:14px;height:14px;margin:0;accent-color:#28679e;\}|.
    rv_html = rv_html && |.gg-selection .gg-choice label\{min-width:0;cursor:pointer;\}|.
* A select-option is a row in the same label column as the parameters, so the
* group carries no frame of its own. Row numbers appear only once a range has
* more than one row to distinguish.
    rv_html = rv_html && |.gg-selection .gg-range\{align-items:flex-start;padding:1px 0;\}|.
    rv_html = rv_html && |.gg-range-name\{flex:0 0 auto;min-width:12rem;padding-top:3px;color:#123b64;\}|.
    rv_html = rv_html && |.gg-range-list\{flex:1 1 auto;min-width:0;display:grid;gap:2px;\}|.
* The columns are sized by their content, not stretched across the card, so a
* two character carrier range does not span the full width the way it did.
    rv_html = rv_html && |.gg-range-row\{display:grid;grid-template-columns:auto auto auto 22px 22px;justify-content:start;align-items:center;gap:5px;min-height:26px;padding:1px 0;border:0;background:transparent;box-shadow:none;\}|.
    rv_html = rv_html && |.gg-range-list--numbered .gg-range-row\{grid-template-columns:24px auto auto auto 22px 22px;\}|.
    rv_html = rv_html && |.gg-range-list--numbered .gg-range-row--single\{grid-template-columns:24px auto 22px 22px;\}|.
    rv_html = rv_html && |.gg-range-index\{display:inline-flex;align-items:center;justify-content:center;width:20px;height:20px;border:1px solid #8daac4;border-radius:1px;background:#d5e6f3;color:#2c618d;font-size:11px;font-weight:700;\}|.
* From and To sit next to their own input, so they must not take the 12rem
* label column that the field labels to their left occupy.
    rv_html = rv_html && |.gg-range-input\{width:auto;min-width:5rem;\}|.
    rv_html = rv_html && |.gg-range-to\{color:#315a7f;font-size:12px;\}|.
    rv_html = rv_html && |.gg-required-marker\{display:inline-flex;align-items:center;justify-content:center;width:18px;height:18px;border:1px solid #c39400;border-radius:50%;background:#fff1a6;color:#8a5c00;font-size:12px;font-weight:700;\}|.
    rv_html = rv_html && |.gg-range-row--single\{grid-template-columns:auto 22px 22px;\}|.
    rv_html = rv_html && |.gg-selection .gg-actions\{display:flex;justify-content:flex-start;gap:8px;margin:.75rem 0 0;padding:.75rem 0 0;border:0;border-top:1px solid #8daac4;border-radius:0;background:transparent;box-shadow:none;\}|.
    rv_html = rv_html && |.gg-selection .gg-actions:hover\{background:transparent;box-shadow:none;\}|.
    rv_html = rv_html && |.gg-selection button:not(.gg-help-button)\{min-height:26px;padding:2px 12px;border:1px solid #8c8c8c;border-radius:2px;background:linear-gradient(#fefefe,#d9d9d9);color:#163e6b;font:inherit;cursor:pointer;box-shadow:none;\}|.
    rv_html = rv_html && |.gg-selection button:not(.gg-help-button):hover,.gg-selection button:not(.gg-help-button):focus\{background:linear-gradient(#fff,#c7dced);border-color:#5e8fbd;outline:0;\}|.
    rv_html = rv_html && |.gg-selection button:not(.gg-help-button):disabled\{background:#d1d1d1;color:#808080;cursor:default;\}|.
    rv_html = rv_html && |.gg-selection>form>button.gg-selection-button\{align-self:flex-start;width:auto;background:linear-gradient(#fffbd2,var(--gg-action));border-color:#a68e37;color:#2b2a13;\}|.
    rv_html = rv_html && |.gg-selection-button .wb-icon\{width:14px;height:14px;vertical-align:-2px;margin-right:5px;\}|.
    rv_html = rv_html && |.gg-selection nav[role=tablist]\{display:flex;align-items:flex-end;gap:2px;padding:0 4px;border-bottom:2px solid #6f9ac1;background:#d0e1ef;\}|.
    rv_html = rv_html && |.gg-selection nav[role=tablist] button\{min-height:28px;margin:0;padding:3px 15px;border:1px solid #8eacc8;border-bottom:0;border-radius:3px 3px 0 0;background:linear-gradient(#e8f2fa,#bfd5e8);color:#163e6b;white-space:nowrap;box-shadow:none;\}|.
    rv_html = rv_html && |.gg-selection nav[role=tablist] button[aria-selected=true]\{background:#e3eff8;color:#102f4d;font-weight:600;position:relative;top:2px;\}|.
    rv_html = rv_html && |.gg-selection .gg-message\{margin:0 0 8px;padding:8px 10px;border-radius:2px;box-shadow:none;\}|.
    rv_html = rv_html && |.gg-selection>form>p\{margin:4px 0;color:#315a7f;\}|.
    rv_html = rv_html && |.gg-selection>form>hr\{width:100%;margin:4px 0;border:0;border-top:1px solid #8daac4;\}|.
    rv_html = rv_html && |.gg-selection [hidden]\{display:none!important;\}|.
    rv_html = rv_html && |@media(max-width:720px)\{|.
    rv_html = rv_html && |.gg-selection\{padding-bottom:12px;\}|.
    rv_html = rv_html && |.gg-selection .gg-field\{display:grid;grid-template-columns:1fr;gap:4px;padding:4px 0;\}|.
    rv_html = rv_html && |.gg-selection .gg-field>label\{grid-column:1;min-width:0;\}|.
    rv_html = rv_html && |.gg-selection .gg-parameter>input[type=text],.gg-selection .gg-parameter>select\{width:100%;min-width:0;max-width:none;\}|.
    rv_html = rv_html && |.gg-selection .gg-range\{display:grid;grid-template-columns:1fr;gap:4px;\}|.
    rv_html = rv_html && |.gg-range-name\{min-width:0;padding-top:0;\}|.
    rv_html = rv_html && |.gg-selection fieldset\{padding:.6rem .5rem .7rem;\}|.
    rv_html = rv_html && |.gg-range-row,.gg-range-row--single\{grid-template-columns:minmax(0,1fr) minmax(0,2fr);gap:4px;\}|.
    rv_html = rv_html && |.gg-range-index\{grid-column:1 / -1;justify-self:start;\}|.
    rv_html = rv_html && |.gg-range-input\{grid-column:2;\}|.
    rv_html = rv_html && |.gg-range-to\{grid-column:2;\}|.
    rv_html = rv_html && |.gg-range-row--single .gg-range-input\{grid-column:2;\}|.
    rv_html = rv_html && |.gg-range-row .gg-help-button\{justify-self:start;\}|.
    rv_html = rv_html && |.gg-selection .gg-actions\{flex-wrap:wrap;\}|.
    rv_html = rv_html && |.gg-selection .gg-actions button\{flex:1 1 9rem;\}|.
    rv_html = rv_html && |\}|.
    rv_html = rv_html && |.gg-dynpro\{position:relative;min-height:12rem;overflow:hidden;background:linear-gradient(var(--gg-panel),var(--gg-work-area));box-sizing:border-box;color:#123b64;\}|.
    rv_html = rv_html && |.gg-context-menu\{position:fixed;z-index:1200;min-width:170px;padding:3px;background:#fff;border:1px solid #7594b2;box-shadow:0 4px 14px rgba(18,52,84,.28);color:#123b64;\}|.
    rv_html = rv_html && |.gg-context-menu[hidden]\{display:none;\}|.
    rv_html = rv_html && |.gg-context-menu-list\{display:grid;gap:1px;margin:0;padding:0;list-style:none;\}|.
    rv_html = rv_html && |.gg-context-menu-item\{display:block;width:100%;min-height:26px;padding:3px 12px;border:0;background:transparent;color:#123b64;text-align:left;font:inherit;cursor:pointer;\}|.
    rv_html = rv_html && |.gg-context-menu-item:hover,.gg-context-menu-item:focus\{background:#d9e8f7;outline:0;\}|.
    rv_html = rv_html && |.gg-context-menu-item:disabled\{background:#eee;color:#808080;cursor:default;\}|.
    rv_html = rv_html && |.gg-context-menu-separator\{height:1px;margin:3px 4px;background:#b4c8db;\}|.
    rv_html = rv_html && |.gg-context-menu-group\{padding:3px 0 0;\}|.
    rv_html = rv_html && |.gg-context-menu-group-label\{display:block;padding:2px 12px;color:#55738f;font-size:11px;font-weight:600;\}|.
    rv_html = rv_html && |.gg-dynpro-control\{position:absolute;box-sizing:border-box;color:#123b64;font:inherit;\}|.
* A BOX is the group box the Screen Painter draws: a titled band across the top
* of the frame and a body a shade darker than the work area, rather than the
* browser default groove border a bare fieldset would carry.
* The box is an empty fieldset and the fields it encloses are absolutely
* positioned siblings, not children, so it takes the layer below every other
* control for its fill not to paint over them whatever the declaration order.
    rv_html = rv_html && |.gg-dynpro .gg-dynpro-control\{z-index:1;\}|.
    rv_html = rv_html && |.gg-dynpro fieldset.gg-dynpro-control\{z-index:0;min-width:0;margin:0;padding:0;border:1px solid #93b2d0;background:#deebf4;\}|.
* Floating the legend takes it out of the notched-border rendering, so it lays
* out as an ordinary block filling the width of the frame.
    rv_html = rv_html && |.gg-dynpro fieldset.gg-dynpro-control>legend\{float:left;width:100%;box-sizing:border-box;margin:0;padding:3px 10px;border-bottom:1px solid #87a3c0;background:linear-gradient(#cddfef,#c1d6ea);color:#12314f;font-size:12px;line-height:15px;\}|.
    rv_html = rv_html && |.gg-dynpro input,.gg-dynpro select,.gg-dynpro button\{font:inherit;\}|.
    rv_html = rv_html && |.gg-dynpro input[type=text],.gg-dynpro input[type=password],.gg-dynpro select\{height:var(--gg-row);padding:2px 6px;border:1px solid var(--gg-border-dark);border-radius:1px;background:var(--gg-input);color:#123b64;box-sizing:border-box;box-shadow:inset 0 1px 2px rgba(54,87,116,.18);\}|.
    rv_html = rv_html && |.gg-dynpro .gg-type-text,.gg-dynpro .gg-type-date,.gg-dynpro .gg-type-time\{text-align:left;\}|.
    rv_html = rv_html && |.gg-dynpro input[type=checkbox],.gg-dynpro input[type=radio]\{width:14px;height:14px;margin:0;flex:0 0 auto;accent-color:#28679e;\}|.
    rv_html = rv_html && |.gg-dynpro-control>input[type=text],.gg-dynpro-control>input[type=password]\{width:100%;\}|.
    rv_html = rv_html && |.gg-dynpro input[required]\{background:#fff1a6;border-color:#d4a000;\}|.
    rv_html = rv_html && |.gg-dynpro button\{min-height:26px;padding:2px 12px;border:1px solid #8c8c8c;border-radius:2px;background:linear-gradient(#fefefe,#d9d9d9);color:#163e6b;cursor:pointer;\}|.
    rv_html = rv_html && |.gg-dynpro button:hover,.gg-dynpro button:focus\{background:linear-gradient(#fff,#c7dced);border-color:#5e8fbd;outline:0;\}|.
    rv_html = rv_html && |.gg-dynpro button:disabled\{background:#d1d1d1;color:#808080;cursor:default;\}|.
    rv_html = rv_html && |.gg-dynpro>form>button.gg-dynpro-control\{background:linear-gradient(#fffbd2,var(--gg-action));border-color:#a68e37;color:#2b2a13;\}|.
    rv_html = rv_html && |.gg-dynpro>form>button.gg-dynpro-control\{display:flex;align-items:center;justify-content:center;gap:8px;\}|.
    rv_html = rv_html && |.gg-dynpro>form>button.gg-dynpro-control .wb-icon\{width:16px;height:16px;\}|.
    rv_html = rv_html && |.gg-dynpro .gg-dynpro-field>label\{display:block;width:100%;height:100%;\}|.
    rv_html = rv_html && |.gg-dynpro .gg-dynpro-field>label>input\{width:100%;\}|.
    rv_html = rv_html && |.gg-dynpro>form>output.gg-dynpro-control\{display:block;overflow:hidden;white-space:nowrap;padding:2px 6px;border:1px solid #8daac4;background:#e4eff8;color:#123b64;box-sizing:border-box;\}|.
    rv_html = rv_html && |button.gg-help-button\{display:inline-flex;align-items:center;justify-content:center;min-height:0;width:22px;height:22px;padding:0;border:1px solid #7f9bb5;border-radius:50%;background:#fff;color:#123b64;cursor:pointer;box-shadow:0 1px 3px rgba(18,59,100,.35);opacity:0;visibility:hidden;transition:opacity .08s linear;\}|.
    rv_html = rv_html && |button.gg-help-button:hover,button.gg-help-button:focus\{background:#d9eaf9;border-color:#3c74a6;outline:0;\}|.
    rv_html = rv_html && |button.gg-help-button .wb-icon\{width:14px;height:14px;\}|.
    rv_html = rv_html && |button.gg-range-editor-open\{opacity:1;visibility:visible;\}|.
    rv_html = rv_html && |.gg-field:focus-within .gg-help-button,.gg-range:focus-within .gg-help-button,.gg-dynpro-field:focus-within .gg-help-button\{opacity:1;visibility:visible;\}|.
    rv_html = rv_html && |.gg-dynpro .gg-dynpro-field>.gg-help-button\{position:absolute;left:100%;top:2px;margin-left:5px;\}|.
    rv_html = rv_html && |.gg-value-help-modal\{position:fixed;inset:0;z-index:1000;display:flex;align-items:center;justify-content:center;padding:24px;box-sizing:border-box;background:rgba(19,45,72,.48);backdrop-filter:blur(2px);animation:gg-value-help-in .12s ease-out;\}|.
    rv_html = rv_html && |.gg-value-help-modal[hidden]\{display:none;\}|.
    rv_html = rv_html && |.gg-popup-modal\{position:fixed;inset:0;z-index:1100;display:flex;align-items:center;justify-content:center;padding:24px;box-sizing:border-box;background:rgba(19,45,72,.48);backdrop-filter:blur(2px);animation:gg-value-help-in .12s ease-out;\}|.
    rv_html = rv_html && |.gg-popup-panel\{width:min(520px,100%);\}|.
    rv_html = rv_html && |.gg-popup-body\{display:grid;gap:10px;padding:16px;background:#f8fbfe;color:#1d2d3e;\}|.
    rv_html = rv_html && |.gg-popup-body p\{margin:0;line-height:1.4;\}|.
    rv_html = rv_html && |.gg-popup-field\{display:grid;grid-template-columns:minmax(8rem,auto) minmax(0,1fr);gap:10px;align-items:center;\}|.
    rv_html = rv_html && |.gg-popup-field input\{width:100%;height:26px;padding:2px 6px;border:1px solid var(--gg-border-dark);border-radius:2px;background:var(--gg-input);color:#123b64;box-sizing:border-box;font:inherit;\}|.
    rv_html = rv_html && |.gg-popup-actions\{display:flex;justify-content:flex-end;gap:8px;padding:10px 14px;background:#eef5fb;border-top:1px solid #b4c8db;\}|.
    rv_html = rv_html && |.gg-range-editor-modal\{position:fixed;inset:0;z-index:1000;display:flex;align-items:center;justify-content:center;padding:24px;box-sizing:border-box;background:rgba(19,45,72,.48);backdrop-filter:blur(2px);animation:gg-value-help-in .12s ease-out;\}|.
    rv_html = rv_html && |.gg-range-editor-modal[hidden]\{display:none;\}|.
    rv_html = rv_html && |.gg-value-help-panel\{display:flex;flex-direction:column;width:min(430px,100%);max-height:min(560px,calc(100vh - 48px));overflow:hidden;background:#fff;border:1px solid #7594b2;border-radius:5px;box-shadow:0 18px 48px rgba(18,52,84,.34);color:#1d2d3e;\}|.
    rv_html = rv_html && |.gg-value-help-header\{display:flex;align-items:center;justify-content:space-between;gap:16px;padding:12px 14px;background:linear-gradient(#f8fbfe,#e2edf7);border-bottom:1px solid #b4c8db;\}|.
    rv_html = rv_html && |.gg-value-help-header h2\{margin:0;color:#174a80;font-size:16px;font-weight:650;line-height:1.25;\}|.
    rv_html = rv_html && |.gg-value-help-modal .gg-value-help-close\{display:inline-flex;align-items:center;justify-content:center;width:28px;height:28px;min-height:28px;padding:0;border:1px solid transparent;border-radius:3px;background:transparent;color:#315a7f;cursor:pointer;flex:0 0 auto;\}|.
    rv_html = rv_html && |.gg-value-help-modal .gg-value-help-close:hover,.gg-value-help-modal .gg-value-help-close:focus\{border-color:#86a9cc;background:#d9e8f7;color:#123b64;outline:0;\}|.
    rv_html = rv_html && |.gg-value-help-modal .gg-value-help-close .wb-icon\{width:17px;height:17px;\}|.
    rv_html = rv_html && |.gg-value-help-status\{display:flex;min-height:0;overflow:hidden;\}|.
    rv_html = rv_html && |.gg-value-help\{margin:0;padding:12px 14px;overflow:auto;background:#f8fbfe;\}|.
    rv_html = rv_html && |.gg-value-help ul\{display:grid;gap:6px;margin:0;padding:0;list-style:none;\}|.
    rv_html = rv_html && |.gg-value-help li\{padding:9px 10px;border:1px solid #c6d6e5;border-radius:3px;background:#fff;color:#1d456c;line-height:1.3;box-shadow:0 1px 1px rgba(34,67,102,.06);overflow-wrap:anywhere;\}|.
    rv_html = rv_html && |.gg-value-help li\{cursor:pointer;\}|.
    rv_html = rv_html && |.gg-value-help li:hover,.gg-value-help li:focus\{border-color:#6f9ac1;background:#eef6fd;outline:0;\}|.
    rv_html = rv_html && |.gg-range-editor-panel\{width:min(760px,100%);\}|.
    rv_html = rv_html && |.gg-range-editor-body\{padding:12px 14px;background:#f8fbfe;overflow:auto;\}|.
    rv_html = rv_html && |.gg-range-editor-body>p\{margin:0 0 10px;color:#315a7f;font-size:12px;\}|.
    rv_html = rv_html && |.gg-range-editor-list\{display:grid;gap:5px;\}|.
    rv_html = rv_html && |.gg-range-editor-row\{display:grid;grid-template-columns:7rem 8rem minmax(8rem,1fr) minmax(8rem,1fr) 28px;gap:6px;align-items:center;\}|.
    rv_html = rv_html && |.gg-range-editor-row select,.gg-range-editor-row input\{width:100%;min-width:0;height:26px;padding:2px 6px;border:1px solid #8daac4;border-radius:2px;background:#fff;color:#123b64;box-sizing:border-box;font:inherit;\}|.
    rv_html = rv_html && |.gg-range-editor-row button\{width:26px;min-height:26px;padding:0;border:1px solid #8c8c8c;border-radius:2px;background:linear-gradient(#fefefe,#d9d9d9);color:#163e6b;font:inherit;cursor:pointer;\}|.
    rv_html = rv_html && |.gg-range-editor-actions\{display:flex;align-items:center;gap:8px;margin-top:12px;padding-top:10px;border-top:1px solid #b4c8db;\}|.
    rv_html = rv_html && |.gg-range-editor-spacer\{flex:1 1 auto;\}|.
    rv_html = rv_html && |@keyframes gg-value-help-in\{from\{opacity:0\}to\{opacity:1\}\}|.
    rv_html = rv_html && |@media(prefers-reduced-motion:reduce)\{.gg-value-help-modal\{animation:none\}\}|.
    rv_html = rv_html && |@media(max-width:480px)\{.gg-value-help-modal\{padding:12px\}.gg-value-help-panel\{max-height:calc(100vh - 24px)\}\}|.
    rv_html = rv_html && |@media(max-width:760px)\{.gg-free-selection-modal\{padding:10px\}.gg-free-selection-body\{grid-template-columns:1fr\}.gg-free-selection-tree\{border-right:0;border-bottom:1px solid #b4c8db\}\}|.
    rv_html = rv_html && |@media(max-width:760px)\{.gg-free-selection-row\{grid-template-columns:1fr 1fr\}.gg-free-selection-row label\{grid-column:1\}\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control]\{overflow:auto;background:#e4eff8;border:1px solid #8daac4;box-sizing:border-box;scrollbar-color:#9eb5c8 #d6e5f0;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] table\{border-collapse:collapse;table-layout:fixed;min-width:100%;width:max-content;background:#fff;color:#123b64;font-size:13px;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] caption\{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap;border:0;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] th\{height:28px;padding:4px 8px;text-align:left;white-space:nowrap;background:linear-gradient(#e9f3fa,#c7dae9);border:1px solid #8daac4;color:#123b64;font-weight:700;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] td\{height:28px;padding:3px 8px;white-space:nowrap;background:#fff;border:1px solid #c1d2e0;color:#123b64;box-sizing:border-box;vertical-align:middle;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] tbody tr:nth-child(even) td\{background:#f3f8fc;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] td output\{display:block;white-space:nowrap;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] td input\{width:100%;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-dynpro [role=tablist]\{display:flex;align-items:flex-start;gap:2px;padding:0 4px;border-bottom:2px solid #6f9ac1;background:#d0e1ef;\}|.
    rv_html = rv_html && |.gg-dynpro [role=tab]\{min-height:28px;margin:0;padding:3px 15px;border:1px solid #8eacc8;border-bottom:0;border-radius:3px 3px 0 0;background:linear-gradient(#e8f2fa,#bfd5e8);color:#163e6b;white-space:nowrap;\}|.
    rv_html = rv_html && |.gg-dynpro [role=tab][aria-selected=true]\{background:#e3eff8;color:#102f4d;font-weight:600;position:relative;top:2px;\}|.
    rv_html = rv_html && |.gg-dynpro .gg-field\{margin:0;\}|.
    rv_html = rv_html && |.gg-dynpro>form> .gg-field\{position:absolute;\}|.
    rv_html = rv_html && |.gg-visually-hidden\{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);\}|.
    rv_html = rv_html && |@media(max-width:720px)\{.gg-page\{gap:6px\}.gg-action-row\{flex-wrap:wrap\}.gg-list\{overflow-x:auto\}.gg-alv\{overflow-x:auto\}.gg-dynpro\{min-width:640px\}.gg-dynpro [role=tablist],.gg-control-toolbar,.gg-alv-toolbar\{overflow-x:auto;white-space:nowrap\}\}|.
    rv_html = rv_html && |</style></head><body><div class="wb-shell">|.
    rv_html = rv_html && '<a class="wb-sr-only wb-skip-link" href="#gg-main-content">Skip to application</a>'.
    rv_html = rv_html && zcl_gg_host_icons=>sprite( ).
    rv_html = rv_html && zcl_gg_workbench_utility=>render_top(
      iv_runtime      = abap_true
      iv_title        = iv_title
      iv_session_id   = iv_session_id
      iv_page_id      = iv_page_id
      is_status       = is_status
      iv_content_form = COND string( WHEN iv_kind = zif_gg_host_html_v1=>page_dynpro THEN `gg-dynpro-form` ELSE `` ) ).
    rv_html = rv_html && |<div class="wb-runtime-content{ lv_content_class }" data-session-id="{ escape_attribute( iv_session_id ) }" data-page-id="{ escape_attribute( iv_page_id ) }" data-page-kind="{ escape_attribute( iv_kind ) }">|.
    rv_html = rv_html && |<main id="gg-main-content" aria-labelledby="wb-page-title">{ iv_body }</main></div>|.
    rv_html = rv_html && zcl_gg_workbench_utility=>render_bottom( ).
  ENDMETHOD.

  METHOD css_class.
    DATA lv_total TYPE abap_bool.
    DATA lv_subtotal TYPE abap_bool.
    DATA lv_hotspot TYPE abap_bool.
    DATA lv_readonly TYPE abap_bool.

    rv_class = 'gg-format'.
    CASE is_format-color.
      WHEN zif_gg_list_processing_types_v1=>color_heading.
        rv_class = rv_class && ' gg-color-heading'.
      WHEN zif_gg_list_processing_types_v1=>color_total.
        rv_class = rv_class && ' gg-color-total'.
        lv_total = abap_true.
      WHEN zif_gg_list_processing_types_v1=>color_key.
        rv_class = rv_class && ' gg-color-key'.
      WHEN zif_gg_list_processing_types_v1=>color_positive.
        rv_class = rv_class && ' gg-color-positive'.
      WHEN zif_gg_list_processing_types_v1=>color_negative.
        rv_class = rv_class && ' gg-color-negative'.
      WHEN zif_gg_list_processing_types_v1=>color_group.
        rv_class = rv_class && ' gg-color-group'.
        lv_subtotal = abap_true.
      WHEN OTHERS.
        rv_class = rv_class && ' gg-color-normal'.
    ENDCASE.
    IF is_format-intensified = abap_true.
      rv_class = rv_class && ' gg-intensified'.
    ENDIF.
    IF is_format-inverse = abap_true.
      rv_class = rv_class && ' gg-inverse'.
    ENDIF.
    IF is_format-hotspot = abap_true.
      rv_class = rv_class && ' gg-hotspot'.
      lv_hotspot = abap_true.
    ENDIF.
    IF is_format-input = abap_true.
      rv_class = rv_class && ' gg-input'.
    ELSE.
      lv_readonly = abap_true.
    ENDIF.
    rv_class = rv_class && ` ` && state_class(
      iv_total    = lv_total
      iv_subtotal = lv_subtotal
      iv_hotspot  = lv_hotspot
      iv_readonly = lv_readonly ).
  ENDMETHOD.

  METHOD message_class.
    CASE iv_type.
      WHEN zif_gg_session_types_v1=>message_type_error
          OR zif_gg_session_types_v1=>message_type_abort
          OR zif_gg_session_types_v1=>message_type_exit.
        rv_class = 'gg-error'.
      WHEN zif_gg_session_types_v1=>message_type_warning.
        rv_class = 'gg-warning'.
      WHEN zif_gg_session_types_v1=>message_type_success.
        rv_class = 'gg-success'.
      WHEN OTHERS.
        rv_class = 'gg-info'.
    ENDCASE.
  ENDMETHOD.

  METHOD state_class.
    rv_class = `gg-state`.
    IF iv_focused = abap_true.
      rv_class = rv_class && ` gg-state-focused`.
    ENDIF.
    IF iv_selected = abap_true.
      rv_class = rv_class && ` gg-state-selected`.
    ENDIF.
    IF iv_changed = abap_true.
      rv_class = rv_class && ` gg-state-changed`.
    ENDIF.
    IF iv_disabled = abap_true.
      rv_class = rv_class && ` gg-state-disabled`.
    ENDIF.
    IF iv_required = abap_true.
      rv_class = rv_class && ` gg-state-required`.
    ENDIF.
    IF iv_error = abap_true.
      rv_class = rv_class && ` gg-state-error`.
    ENDIF.
    IF iv_warning = abap_true.
      rv_class = rv_class && ` gg-state-warning`.
    ENDIF.
    IF iv_total = abap_true.
      rv_class = rv_class && ` gg-state-total`.
    ENDIF.
    IF iv_subtotal = abap_true.
      rv_class = rv_class && ` gg-state-subtotal`.
    ENDIF.
    IF iv_hotspot = abap_true.
      rv_class = rv_class && ` gg-state-hotspot`.
    ENDIF.
    IF iv_readonly = abap_true.
      rv_class = rv_class && ` gg-state-readonly`.
    ENDIF.
  ENDMETHOD.

  METHOD format_external_value.
    DATA lv_first TYPE string.
    DATA lv_second TYPE string.
    DATA lv_third TYPE string.

    rv_value = iv_value.
    CASE to_upper( iv_type ).
      WHEN 'D'.
        IF strlen( iv_value ) = 8 AND iv_value CO '0123456789'.
          lv_first = substring(
            val = iv_value
            off = 6
            len = 2 ).
          lv_second = substring(
            val = iv_value
            off = 4
            len = 2 ).
          lv_third = substring(
            val = iv_value
            off = 0
            len = 4 ).
          rv_value = |{ lv_first }.{ lv_second }.{ lv_third }|.
        ENDIF.
      WHEN 'T'.
        IF strlen( iv_value ) = 6 AND iv_value CO '0123456789'.
          lv_first = substring(
            val = iv_value
            off = 0
            len = 2 ).
          lv_second = substring(
            val = iv_value
            off = 2
            len = 2 ).
          lv_third = substring(
            val = iv_value
            off = 4
            len = 2 ).
          rv_value = |{ lv_first }:{ lv_second }:{ lv_third }|.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
