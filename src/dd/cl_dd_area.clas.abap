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

    "! Publishes the accumulated markup through the public HTML_TABLE
    "! attribute, which is how callers read a document's rendered content.
    METHODS fill_html_table.

    METHODS escape_html
      IMPORTING
        value         TYPE string
      RETURNING
        VALUE(result) TYPE string.

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
    tablearea->parent_area = me.
    lv_start = strlen( html_content ).
    html_content = html_content && |<table class="gg-dd-table" aria-label="{ escape_html( a11y_label ) }" border="{ border }"><tbody>|.
    IF with_heading IS NOT INITIAL.
      html_content = html_content && |<tr><th colspan="{ no_of_columns }">Dynamic document table</th></tr>|.
    ENDIF.
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
    formarea = NEW cl_dd_form_area( ).
    formarea->parent_area = me.
    main_url = ``.
    alv_offline_info = 'Dynamic document form controls are handled in the browser session.'.
    html_content = html_content && `<form class="gg-dd-form">`.
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
    html_content = html_content && `<u>`.
  ENDMETHOD.

  METHOD add_icon.
    html_content = html_content && |<span class="gg-dd-icon" role="img" aria-label="{ escape_html( alternative_text ) }" data-icon="{ escape_html( CONV string( sap_icon ) ) }">{ escape_html( CONV string( sap_icon ) ) }</span>|.
  ENDMETHOD.

  METHOD html_insert.
    html_content = html_content && contents.
    position = strlen( html_content ).
  ENDMETHOD.

  METHOD add_text.
    DATA lv_text TYPE string.
    DATA lv_start TYPE i.
    DATA lv_fragment TYPE string.
    lv_start = strlen( html_content ).
    IF text_table IS SUPPLIED.
      LOOP AT text_table INTO DATA(lv_line).
        lv_text = lv_text && CONV string( lv_line ) && `<br>`.
      ENDLOOP.
    ELSE.
      lv_text = CONV string( text ).
    ENDIF.
    html_content = html_content && |<span class="gg-dd-text { escape_html( CONV string( style_class ) ) }" title="{ escape_html( a11y_tooltip ) }">{ escape_html( lv_text ) }</span>|.
    IF document IS BOUND AND document <> me.
      lv_fragment = substring(
        val = html_content
        off = lv_start ).
      document->html_content = document->html_content && lv_fragment.
    ENDIF.
  ENDMETHOD.

  METHOD escape_html.
    result = cl_gui_control=>escape_html( value ).
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
