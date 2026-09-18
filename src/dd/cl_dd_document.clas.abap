CLASS cl_dd_document DEFINITION PUBLIC INHERITING FROM cl_dd_area.
  PUBLIC SECTION.

    DATA html_control TYPE REF TO cl_gui_html_viewer.

    METHODS constructor
      IMPORTING
        style            TYPE sdydo_attribute OPTIONAL
        background_color TYPE i OPTIONAL
        bds_stylesheet   TYPE any OPTIONAL
        no_margins       TYPE abap_bool OPTIONAL.

    METHODS add_picture
      IMPORTING
        picture_id TYPE any
        width      TYPE any OPTIONAL.

    METHODS display_document
      IMPORTING
        reuse_control      TYPE abap_bool OPTIONAL
        reuse_registration TYPE abap_bool OPTIONAL
        container          TYPE clike OPTIONAL
        parent             TYPE REF TO cl_gui_container OPTIONAL.

    METHODS set_document_background
      IMPORTING
        picture_id TYPE any OPTIONAL.

    METHODS merge_document.

    METHODS initialize_document
      IMPORTING
        background_color TYPE i OPTIONAL.

    METHODS vertical_split
      IMPORTING
        split_area  TYPE REF TO cl_dd_area
        split_width TYPE clike OPTIONAL
      EXPORTING
        right_area  TYPE REF TO cl_dd_area.

    METHODS print_document
      IMPORTING
        reuse_control TYPE sdydo_flag OPTIONAL
      EXCEPTIONS
        html_print_error.

  PRIVATE SECTION.
    DATA mv_right_area TYPE REF TO cl_dd_area.
    DATA mv_document_html TYPE string.

    METHODS render_document_styles
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.

CLASS cl_dd_document IMPLEMENTATION.
  METHOD constructor.
    initialize_document( background_color = background_color ).
  ENDMETHOD.

  METHOD print_document.
    cl_gui_control=>set_external_html( mv_document_html ).
  ENDMETHOD.

  METHOD vertical_split.
    DATA lv_percent_text TYPE string.
    DATA lv_percent TYPE i VALUE 72.
    DATA lv_remaining_percent TYPE i.

    IF split_area IS BOUND AND split_area <> me.
      mv_right_area = split_area.
    ELSE.
      mv_right_area = NEW cl_dd_area( ).
    ENDIF.
    right_area = mv_right_area.
    IF split_width IS SUPPLIED.
      lv_percent_text = CONV string( split_width ).
      REPLACE ALL OCCURRENCES OF '%' IN lv_percent_text WITH ``.
      CONDENSE lv_percent_text NO-GAPS.
      IF lv_percent_text IS NOT INITIAL AND lv_percent_text CO '0123456789'.
        lv_percent = CONV i( lv_percent_text ).
      ENDIF.
    ENDIF.
    IF lv_percent < 30 OR lv_percent > 90.
      lv_percent = 72.
    ENDIF.
    lv_remaining_percent = 100 - lv_percent.
    html_content = html_content && |<div class="gg-dd-split" style="grid-template-columns:minmax(0,{ lv_percent }fr) minmax(0,{ lv_remaining_percent }fr)"><div class="gg-dd-main">|.
  ENDMETHOD.

  METHOD merge_document.
    DATA lv_raw_html TYPE string.

    finish_open_table( ).
    mv_document_html = html_content.
    IF mv_form_open = abap_true.
      mv_document_html = mv_document_html && '</form>'.
    ENDIF.
    IF mv_right_area IS BOUND.
      mv_document_html = mv_document_html && |</div><aside class="gg-dd-right-area">{ mv_right_area->get_html_content( ) }</aside></div>|.
    ENDIF.
    mv_document_html = mv_document_html && '</div></section>'.
    lv_raw_html = html_content.
    html_content = mv_document_html.
    fill_html_table( ).
    html_content = lv_raw_html.
  ENDMETHOD.

  METHOD initialize_document.
    CLEAR html_content.
    CLEAR: mv_right_area, mv_document_html, mv_table_area, mv_form_open.
    html_content = |<section class="gg-dd-document" aria-label="Dynamic document" data-background="{ background_color }">{ zcl_gg_host_icons=>sprite( ) }<style>{ render_document_styles( ) }</style><div class="gg-dd-content">|.
  ENDMETHOD.

  METHOD display_document.
    DATA lt_html TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    merge_document( ).
    IF parent IS BOUND AND html_control IS NOT BOUND.
      html_control = NEW cl_gui_html_viewer( parent = parent ).
    ENDIF.
    IF html_control IS BOUND.
      APPEND mv_document_html TO lt_html.
      html_control->load_data( CHANGING data_table = lt_html ).
    ELSE.
      cl_gui_control=>set_external_html( mv_document_html ).
    ENDIF.
  ENDMETHOD.

  METHOD render_document_styles.
    result = |body\{margin:0;background:#eef3f7;color:#172b3a;font:14px Arial,sans-serif;\}|.
    result = result && |.gg-dd-document\{box-sizing:border-box;min-height:100%;margin:0;padding:24px 20px;background:#edf4f8;color:#172b3a;font:14px Arial,sans-serif;\}|.
    result = result && |.gg-dd-content\{min-width:0;\}|.
    result = result && |.gg-dd-split\{display:grid;gap:12px;align-items:start;min-width:0;\}|.
    result = result && |.gg-dd-main\{min-width:0;\}|.
    result = result && |.gg-dd-right-area\{min-width:0;padding-top:3px;color:#172b3a;font-size:14px;line-height:1.4;\}|.
    result = result && |.gg-dd-text\{font:inherit;text-decoration:none;\}|.
    result = result && |.gg-dd-text[data-sap-style="HEADING"]\{display:inline-block;margin:2px 0 3px;font-size:23px;font-weight:700;line-height:1.2;color:#111;\}|.
    result = result && |.gg-dd-text[data-sap-style="KEY"]\{color:#075e98;background:#e3f0f4;\}|.
    result = result && |.gg-dd-text[data-sap-style="GROUP_HEADING"]\{font-weight:700;color:#173c5e;\}|.
    result = result && |.gg-dd-text[data-sap-emphasis="STRONG"]\{font-weight:700;\}|.
    result = result && |.gg-dd-text[data-sap-color="LIST_POSITIVE"]\{color:#174c25;background:#c6f0be;\}|.
    result = result && |.gg-dd-text[data-sap-color="LIST_HEADING"]\{color:#164b82;background:#d9e9f6;\}|.
    result = result && |.gg-dd-text[data-sap-fontsize="SMALL"]\{font-size:11px;\}|.
    result = result && |.gg-dd-text[data-sap-fontsize="MEDIUM"]\{font-size:14px;\}|.
    result = result && |.gg-dd-text[data-sap-fontsize="LARGE"]\{font-size:18px;\}|.
    result = result && |.gg-dd-text[data-sap-fontstyle="SERIF"]\{font-family:Georgia,serif;\}|.
    result = result && |.gg-dd-text[data-sap-fontstyle="SANS_SERIF"]\{font-family:Arial,sans-serif;\}|.
    result = result && |.gg-dd-link\{color:#0066b3;text-decoration:underline;\}|.
    result = result && |.gg-dd-underline\{height:0;margin:8px 0 10px;border:0;border-top:1px solid #bccbd6;\}|.
    result = result && |.gg-dd-table\{width:100%;margin:6px 0 8px;border:2px solid #405680;border-collapse:collapse;table-layout:fixed;color:#172b3a;font:14px Arial,sans-serif;\}|.
    result = result && |.gg-dd-table th,.gg-dd-table td\{height:27px;padding:4px 6px;border:1px solid #91a6c0;text-align:left;vertical-align:middle;overflow-wrap:anywhere;\}|.
    result = result && |.gg-dd-table th\{background:#647fb8;color:#fff;font-weight:500;\}|.
    result = result && |.gg-dd-table td\{background:#f7fafc;\}|.
    result = result && |.gg-dd-table tr[data-sap-color="LIST_POSITIVE"] td\{background:#c8f1bd;color:#174b24;\}|.
    result = result && |.gg-dd-table .gg-dd-icon\{display:inline-flex;align-items:center;justify-content:center;color:#176d35;\}|.
    result = result && |.gg-dd-form\{display:flex;flex-wrap:wrap;align-items:center;gap:7px 8px;margin:6px 0 0;color:#172b3a;\}|.
    result = result && |.gg-dd-form>.gg-dd-text\{flex:0 0 100%;font-weight:700;\}|.
    result = result && |.gg-dd-form label\{display:inline-flex;align-items:center;gap:5px;\}|.
    result = result && |.gg-dd-form input,.gg-dd-form select\{box-sizing:border-box;height:27px;border:1px solid #8fa5ba;background:#fff;color:#172b3a;font:inherit;\}|.
    result = result && |.gg-dd-form button\{min-height:27px;padding:3px 8px;border:1px solid #8b9daf;background:linear-gradient(#fff,#e6edf3);color:#173d60;font:inherit;\}|.
    result = result && |.gg-dd-icon\{display:inline-flex;align-items:center;vertical-align:middle;color:#176c36;\}|.
    result = result && |.gg-dd-icon .wb-icon\{width:18px;height:18px;\}|.
    result = result && |.wb-icon-sprite\{position:absolute;width:0;height:0;overflow:hidden;\}|.
    result = result && |.wb-icon\{display:inline-block;width:1em;height:1em;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;vertical-align:middle;\}|.
  ENDMETHOD.

  METHOD add_picture.
    html_content = html_content && |<img class="gg-dd-picture" src="{ cl_gui_control=>escape_html( CONV string( picture_id ) ) }" width="{ width }" alt="Dynamic document picture">|.
  ENDMETHOD.

  METHOD set_document_background.
    html_content = html_content && |<div class="gg-dd-background" data-picture="{ cl_gui_control=>escape_html( CONV string( picture_id ) ) }"></div>|.
  ENDMETHOD.

ENDCLASS.
