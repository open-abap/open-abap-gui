CLASS cl_salv_functions_list DEFINITION PUBLIC INHERITING FROM cl_salv_functions.
  PUBLIC SECTION.

    METHODS set_default
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_view_excel
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_group_filter
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_group_sort
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_group_layout
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_filter
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_print
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_find
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_print_preview
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_export_spreadsheet
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_sort_asc
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_sort_desc
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_export_localfile
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_layout_save
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

ENDCLASS.

CLASS cl_salv_functions_list IMPLEMENTATION.
  METHOD set_export_localfile.
    set_named_visibility(
      name  = 'EXPORT_LOCALFILE'
      value = value ).
  ENDMETHOD.

  METHOD set_sort_desc.
    set_named_visibility(
      name  = 'SORT_DESC'
      value = value ).
  ENDMETHOD.

  METHOD set_sort_asc.
    set_named_visibility(
      name  = 'SORT_ASC'
      value = value ).
  ENDMETHOD.

  METHOD set_export_spreadsheet.
    set_named_visibility(
      name  = 'EXPORT_SPREADSHEET'
      value = value ).
  ENDMETHOD.

  METHOD set_print_preview.
    set_named_visibility(
      name  = 'PRINT_PREVIEW'
      value = value ).
  ENDMETHOD.

  METHOD set_find.
    set_named_visibility(
      name  = 'FIND'
      value = value ).
  ENDMETHOD.

  METHOD set_print.
    set_named_visibility(
      name  = 'PRINT'
      value = value ).
  ENDMETHOD.

  METHOD set_filter.
    set_named_visibility(
      name  = 'FILTER'
      value = value ).
  ENDMETHOD.

  METHOD set_layout_save.
    set_named_visibility(
      name  = 'LAYOUT_SAVE'
      value = value ).
  ENDMETHOD.

  METHOD set_group_layout.
    set_named_visibility(
      name  = 'GROUP_LAYOUT'
      value = value ).
  ENDMETHOD.

  METHOD set_group_sort.
    set_named_visibility(
      name  = 'GROUP_SORT'
      value = value ).
  ENDMETHOD.

  METHOD set_group_filter.
    set_named_visibility(
      name  = 'GROUP_FILTER'
      value = value ).
  ENDMETHOD.

  METHOD set_view_excel.
    set_named_visibility(
      name  = 'VIEW_EXCEL'
      value = value ).
  ENDMETHOD.

  METHOD set_default.
    set_all( value ).
  ENDMETHOD.

ENDCLASS.
