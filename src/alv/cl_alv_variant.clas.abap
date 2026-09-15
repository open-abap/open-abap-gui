CLASS cl_alv_variant DEFINITION PUBLIC.
  PUBLIC SECTION.

    DATA ms_layout TYPE lvc_s_layo.
    DATA mt_fieldcatalog TYPE lvc_t_fcat.
    DATA mt_sort TYPE lvc_t_sort.
    DATA mt_filter TYPE lvc_t_filt.

    METHODS constructor
      IMPORTING
        it_outtab       TYPE REF TO data OPTIONAL
        it_fieldcatalog TYPE lvc_t_fcat OPTIONAL
        is_variant      TYPE disvariant OPTIONAL
        is_layout       TYPE lvc_s_layo OPTIONAL.

    METHODS delete_variants
      IMPORTING
        it_variants    TYPE ltvariants
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
    IF it_fieldcatalog IS SUPPLIED.
      mt_fieldcatalog = it_fieldcatalog.
    ENDIF.
    IF is_layout IS SUPPLIED.
      ms_layout = is_layout.
    ENDIF.
  ENDMETHOD.

  METHOD get_variant_info_from_db.
    et_fcat = mt_fieldcatalog.
    IF et_fcat IS INITIAL AND it_def_fcat IS SUPPLIED.
      et_fcat = it_def_fcat.
    ENDIF.
  ENDMETHOD.

  METHOD delete_variants.
    boolean = abap_true.
  ENDMETHOD.

ENDCLASS.
