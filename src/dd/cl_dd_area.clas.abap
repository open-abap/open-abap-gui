CLASS cl_dd_area DEFINITION PUBLIC.
  PUBLIC SECTION.

    CONSTANTS list_heading TYPE sdydo_attribute VALUE 'LIST_HEADING'.
    CONSTANTS list_heading_int TYPE sdydo_attribute VALUE 'LIST_HEADING_INT'.
    CONSTANTS list_heading_inv TYPE sdydo_attribute VALUE 'LIST_HEADING_INV'.
    CONSTANTS list_normal TYPE sdydo_attribute VALUE 'LIST_NORMAL'.
    CONSTANTS list_negative_inv TYPE sdydo_attribute VALUE 'LIST_NEGATIVE_INV'.
    CONSTANTS list_group TYPE sdydo_attribute VALUE 'LIST_GROUP'.
    CONSTANTS list_total_int TYPE sdydo_attribute VALUE 'LIST_TOTAL_INT'.

    CONSTANTS col_textarea TYPE i VALUE 31.

    CONSTANTS warning TYPE sdydo_attribute VALUE 'WARNING'.

    CONSTANTS heading TYPE sdydo_attribute VALUE 'HEADING'.

    CONSTANTS strong TYPE sdydo_attribute VALUE 'STRONG'.
    CONSTANTS large TYPE sdydo_attribute VALUE 'LARGE'.
    CONSTANTS medium TYPE c LENGTH 50 VALUE 'MEDIUM'.
    CONSTANTS small TYPE c LENGTH 50 VALUE 'SMALL'.

    CONSTANTS serif TYPE sdydo_attribute VALUE 'SERIF'.
    CONSTANTS sans_serif TYPE sdydo_attribute VALUE 'SANS_SERIF'.

    DATA html_table TYPE sdydo_html_table.

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

ENDCLASS.

CLASS cl_dd_area IMPLEMENTATION.
  METHOD add_table.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_gap.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD line_with_layout.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_form.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD underline.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_icon.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD html_insert.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_text.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.