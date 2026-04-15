CLASS cl_dd_table_area DEFINITION PUBLIC INHERITING FROM cl_dd_area.
  PUBLIC SECTION.

    METHODS new_row
      IMPORTING
        sap_style     TYPE any OPTIONAL
        sap_color     TYPE any OPTIONAL
        sap_fontsize  TYPE any OPTIONAL
        sap_fontstyle TYPE any OPTIONAL
        sap_emphasis  TYPE any OPTIONAL.

ENDCLASS.

CLASS cl_dd_table_area IMPLEMENTATION.

  METHOD new_row.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.