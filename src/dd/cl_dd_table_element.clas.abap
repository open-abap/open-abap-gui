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

  PRIVATE SECTION.
    DATA html_content TYPE string.

ENDCLASS.

CLASS cl_dd_table_element IMPLEMENTATION.
  METHOD set_row_style.
    html_content = html_content && |<tr data-row="{ row_no }" class="{ CONV string( sap_style ) }">|.
  ENDMETHOD.

  METHOD new_row.
    row_count = row_count + 1.
    html_content = html_content && `<tr>`.
  ENDMETHOD.

  METHOD add_column.
    column = NEW cl_dd_area( ).
    column->html_content = |<td class="{ CONV string( style_class ) }">{ cl_gui_control=>escape_html( CONV string( heading ) ) }</td>|.
    APPEND column TO table_of_columns.
  ENDMETHOD.

  METHOD set_column_style.
    html_content = html_content && |<!-- column { col_no } style { CONV string( sap_style ) } -->|.
  ENDMETHOD.

ENDCLASS.
