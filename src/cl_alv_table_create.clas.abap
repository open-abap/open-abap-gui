CLASS cl_alv_table_create DEFINITION PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS create_dynamic_table
      IMPORTING
        i_style_table    TYPE char1 OPTIONAL
        it_fieldcatalog  TYPE any
        i_length_in_byte TYPE boolean OPTIONAL
      EXPORTING
        ep_table         TYPE REF TO data
        e_style_fname    TYPE string.
ENDCLASS.

CLASS cl_alv_table_create IMPLEMENTATION.

  METHOD create_dynamic_table.
    ASSERT 1 = 2.
  ENDMETHOD.

ENDCLASS.