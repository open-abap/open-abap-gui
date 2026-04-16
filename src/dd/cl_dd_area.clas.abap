CLASS cl_dd_area DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS add_text
      IMPORTING
        text          TYPE any OPTIONAL
        text_table    TYPE any OPTIONAL
        fix_lines     TYPE any OPTIONAL
        sap_style     TYPE any OPTIONAL
        sap_color     TYPE any OPTIONAL
        sap_fontsize  TYPE any OPTIONAL
        sap_fontstyle TYPE any OPTIONAL
        sap_emphasis  TYPE any OPTIONAL
        style_class   TYPE any OPTIONAL
        a11y_tooltip  TYPE string OPTIONAL
      CHANGING
        document      TYPE REF TO cl_dd_document OPTIONAL.

    METHODS html_insert
      IMPORTING
        contents TYPE string
      CHANGING
        position TYPE i.

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

ENDCLASS.

CLASS cl_dd_area IMPLEMENTATION.
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