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
        iv_name = ls_attribute-name
        iv_value = ls_attribute-value
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
    rv_html = |<!doctype html><html lang="en"><head>|.
    rv_html = rv_html && |<meta charset="utf-8">|.
    rv_html = rv_html && |<meta name="viewport" content="width=device-width,initial-scale=1">|.
    rv_html = rv_html && |<title>{ escape_text( iv_title ) }</title>|.
    rv_html = rv_html && |<style{ attribute( iv_name = `nonce` iv_value = iv_csp_nonce iv_optional = abap_true ) }>|.
    rv_html = rv_html && |:root\{font-family:system-ui,sans-serif;color-scheme:light dark;\}|.
    rv_html = rv_html && |body\{margin:1rem;line-height:1.4;\}|.
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
    rv_html = rv_html && |.gg-selection fieldset\{margin:.75rem 0;padding:.75rem;\}|.
    rv_html = rv_html && |.gg-field\{display:flex;gap:.5rem;align-items:center;margin:.35rem 0;\}|.
    rv_html = rv_html && |.gg-field label\{min-width:12rem;\}|.
    rv_html = rv_html && |.gg-dynpro\{position:relative;min-height:12rem;\}|.
    rv_html = rv_html && |.gg-dynpro-control\{position:absolute;box-sizing:border-box;\}|.
    rv_html = rv_html && |.gg-visually-hidden\{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);\}|.
    rv_html = rv_html && |</style></head><body>|.
    rv_html = rv_html && |<div data-session-id="{ escape_attribute( iv_session_id ) }" data-page-id="{ escape_attribute( iv_page_id ) }" data-page-kind="{ escape_attribute( iv_kind ) }">|.
    rv_html = rv_html && |<main>{ iv_body }</main></div></body></html>|.
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
