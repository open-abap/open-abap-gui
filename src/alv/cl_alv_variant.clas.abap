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

* The saved layouts of the grids, kept for the lifetime of the server.
* A layout belongs to a report and a handle, and
* holds the visible columns in their order and the sort criteria.
    TYPES: BEGIN OF ty_layout,
             username TYPE sy-uname,
             report   TYPE disvariant-report,
             handle   TYPE disvariant-handle,
             variant  TYPE disvariant-variant,
             text     TYPE disvariant-text,
             default  TYPE abap_bool,
             fields   TYPE string_table,
             sort     TYPE lvc_t_sort,
           END OF ty_layout.
    TYPES ty_layouts TYPE STANDARD TABLE OF ty_layout WITH DEFAULT KEY.

    CLASS-METHODS delete_layout IMPORTING is_variant TYPE disvariant.

    CLASS-METHODS save_layout
      IMPORTING
        is_layout TYPE ty_layout.

    CLASS-METHODS get_layouts
      IMPORTING
        is_variant    TYPE disvariant
      RETURNING
        VALUE(result) TYPE ty_layouts.

    CLASS-METHODS read_layout
      IMPORTING
        is_variant    TYPE disvariant
      RETURNING
        VALUE(result) TYPE ty_layout.

    CLASS-METHODS read_default_layout
      IMPORTING
        is_variant    TYPE disvariant
      RETURNING
        VALUE(result) TYPE ty_layout.

* The layout of a field catalog: its visible columns in catalog order.
    CLASS-METHODS layout_of
      IMPORTING
        it_fieldcat   TYPE lvc_t_fcat
        it_sort       TYPE lvc_t_sort
      RETURNING
        VALUE(result) TYPE ty_layout.

* Shows the layout's columns in its order and hides the others.
    CLASS-METHODS apply_layout
      IMPORTING
        is_layout   TYPE ty_layout
      CHANGING
        ct_fieldcat TYPE lvc_t_fcat
        ct_sort     TYPE lvc_t_sort.

  PRIVATE SECTION.
    CLASS-DATA gt_layouts TYPE ty_layouts.

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

  METHOD delete_layout.
    DELETE gt_layouts WHERE report = is_variant-report AND handle = is_variant-handle
      AND variant = is_variant-variant AND ( username = sy-uname OR username IS INITIAL ).
  ENDMETHOD.

  METHOD save_layout.
    IF is_layout-default = abap_true.
      LOOP AT gt_layouts ASSIGNING FIELD-SYMBOL(<ls_other>)
          WHERE report = is_layout-report AND handle = is_layout-handle AND username = is_layout-username.
        CLEAR <ls_other>-default.
      ENDLOOP.
    ENDIF.
    DELETE gt_layouts WHERE report = is_layout-report
                        AND handle = is_layout-handle
                        AND variant = is_layout-variant AND username = is_layout-username.
    APPEND is_layout TO gt_layouts.
    SORT gt_layouts BY report handle variant.
  ENDMETHOD.

  METHOD get_layouts.
    LOOP AT gt_layouts INTO DATA(ls_layout)
        WHERE report = is_variant-report AND handle = is_variant-handle
          AND ( username = sy-uname OR username IS INITIAL ).
      APPEND ls_layout TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_layout.
    LOOP AT get_layouts( is_variant ) INTO DATA(ls_layout) WHERE variant = is_variant-variant.
      result = ls_layout.
      IF result-username = sy-uname.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_default_layout.
    LOOP AT get_layouts( is_variant ) INTO DATA(ls_layout) WHERE default = abap_true.
      result = ls_layout.
      IF result-username = sy-uname.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD layout_of.
    DATA(lt_fieldcat) = it_fieldcat.
    SORT lt_fieldcat STABLE BY col_pos.
    LOOP AT lt_fieldcat INTO DATA(ls_fieldcat)
        WHERE tech IS INITIAL AND no_out IS INITIAL.
      APPEND CONV string( ls_fieldcat-fieldname ) TO result-fields.
    ENDLOOP.
    result-sort = it_sort.
  ENDMETHOD.

  METHOD apply_layout.
    DATA lv_hidden_pos TYPE i.

    lv_hidden_pos = lines( is_layout-fields ).
    LOOP AT ct_fieldcat ASSIGNING FIELD-SYMBOL(<ls_fieldcat>) WHERE tech IS INITIAL.
      READ TABLE is_layout-fields TRANSPORTING NO FIELDS
        WITH KEY table_line = CONV string( <ls_fieldcat>-fieldname ).
      IF sy-subrc = 0.
        <ls_fieldcat>-no_out = space.
        <ls_fieldcat>-col_pos = sy-tabix.
      ELSE.
        lv_hidden_pos = lv_hidden_pos + 1.
        <ls_fieldcat>-no_out = abap_true.
        <ls_fieldcat>-col_pos = lv_hidden_pos.
      ENDIF.
    ENDLOOP.
    SORT ct_fieldcat BY col_pos.
    ct_sort = is_layout-sort.
  ENDMETHOD.

ENDCLASS.
