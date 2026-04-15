CLASS cl_dd_table_element DEFINITION PUBLIC.
  PUBLIC SECTION.

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

ENDCLASS.

CLASS cl_dd_table_element IMPLEMENTATION.

  METHOD set_column_style.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.