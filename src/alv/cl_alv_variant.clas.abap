CLASS cl_alv_variant DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        it_outtab       TYPE REF TO data OPTIONAL
        it_fieldcatalog TYPE lvc_t_fcat OPTIONAL
        is_variant      TYPE disvariant OPTIONAL
        is_layout       TYPE lvc_s_layo OPTIONAL.

    METHODS delete_variants
      IMPORTING
        it_variants    TYPE any
      RETURNING
        VALUE(boolean) TYPE abap_bool.

    METHODS get_variant_info_from_db
      IMPORTING
        is_variant  TYPE disvariant
        it_def_fcat TYPE lvc_t_fcat OPTIONAL
      EXPORTING
        et_fcat     TYPE lvc_t_fcat.

ENDCLASS.

CLASS cl_alv_variant IMPLEMENTATION.
  METHOD constructor.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_variant_info_from_db.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD delete_variants.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.