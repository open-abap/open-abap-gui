CLASS cl_dd_table_area DEFINITION PUBLIC INHERITING FROM cl_dd_area.
  PUBLIC SECTION.

    METHODS new_row
      IMPORTING
        sap_style     TYPE any OPTIONAL
        sap_color     TYPE any OPTIONAL
        sap_fontsize  TYPE any OPTIONAL
        sap_fontstyle TYPE any OPTIONAL
        sap_emphasis  TYPE any OPTIONAL.

    METHODS add_heading
      IMPORTING
        text TYPE clike.

    METHODS add_text REDEFINITION.
    METHODS add_icon REDEFINITION.

    DATA column_count TYPE i.

  PRIVATE SECTION.
    DATA mv_heading_count TYPE i.

ENDCLASS.

CLASS cl_dd_table_area IMPLEMENTATION.

  METHOD add_heading.
    DATA lv_start TYPE i.
    DATA lv_fragment TYPE string.
    IF mv_heading_count = 0.
      html_content = html_content && '<tr>'.
      IF parent_area IS BOUND.
        parent_area->html_content = parent_area->html_content && '<tr>'.
      ENDIF.
    ENDIF.
    lv_start = strlen( html_content ).
    html_content = html_content && |<th>{ cl_gui_control=>escape_html( CONV string( text ) ) }</th>|.
    IF parent_area IS BOUND.
      lv_fragment = substring(
        val = html_content
        off = lv_start ).
      parent_area->html_content = parent_area->html_content && lv_fragment.
    ENDIF.
    ADD 1 TO mv_heading_count.
    IF column_count > 0 AND mv_heading_count >= column_count.
      html_content = html_content && '</tr>'.
      IF parent_area IS BOUND.
        parent_area->html_content = parent_area->html_content && '</tr>'.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD new_row.
    DATA lv_start TYPE i.
    DATA lv_fragment TYPE string.
    lv_start = strlen( html_content ).
    html_content = html_content && `<tr>`.
    IF parent_area IS BOUND.
      lv_fragment = substring(
        val = html_content
        off = lv_start ).
      parent_area->html_content = parent_area->html_content && lv_fragment.
    ENDIF.
  ENDMETHOD.

  METHOD add_text.
    DATA lv_text TYPE string.
    DATA lv_fragment TYPE string.
    IF text_table IS SUPPLIED.
      LOOP AT text_table INTO DATA(lv_line).
        lv_text = lv_text && CONV string( lv_line ) && `<br>`.
      ENDLOOP.
    ELSE.
      lv_text = CONV string( text ).
    ENDIF.
    lv_fragment = |<td>{ cl_gui_control=>escape_html( lv_text ) }</td>|.
    html_content = html_content && lv_fragment.
    IF parent_area IS BOUND.
      parent_area->html_content = parent_area->html_content && lv_fragment.
    ENDIF.
  ENDMETHOD.

  METHOD add_icon.
    DATA lv_fragment TYPE string.
    lv_fragment = |<td><span class="gg-dd-icon" role="img" aria-label="{ cl_gui_control=>escape_html( alternative_text ) }" data-icon="{ cl_gui_control=>escape_html( CONV string( sap_icon ) ) }">{ cl_gui_control=>escape_html( CONV string( sap_icon ) ) }</span></td>|.
    html_content = html_content && lv_fragment.
    IF parent_area IS BOUND.
      parent_area->html_content = parent_area->html_content && lv_fragment.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
