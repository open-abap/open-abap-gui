CLASS cl_dd_document DEFINITION PUBLIC.
  PUBLIC SECTION.

    CONSTANTS heading TYPE c LENGTH 50 VALUE 'HEADING'.
    CONSTANTS list_heading_int TYPE c LENGTH 50 VALUE 'LIST_HEADING_INT'.
    CONSTANTS list_normal TYPE c LENGTH 50 VALUE 'LIST_NORMAL'.
    CONSTANTS medium TYPE c LENGTH 50 VALUE 'MEDIUM'.
    CONSTANTS small TYPE c LENGTH 50 VALUE 'SMALL'.

    METHODS add_picture
      IMPORTING
        picture_id TYPE any.

    METHODS display_document
      IMPORTING
        reuse_control      TYPE abap_bool OPTIONAL
        reuse_registration TYPE abap_bool OPTIONAL
        container          TYPE clike OPTIONAL
        parent             TYPE REF TO cl_gui_container OPTIONAL.

    METHODS set_document_background
      IMPORTING
        picture_id TYPE any OPTIONAL.

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

    METHODS new_line
      IMPORTING
        repeat TYPE i OPTIONAL.

    METHODS add_icon
      IMPORTING
      sap_icon TYPE any.

    METHODS merge_document.

    METHODS add_gap.

    METHODS initialize_document
      IMPORTING
        background_color TYPE i OPTIONAL.

ENDCLASS.

CLASS cl_dd_document IMPLEMENTATION.
  METHOD initialize_document.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD merge_document.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD display_document.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_picture.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_gap.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_icon.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD new_line.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_document_background.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_text.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.