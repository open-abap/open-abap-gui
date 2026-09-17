CLASS cl_dd_area DEFINITION PUBLIC FRIENDS cl_dd_form_area cl_dd_table_area cl_dd_table_element.
  PUBLIC SECTION.

    CONSTANTS col_background_level2 TYPE i VALUE 35.
    CONSTANTS col_textarea TYPE i VALUE 31.
    CONSTANTS cursor TYPE sdydo_attribute VALUE '<!%_CURSOR!>'.
    CONSTANTS emphasis TYPE sdydo_attribute VALUE 'EMPHASIS'.
    CONSTANTS heading TYPE sdydo_attribute VALUE 'HEADING'.
    CONSTANTS key TYPE sdydo_attribute VALUE 'KEY'.
    CONSTANTS large TYPE sdydo_attribute VALUE 'LARGE'.
    CONSTANTS list_background TYPE sdydo_attribute VALUE 'LIST_BACKGROUND'.
    CONSTANTS list_background_int TYPE sdydo_attribute VALUE 'LIST_BACKGROUND_INT'.
    CONSTANTS list_group TYPE sdydo_attribute VALUE 'LIST_GROUP'.
    CONSTANTS list_heading TYPE sdydo_attribute VALUE 'LIST_HEADING'.
    CONSTANTS list_heading_int TYPE sdydo_attribute VALUE 'LIST_HEADING_INT'.
    CONSTANTS list_heading_inv TYPE sdydo_attribute VALUE 'LIST_HEADING_INV'.
    CONSTANTS list_key TYPE sdydo_attribute VALUE 'LIST_KEY'.
    CONSTANTS list_negative TYPE sdydo_attribute VALUE 'LIST_NEGATIVE'.
    CONSTANTS list_negative_int TYPE sdydo_attribute VALUE 'LIST_NEGATIVE_INT'.
    CONSTANTS list_negative_inv TYPE sdydo_attribute VALUE 'LIST_NEGATIVE_INV'.
    CONSTANTS list_normal TYPE sdydo_attribute VALUE 'LIST_NORMAL'.
    CONSTANTS list_normal_int TYPE sdydo_attribute VALUE 'LIST_NORMAL_INT'.
    CONSTANTS list_positive TYPE sdydo_attribute VALUE 'LIST_POSITIVE'.
    CONSTANTS list_positive_int TYPE sdydo_attribute VALUE 'LIST_POSITIVE_INT'.
    CONSTANTS list_total_int TYPE sdydo_attribute VALUE 'LIST_TOTAL_INT'.
    CONSTANTS medium TYPE c LENGTH 50 VALUE 'MEDIUM'.
    CONSTANTS sans_serif TYPE sdydo_attribute VALUE 'SANS_SERIF'.
    CONSTANTS serif TYPE sdydo_attribute VALUE 'SERIF'.
    CONSTANTS small TYPE c LENGTH 50 VALUE 'SMALL'.
    CONSTANTS standard TYPE sdydo_attribute VALUE 'STANDARD'.
    CONSTANTS strong TYPE sdydo_attribute VALUE 'STRONG'.
    CONSTANTS success TYPE sdydo_attribute VALUE 'SUCCESS'.
    CONSTANTS table_heading TYPE sdydo_attribute VALUE 'TABLE_HEADING'.
    CONSTANTS warning TYPE sdydo_attribute VALUE 'WARNING'.
    CONSTANTS list_group_int TYPE sdydo_attribute VALUE 'LIST_GROUP_INT'.

    DATA html_table TYPE sdydo_html_table.
    CLASS-DATA act_gui_properties TYPE sdydo_act_gui_properties.

    METHODS get_html_content
      RETURNING
        VALUE(result) TYPE string.

    METHODS new_line
      IMPORTING
        repeat TYPE i OPTIONAL.

    METHODS html_insert
      IMPORTING
        contents TYPE string
      CHANGING
        position TYPE i.

    METHODS add_table
      IMPORTING
        no_of_columns               TYPE i
        with_heading                TYPE sdydo_flag OPTIONAL
        border                      TYPE sdydo_value DEFAULT '1'
        width                       TYPE sdydo_value OPTIONAL
        with_a11y_marks             TYPE sdydo_flag OPTIONAL
        a11y_label                  TYPE string OPTIONAL
        cell_background_transparent TYPE any OPTIONAL
      EXPORTING
        table                       TYPE REF TO cl_dd_table_element
        tablearea                   TYPE REF TO cl_dd_table_area
      EXCEPTIONS
        table_already_used.

    METHODS add_icon
      IMPORTING
        sap_icon         TYPE any
        sap_size         TYPE any OPTIONAL
        sap_style        TYPE any OPTIONAL
        sap_color        TYPE any OPTIONAL
        alternative_text TYPE string OPTIONAL
        tabindex         TYPE i OPTIONAL.

    METHODS underline.

    METHODS add_link
      IMPORTING
        url                    TYPE sdydo_text_element
        text                   TYPE sdydo_text_element
        name                   TYPE sdydo_element_name OPTIONAL
        tooltip                TYPE string OPTIONAL
        destination_in_doc_set TYPE string OPTIONAL
        destination_in_doc_pos TYPE string OPTIONAL
        tabindex               TYPE i OPTIONAL
        hotkey                 TYPE sdydo_c1 OPTIONAL
      EXPORTING
        link                   TYPE REF TO cl_dd_link_element.

    METHODS add_form
      EXPORTING
        formarea         TYPE REF TO cl_dd_form_area
        main_url         TYPE string
        alv_offline_info TYPE string.

    METHODS line_with_layout
      IMPORTING
        start            TYPE abap_bool OPTIONAL
        end              TYPE abap_bool OPTIONAL
        no_leading_break TYPE abap_bool DEFAULT abap_false.

    METHODS add_gap
      IMPORTING
        width      TYPE i OPTIONAL
        width_like TYPE any OPTIONAL.

    METHODS add_text
      IMPORTING
        text          TYPE sdydo_text_element OPTIONAL
        text_table    TYPE sdydo_text_table OPTIONAL
        fix_lines     TYPE sdydo_flag OPTIONAL
        sap_style     TYPE sdydo_attribute OPTIONAL
        sap_color     TYPE sdydo_attribute OPTIONAL
        sap_fontsize  TYPE sdydo_attribute OPTIONAL
        sap_fontstyle TYPE sdydo_attribute OPTIONAL
        sap_emphasis  TYPE sdydo_attribute OPTIONAL
        style_class   TYPE sdydo_attribute OPTIONAL
        a11y_tooltip  TYPE string OPTIONAL
      CHANGING
        document      TYPE REF TO cl_dd_document OPTIONAL.

  PROTECTED SECTION.
    DATA html_content TYPE string.
    DATA parent_area TYPE REF TO cl_dd_area.
    DATA mv_table_area TYPE REF TO cl_dd_table_area.
    DATA mv_form_open TYPE abap_bool.

    "! Publishes the accumulated markup through the public HTML_TABLE
    "! attribute, which is how callers read a document's rendered content.
    METHODS fill_html_table.

    METHODS escape_html
      IMPORTING
        value         TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS render_text_html
      IMPORTING
        text          TYPE sdydo_text_element OPTIONAL
        text_table    TYPE sdydo_text_table OPTIONAL
        sap_style     TYPE sdydo_attribute OPTIONAL
        sap_color     TYPE sdydo_attribute OPTIONAL
        sap_fontsize  TYPE sdydo_attribute OPTIONAL
        sap_fontstyle TYPE sdydo_attribute OPTIONAL
        sap_emphasis  TYPE sdydo_attribute OPTIONAL
        style_class   TYPE sdydo_attribute OPTIONAL
        a11y_tooltip  TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE string.

    METHODS render_icon_html
      IMPORTING
        sap_icon         TYPE any
        alternative_text TYPE string OPTIONAL
      RETURNING
        VALUE(result)    TYPE string.

ENDCLASS.

CLASS cl_dd_area IMPLEMENTATION.
  METHOD new_line.
    DATA lv_repeat TYPE i.
    lv_repeat = COND #( WHEN repeat IS SUPPLIED THEN repeat ELSE 1 ).
    DO lv_repeat TIMES.
      html_content = html_content && `<br>`.
    ENDDO.
  ENDMETHOD.

  METHOD add_table.
    DATA lv_start TYPE i.
    DATA lv_fragment TYPE string.
    CLEAR table.
    table = NEW cl_dd_table_element( ).
    tablearea = NEW cl_dd_table_area( ).
    tablearea->column_count = no_of_columns.
    tablearea->parent_area = me.
    mv_table_area = tablearea.
    lv_start = strlen( html_content ).
    html_content = html_content && |<table class="gg-dd-table" aria-label="{ escape_html( a11y_label ) }" border="{ border }"><tbody>|.
    lv_fragment = substring(
      val = html_content
      off = lv_start ).
    table->html_content = lv_fragment.
    tablearea->html_content = lv_fragment.
  ENDMETHOD.

  METHOD add_gap.
    html_content = html_content && |<span class="gg-dd-gap" style="display:inline-block;width:{ width }px" aria-hidden="true"></span>|.
  ENDMETHOD.

  METHOD line_with_layout.
    IF no_leading_break = abap_false.
      new_line( ).
    ENDIF.
    IF start = abap_true.
      html_content = html_content && `<div class="gg-dd-layout">`.
    ENDIF.
    IF end = abap_true.
      html_content = html_content && `</div>`.
    ENDIF.
  ENDMETHOD.

  METHOD add_form.
    IF mv_table_area IS BOUND.
      mv_table_area->finish_table( ).
    ENDIF.
    formarea = NEW cl_dd_form_area( ).
    formarea->parent_area = me.
    main_url = ``.
    alv_offline_info = 'Dynamic document form controls are handled in the browser session.'.
    html_content = html_content && `<form class="gg-dd-form">`.
    mv_form_open = abap_true.
  ENDMETHOD.

  METHOD add_link.
    link = NEW cl_dd_link_element( ).
    link->name = name.
    link->url = url.
    link->text = text.
    link->tooltip = tooltip.
    html_content = html_content && |<a class="gg-dd-link" href="{ escape_html( CONV string( url ) ) }" title="{ escape_html( tooltip ) }"{ COND string( WHEN name IS INITIAL THEN `` ELSE | id="{ escape_html( CONV string( name ) ) }"| ) }>{ escape_html( CONV string( text ) ) }</a>|.
  ENDMETHOD.

  METHOD underline.
    html_content = html_content && `<hr class="gg-dd-underline" aria-hidden="true">`.
  ENDMETHOD.

  METHOD add_icon.
    html_content = html_content && render_icon_html(
      sap_icon         = sap_icon
      alternative_text = alternative_text ).
  ENDMETHOD.

  METHOD html_insert.
    html_content = html_content && contents.
    position = strlen( html_content ).
  ENDMETHOD.

  METHOD add_text.
    DATA lv_start TYPE i.
    DATA lv_fragment TYPE string.
    lv_start = strlen( html_content ).
    IF text_table IS SUPPLIED.
      html_content = html_content && render_text_html(
        text_table    = text_table
        sap_style     = sap_style
        sap_color     = sap_color
        sap_fontsize  = sap_fontsize
        sap_fontstyle = sap_fontstyle
        sap_emphasis  = sap_emphasis
        style_class   = style_class
        a11y_tooltip  = a11y_tooltip ).
    ELSE.
      html_content = html_content && render_text_html(
        text          = text
        sap_style     = sap_style
        sap_color     = sap_color
        sap_fontsize  = sap_fontsize
        sap_fontstyle = sap_fontstyle
        sap_emphasis  = sap_emphasis
        style_class   = style_class
        a11y_tooltip  = a11y_tooltip ).
    ENDIF.
    lv_fragment = substring(
      val = html_content
      off = lv_start ).
    IF document IS BOUND AND document <> me.
      document->html_content = document->html_content && lv_fragment.
    ENDIF.
    IF parent_area IS BOUND.
      parent_area->html_content = parent_area->html_content && lv_fragment.
    ENDIF.
  ENDMETHOD.

  METHOD escape_html.
    result = cl_gui_control=>escape_html( value ).
  ENDMETHOD.

  METHOD render_text_html.
    DATA lv_text TYPE string.
    DATA lv_style TYPE string.
    DATA lv_color TYPE string.
    DATA lv_fontsize TYPE string.
    DATA lv_fontstyle TYPE string.
    DATA lv_emphasis TYPE string.

    IF text_table IS SUPPLIED.
      LOOP AT text_table INTO DATA(lv_line).
        lv_text = lv_text && escape_html( CONV string( lv_line ) ) && `<br>`.
      ENDLOOP.
    ELSE.
      lv_text = escape_html( CONV string( text ) ).
    ENDIF.
    lv_style = CONV string( sap_style ).
    lv_color = CONV string( sap_color ).
    lv_fontsize = CONV string( sap_fontsize ).
    lv_fontstyle = CONV string( sap_fontstyle ).
    lv_emphasis = CONV string( sap_emphasis ).
    CONDENSE lv_style NO-GAPS.
    CONDENSE lv_color NO-GAPS.
    CONDENSE lv_fontsize NO-GAPS.
    CONDENSE lv_fontstyle NO-GAPS.
    CONDENSE lv_emphasis NO-GAPS.
    result = |<span class="gg-dd-text { escape_html( CONV string( style_class ) ) }" data-sap-style="{ escape_html( lv_style ) }" data-sap-color="{ escape_html( lv_color ) }" data-sap-fontsize="{ escape_html( lv_fontsize ) }" data-sap-fontstyle="{ escape_html( lv_fontstyle ) }" data-sap-emphasis="{ escape_html( lv_emphasis ) }" title="{ escape_html( a11y_tooltip ) }">{ lv_text }</span>|.
  ENDMETHOD.

  METHOD render_icon_html.
    DATA lv_icon_name TYPE string.
    DATA lv_icon_label TYPE string.
    DATA lv_icon_token TYPE string.

    lv_icon_name = CONV string( sap_icon ).
    TRANSLATE lv_icon_name TO LOWER CASE.
    CONDENSE lv_icon_name NO-GAPS.
    lv_icon_label = alternative_text.
    CASE lv_icon_name.
      WHEN 'icon_display' OR 'icon_screen'.
        lv_icon_name = 'icon_display'.
        IF lv_icon_label IS INITIAL.
          lv_icon_label = 'Display'.
        ENDIF.
      WHEN 'icon_okay' OR 'icon_green_light' OR '@5b@'.
        lv_icon_name = 'circle-check'.
        IF lv_icon_label IS INITIAL.
          lv_icon_label = 'Success'.
        ENDIF.
      WHEN OTHERS.
        IF lv_icon_label IS INITIAL.
          lv_icon_label = lv_icon_name.
        ENDIF.
    ENDCASE.
    lv_icon_token = escape_html( CONV string( sap_icon ) ).
    result = |<span class="gg-dd-icon" role="img" aria-label="{ escape_html( lv_icon_label ) }" data-icon="{ lv_icon_token }">{ zcl_gg_host_icons=>icon( iv_name = lv_icon_name ) }</span>|.
  ENDMETHOD.

  METHOD get_html_content.
    result = html_content.
  ENDMETHOD.

  METHOD fill_html_table.
    DATA lv_offset TYPE i.
    DATA lv_length TYPE i.
    DATA lv_chunk TYPE i.
    CLEAR html_table.
    lv_length = strlen( html_content ).
    WHILE lv_offset < lv_length.
      lv_chunk = lv_length - lv_offset.
      IF lv_chunk > 255.
        lv_chunk = 255.
      ENDIF.
      APPEND VALUE #( line = substring( val = html_content
                                        off = lv_offset
                                        len = lv_chunk ) ) TO html_table.
      lv_offset = lv_offset + 255.
    ENDWHILE.
  ENDMETHOD.

ENDCLASS.
