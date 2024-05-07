CLASS cl_alv_variant DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS delete_variants
      IMPORTING
        it_variants    TYPE any
      RETURNING
        VALUE(boolean) TYPE abap_bool.

ENDCLASS.

CLASS cl_alv_variant IMPLEMENTATION.

  METHOD delete_variants.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.