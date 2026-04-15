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

ENDCLASS.

CLASS cl_dd_area IMPLEMENTATION.
  METHOD add_text.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.