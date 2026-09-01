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
        it_breadcrumbs TYPE zif_gg_session_types_v1=>ty_breadcrumbs OPTIONAL
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
    rv_html = rv_html && |:root\{font-family:system-ui,sans-serif;color-scheme:light;\}|.
    rv_html = rv_html && |body\{line-height:1.4;\}|.
    rv_html = rv_html && |main\{max-width:100%;overflow:auto;\}|.
    rv_html = rv_html && |.gg-message\{padding:.5rem;margin:.5rem 0;border:1px solid;\}|.
    rv_html = rv_html && |.gg-error\{color:#b00020;border-color:#b00020;\}|.
    rv_html = rv_html && |.gg-warning\{color:#8a5700;border-color:#8a5700;\}|.
    rv_html = rv_html && |.gg-success\{color:#146c2e;border-color:#146c2e;\}|.
    rv_html = rv_html && |.gg-list\{font-family:ui-monospace,monospace;white-space:pre;overflow:auto;\}|.
    rv_html = rv_html && |.gg-list-line\{display:block;min-height:1.4em;\}|.
    rv_html = rv_html && |.gg-list-line button\{font:inherit;color:inherit;background:none;border:0;padding:0;text-align:left;\}|.
    rv_html = rv_html && |.gg-list-page\{break-after:page;margin-bottom:1rem;\}|.
    rv_html = rv_html && |.gg-list-fragment\{white-space:pre;\}|.
    rv_html = rv_html && |.wb-icon-sprite\{position:absolute;width:0;height:0;overflow:hidden;\}|.
    rv_html = rv_html && |.wb-icon\{display:inline-block;width:1em;height:1em;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;vertical-align:middle;\}|.
    rv_html = rv_html && |.gg-selection fieldset\{margin:.75rem 0;padding:.75rem;\}|.
    rv_html = rv_html && |.gg-field\{display:flex;gap:.5rem;align-items:center;margin:.35rem 0;\}|.
    rv_html = rv_html && |.gg-field label\{min-width:12rem;\}|.
    rv_html = rv_html && |.gg-dynpro\{position:relative;min-height:12rem;overflow:hidden;background:linear-gradient(#e3eff8,#d5e6f3);box-sizing:border-box;color:#123b64;\}|.
    rv_html = rv_html && |.gg-dynpro-control\{position:absolute;box-sizing:border-box;color:#123b64;font:inherit;\}|.
    rv_html = rv_html && |.gg-dynpro input,.gg-dynpro select,.gg-dynpro button\{font:inherit;\}|.
    rv_html = rv_html && |.gg-dynpro input[type=text],.gg-dynpro input[type=password],.gg-dynpro select\{height:26px;padding:2px 6px;border:1px solid #819db8;border-radius:1px;background:#fff;color:#123b64;box-sizing:border-box;box-shadow:inset 0 1px 2px rgba(54,87,116,.18);\}|.
    rv_html = rv_html && |.gg-dynpro-control>input[type=text],.gg-dynpro-control>input[type=password]\{width:100%;\}|.
    rv_html = rv_html && |.gg-dynpro input[required]\{background:#fff1a6;border-color:#d4a000;\}|.
    rv_html = rv_html && |.gg-dynpro button\{min-height:26px;padding:2px 12px;border:1px solid #8c8c8c;border-radius:2px;background:linear-gradient(#fefefe,#d9d9d9);color:#163e6b;cursor:pointer;\}|.
    rv_html = rv_html && |.gg-dynpro button:hover,.gg-dynpro button:focus\{background:linear-gradient(#fff,#c7dced);border-color:#5e8fbd;outline:0;\}|.
    rv_html = rv_html && |.gg-dynpro button:disabled\{background:#d1d1d1;color:#808080;cursor:default;\}|.
    rv_html = rv_html && |.gg-dynpro>form>button.gg-dynpro-control\{background:linear-gradient(#fffbd2,#f4e68d);border-color:#b9aa55;color:#111;\}|.
    rv_html = rv_html && |.gg-dynpro>form>button.gg-dynpro-control\{display:flex;align-items:center;justify-content:center;gap:8px;\}|.
    rv_html = rv_html && |.gg-dynpro>form>button.gg-dynpro-control .wb-icon\{width:16px;height:16px;\}|.
    rv_html = rv_html && |.gg-dynpro .gg-dynpro-field>label\{display:block;width:100%;height:100%;\}|.
    rv_html = rv_html && |.gg-dynpro .gg-dynpro-field>label>input\{width:100%;\}|.
    rv_html = rv_html && |button.gg-help-button\{display:inline-flex;align-items:center;justify-content:center;min-height:0;width:22px;height:22px;padding:0;border:1px solid #7f9bb5;border-radius:50%;background:#fff;color:#123b64;cursor:pointer;box-shadow:0 1px 3px rgba(18,59,100,.35);opacity:0;visibility:hidden;transition:opacity .08s linear;\}|.
    rv_html = rv_html && |button.gg-help-button:hover,button.gg-help-button:focus\{background:#d9eaf9;border-color:#3c74a6;outline:0;\}|.
    rv_html = rv_html && |button.gg-help-button .wb-icon\{width:14px;height:14px;\}|.
    rv_html = rv_html && |.gg-field:focus-within .gg-help-button,.gg-range:focus-within .gg-help-button,.gg-dynpro-field:focus-within .gg-help-button\{opacity:1;visibility:visible;\}|.
    rv_html = rv_html && |.gg-dynpro .gg-dynpro-field>.gg-help-button\{position:absolute;left:100%;top:2px;margin-left:5px;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control]\{overflow:auto;background:#e4eff8;border:1px solid #8daac4;box-sizing:border-box;scrollbar-color:#9eb5c8 #d6e5f0;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] table\{border-collapse:collapse;table-layout:fixed;min-width:100%;width:max-content;background:#fff;color:#123b64;font-size:13px;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] caption\{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap;border:0;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] th\{height:28px;padding:4px 8px;text-align:left;white-space:nowrap;background:linear-gradient(#e9f3fa,#c7dae9);border:1px solid #8daac4;color:#123b64;font-weight:700;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] td\{height:28px;padding:3px 8px;white-space:nowrap;background:#fff;border:1px solid #c1d2e0;color:#123b64;box-sizing:border-box;vertical-align:middle;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] tbody tr:nth-child(even) td\{background:#f3f8fc;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] td output\{display:block;white-space:nowrap;\}|.
    rv_html = rv_html && |.gg-dynpro [data-table-control] td input\{width:100%;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-dynpro [role=tablist]\{display:flex;align-items:flex-end;gap:2px;padding:0 4px;border-bottom:2px solid #6f9ac1;background:#d0e1ef;\}|.
    rv_html = rv_html && |.gg-dynpro [role=tab]\{min-height:28px;margin:0;padding:3px 15px;border:1px solid #8eacc8;border-bottom:0;border-radius:3px 3px 0 0;background:linear-gradient(#e8f2fa,#bfd5e8);color:#163e6b;white-space:nowrap;\}|.
    rv_html = rv_html && |.gg-dynpro [role=tab][aria-selected=true]\{background:#e3eff8;color:#102f4d;font-weight:600;position:relative;top:2px;\}|.
    rv_html = rv_html && |.gg-dynpro .gg-field\{margin:0;\}|.
    rv_html = rv_html && |.gg-dynpro>form> .gg-field\{position:absolute;\}|.
    rv_html = rv_html && |.gg-visually-hidden\{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);\}|.
    rv_html = rv_html && |</style></head><body><div class="wb-shell">|.
    rv_html = rv_html && zcl_gg_host_icons=>sprite( ).
    rv_html = rv_html && zcl_gg_workbench_utility=>render_top(
      iv_runtime      = abap_true
      iv_title        = iv_title
      iv_session_id   = iv_session_id
      iv_page_id      = iv_page_id
      is_status       = is_status
      it_breadcrumbs  = it_breadcrumbs
      iv_content_form = COND string( WHEN iv_kind = zif_gg_host_html_v1=>page_dynpro THEN `gg-dynpro-form` ELSE `` ) ).
    rv_html = rv_html && |<div class="wb-runtime-content{ lv_content_class }" data-session-id="{ escape_attribute( iv_session_id ) }" data-page-id="{ escape_attribute( iv_page_id ) }" data-page-kind="{ escape_attribute( iv_kind ) }">|.
    rv_html = rv_html && |<main>{ iv_body }</main></div>|.
    rv_html = rv_html && zcl_gg_workbench_utility=>render_bottom( ).
  ENDMETHOD.

  METHOD css_class.
    rv_class = 'gg-format'.
    CASE is_format-color.
      WHEN zif_gg_list_processing_types_v1=>color_heading.
        rv_class = rv_class && ' gg-color-heading'.
      WHEN zif_gg_list_processing_types_v1=>color_total.
        rv_class = rv_class && ' gg-color-total'.
      WHEN zif_gg_list_processing_types_v1=>color_key.
        rv_class = rv_class && ' gg-color-key'.
      WHEN zif_gg_list_processing_types_v1=>color_positive.
        rv_class = rv_class && ' gg-color-positive'.
      WHEN zif_gg_list_processing_types_v1=>color_negative.
        rv_class = rv_class && ' gg-color-negative'.
      WHEN zif_gg_list_processing_types_v1=>color_group.
        rv_class = rv_class && ' gg-color-group'.
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
    ENDIF.
    IF is_format-input = abap_true.
      rv_class = rv_class && ' gg-input'.
    ENDIF.
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

ENDCLASS.
