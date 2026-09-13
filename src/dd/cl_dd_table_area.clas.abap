CLASS cl_dd_table_area DEFINITION PUBLIC INHERITING FROM cl_dd_area.
  PUBLIC SECTION.

    DATA parent_area TYPE REF TO cl_dd_area.

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

ENDCLASS.

CLASS cl_dd_table_area IMPLEMENTATION.

  METHOD add_heading.
    DATA lv_start TYPE i.
    DATA lv_fragment TYPE string.
    lv_start = strlen( html_content ).
    html_content = html_content && |<th>{ cl_gui_control=>escape_html( CONV string( text ) ) }</th>|.
    IF parent_area IS BOUND.
      lv_fragment = substring(
        val = html_content
        off = lv_start ).
      parent_area->html_content = parent_area->html_content && lv_fragment.
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

ENDCLASS.
