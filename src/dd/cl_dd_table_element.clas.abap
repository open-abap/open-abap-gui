CLASS cl_dd_table_element DEFINITION PUBLIC FRIENDS cl_dd_area.
  PUBLIC SECTION.

    DATA table_of_columns TYPE sdydo_object_table.
    DATA row_count TYPE i.

    METHODS set_column_style
      IMPORTING
        col_no        TYPE i
        sap_style     TYPE any OPTIONAL
        sap_color     TYPE any OPTIONAL
        sap_fontsize  TYPE any OPTIONAL
        sap_fontstyle TYPE any OPTIONAL
        sap_emphasis  TYPE any OPTIONAL
        sap_align     TYPE any OPTIONAL
        sap_valign    TYPE any OPTIONAL
        sap_symbol    TYPE any OPTIONAL.

    METHODS set_row_style
      IMPORTING
        row_no        TYPE i
        sap_style     TYPE sdydo_attribute OPTIONAL
        sap_color     TYPE sdydo_attribute OPTIONAL
        sap_fontsize  TYPE sdydo_attribute OPTIONAL
        sap_fontstyle TYPE sdydo_attribute OPTIONAL
        sap_emphasis  TYPE sdydo_attribute OPTIONAL.

    METHODS add_column
      IMPORTING
        width       TYPE any OPTIONAL
        bg_color    TYPE any OPTIONAL
        heading     TYPE any OPTIONAL
        sap_style   TYPE any OPTIONAL
        style_class TYPE any OPTIONAL
      EXPORTING
        column      TYPE REF TO cl_dd_area.

    METHODS new_row
      IMPORTING
        sap_style     TYPE any OPTIONAL
        sap_color     TYPE any OPTIONAL
        sap_fontsize  TYPE any OPTIONAL
        sap_fontstyle TYPE any OPTIONAL
        sap_emphasis  TYPE any OPTIONAL.

    METHODS render_html
      RETURNING
        VALUE(result) TYPE string.

  PRIVATE SECTION.
    DATA html_content TYPE string.
    DATA mt_headings TYPE string_table.
    DATA mt_rows TYPE string_table.

ENDCLASS.

CLASS cl_dd_table_element IMPLEMENTATION.
  METHOD set_row_style.
    html_content = html_content && |<tr data-row="{ row_no }" class="{ CONV string( sap_style ) }">|.
  ENDMETHOD.

  METHOD new_row.
    IF table_of_columns IS NOT INITIAL.
      DATA(lv_row) = `<tr>`.
      LOOP AT table_of_columns INTO DATA(lo_column).
        DATA(lo_area) = CAST cl_dd_area( lo_column ).
        lv_row = lv_row && |<td>{ lo_area->html_content }</td>|.
        CLEAR lo_area->html_content.
      ENDLOOP.
      APPEND lv_row && `</tr>` TO mt_rows.
    ENDIF.
    row_count = row_count + 1.
    html_content = html_content && `<tr>`.
  ENDMETHOD.

  METHOD add_column.
    column = NEW cl_dd_area( ).
    APPEND zcl_gg_gui_runtime=>escape_html( CONV string( heading ) ) TO mt_headings.
    APPEND column TO table_of_columns.
  ENDMETHOD.

  METHOD set_column_style.
    html_content = html_content && |<!-- column { col_no } style { CONV string( sap_style ) } -->|.
  ENDMETHOD.

  METHOD render_html.
    IF table_of_columns IS INITIAL.
      RETURN.
    ENDIF.
    result = `<tr class="gg-dd-heading-row">`.
    LOOP AT mt_headings INTO DATA(lv_heading).
      result = result && |<th scope="col">{ lv_heading }</th>|.
    ENDLOOP.
    result = result && `</tr>` && concat_lines_of( mt_rows ).
    DATA(lv_row) = `<tr>`.
    DATA(lv_content) = abap_false.
    LOOP AT table_of_columns INTO DATA(lo_column).
      DATA(lo_area) = CAST cl_dd_area( lo_column ).
      lv_content = xsdbool( lv_content = abap_true OR lo_area->html_content IS NOT INITIAL ).
      lv_row = lv_row && |<td>{ lo_area->html_content }</td>|.
    ENDLOOP.
    IF lv_content = abap_true.
      result = result && lv_row && `</tr>`.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
