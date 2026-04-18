CLASS cl_dd_area DEFINITION PUBLIC.
  PUBLIC SECTION.

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