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
    METHODS finish_table.

    DATA column_count TYPE i.

  PRIVATE SECTION.
    DATA mv_row_open TYPE abap_bool.
    DATA mv_header_open TYPE abap_bool.
    DATA mv_table_closed TYPE abap_bool.
    DATA mv_next_row_style TYPE string.
    DATA mv_next_row_color TYPE string.
    DATA mv_next_row_fontsize TYPE string.
    DATA mv_next_row_fontstyle TYPE string.
    DATA mv_next_row_emphasis TYPE string.

    METHODS append_fragment
      IMPORTING
        iv_fragment TYPE string.

    METHODS open_row.

ENDCLASS.

CLASS cl_dd_table_area IMPLEMENTATION.

  METHOD add_heading.
    IF mv_row_open = abap_false.
      mv_header_open = abap_true.
      open_row( ).
    ENDIF.
    append_fragment( |<th scope="col">{ cl_gui_control=>escape_html( CONV string( text ) ) }</th>| ).
  ENDMETHOD.

  METHOD new_row.
    IF mv_row_open = abap_true.
      append_fragment( '</tr>' ).
    ENDIF.
    mv_row_open = abap_false.
    mv_header_open = abap_false.
    mv_next_row_style = CONV string( sap_style ).
    mv_next_row_color = CONV string( sap_color ).
    mv_next_row_fontsize = CONV string( sap_fontsize ).
    mv_next_row_fontstyle = CONV string( sap_fontstyle ).
    mv_next_row_emphasis = CONV string( sap_emphasis ).
    CONDENSE mv_next_row_style NO-GAPS.
    CONDENSE mv_next_row_color NO-GAPS.
    CONDENSE mv_next_row_fontsize NO-GAPS.
    CONDENSE mv_next_row_fontstyle NO-GAPS.
    CONDENSE mv_next_row_emphasis NO-GAPS.
  ENDMETHOD.

  METHOD add_text.
    DATA lv_fragment TYPE string.
    DATA lv_cell_tag TYPE string.

    IF mv_row_open = abap_false.
      open_row( ).
    ENDIF.
    lv_cell_tag = COND string( WHEN mv_header_open = abap_true THEN 'th' ELSE 'td' ).
    IF text_table IS SUPPLIED.
      LOOP AT text_table INTO DATA(lv_line).
        lv_fragment = lv_fragment && render_text_html(
          text          = lv_line
          sap_style     = sap_style
          sap_color     = sap_color
          sap_fontsize  = sap_fontsize
          sap_fontstyle = sap_fontstyle
          sap_emphasis  = sap_emphasis
          style_class   = style_class
          a11y_tooltip  = a11y_tooltip ) && `<br>`.
      ENDLOOP.
    ELSE.
      lv_fragment = render_text_html(
        text          = text
        sap_style     = sap_style
        sap_color     = sap_color
        sap_fontsize  = sap_fontsize
        sap_fontstyle = sap_fontstyle
        sap_emphasis  = sap_emphasis
        style_class   = style_class
        a11y_tooltip  = a11y_tooltip ).
    ENDIF.
    append_fragment( |<{ lv_cell_tag }>{ lv_fragment }</{ lv_cell_tag }>| ).
  ENDMETHOD.

  METHOD add_icon.
    DATA lv_fragment TYPE string.
    DATA lv_cell_tag TYPE string.

    IF mv_row_open = abap_false.
      open_row( ).
    ENDIF.
    lv_cell_tag = COND string( WHEN mv_header_open = abap_true THEN 'th' ELSE 'td' ).
    lv_fragment = |<{ lv_cell_tag }>{ render_icon_html(
      sap_icon         = sap_icon
      alternative_text = alternative_text ) }</{ lv_cell_tag }>|.
    append_fragment( lv_fragment ).
  ENDMETHOD.

  METHOD append_fragment.
    html_content = html_content && iv_fragment.
    IF parent_area IS BOUND.
      parent_area->html_content = parent_area->html_content && iv_fragment.
    ENDIF.
  ENDMETHOD.

  METHOD open_row.
    DATA lv_attributes TYPE string.
    DATA lv_row_class TYPE string.

    IF mv_header_open = abap_true.
      lv_row_class = 'gg-dd-heading-row'.
    ELSE.
      lv_row_class = 'gg-dd-data-row'.
      IF mv_next_row_style IS NOT INITIAL.
        lv_attributes = lv_attributes && | data-sap-style="{ cl_gui_control=>escape_html( mv_next_row_style ) }"|.
      ENDIF.
      IF mv_next_row_color IS NOT INITIAL.
        lv_attributes = lv_attributes && | data-sap-color="{ cl_gui_control=>escape_html( mv_next_row_color ) }"|.
      ENDIF.
      IF mv_next_row_fontsize IS NOT INITIAL.
        lv_attributes = lv_attributes && | data-sap-fontsize="{ cl_gui_control=>escape_html( mv_next_row_fontsize ) }"|.
      ENDIF.
      IF mv_next_row_fontstyle IS NOT INITIAL.
        lv_attributes = lv_attributes && | data-sap-fontstyle="{ cl_gui_control=>escape_html( mv_next_row_fontstyle ) }"|.
      ENDIF.
      IF mv_next_row_emphasis IS NOT INITIAL.
        lv_attributes = lv_attributes && | data-sap-emphasis="{ cl_gui_control=>escape_html( mv_next_row_emphasis ) }"|.
      ENDIF.
    ENDIF.
    append_fragment( |<tr class="{ lv_row_class }"{ lv_attributes }>| ).
    mv_row_open = abap_true.
    CLEAR: mv_next_row_style, mv_next_row_color, mv_next_row_fontsize,
      mv_next_row_fontstyle, mv_next_row_emphasis.
  ENDMETHOD.

  METHOD finish_table.
    IF mv_table_closed = abap_true.
      RETURN.
    ENDIF.
    IF mv_row_open = abap_true.
      append_fragment( '</tr>' ).
      mv_row_open = abap_false.
    ENDIF.
    append_fragment( '</tbody></table>' ).
    mv_table_closed = abap_true.
  ENDMETHOD.

ENDCLASS.
