CLASS cl_alv_table_create DEFINITION PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS create_dynamic_table
      IMPORTING
        i_style_table    TYPE char1 OPTIONAL
        it_fieldcatalog  TYPE any
        i_length_in_byte TYPE abap_bool OPTIONAL
      EXPORTING
        ep_table         TYPE REF TO data
        e_style_fname    TYPE lvc_fname.
ENDCLASS.

CLASS cl_alv_table_create IMPLEMENTATION.

  METHOD create_dynamic_table.
    CLEAR ep_table.
    CLEAR e_style_fname.
    "The browser runtime cannot manufacture an anonymous DDIC structure, but
    "it can still return a usable table reference and preserve the style
    "component contract for callers that inspect the generated metadata.
    CREATE DATA ep_table TYPE STANDARD TABLE OF string.
    IF i_style_table = 'X'.
      e_style_fname = 'STYLE'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
