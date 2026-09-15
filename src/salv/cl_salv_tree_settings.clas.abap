CLASS cl_salv_tree_settings DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS set_header
      IMPORTING
        value TYPE salv_de_tree_text.

    METHODS get_header
      RETURNING
        VALUE(value) TYPE salv_de_tree_text.

    METHODS set_hierarchy_header
      IMPORTING
        value TYPE salv_de_tree_text.

    METHODS get_hierarchy_header
      RETURNING
        VALUE(value) TYPE salv_de_tree_text.

    METHODS set_hierarchy_tooltip
      IMPORTING
        value TYPE salv_de_tree_text.

    METHODS get_hierarchy_tooltip
      RETURNING
        VALUE(value) TYPE salv_de_tree_text.

    METHODS set_hierarchy_size
      IMPORTING
        value TYPE salv_de_header_size.

    METHODS get_hierarchy_size
      RETURNING
        VALUE(value) TYPE salv_de_header_size.

    METHODS set_hierarchy_size_in_pixel
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS is_hierarchy_size_in_pixel
      RETURNING
        VALUE(value) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mv_header TYPE salv_de_tree_text.
    DATA mv_hierarchy_header TYPE salv_de_tree_text.
    DATA mv_hierarchy_tooltip TYPE salv_de_tree_text.
    DATA mv_hierarchy_size TYPE salv_de_header_size.
    DATA mv_hierarchy_size_pixel TYPE abap_bool.

ENDCLASS.

CLASS cl_salv_tree_settings IMPLEMENTATION.

  METHOD set_header.
    mv_header = value.
  ENDMETHOD.

  METHOD get_header.
    value = mv_header.
  ENDMETHOD.

  METHOD set_hierarchy_header.
    mv_hierarchy_header = value.
  ENDMETHOD.

  METHOD get_hierarchy_header.
    value = mv_hierarchy_header.
  ENDMETHOD.

  METHOD set_hierarchy_tooltip.
    mv_hierarchy_tooltip = value.
  ENDMETHOD.

  METHOD get_hierarchy_tooltip.
    value = mv_hierarchy_tooltip.
  ENDMETHOD.

  METHOD set_hierarchy_size.
    mv_hierarchy_size = value.
  ENDMETHOD.

  METHOD get_hierarchy_size.
    value = mv_hierarchy_size.
  ENDMETHOD.

  METHOD set_hierarchy_size_in_pixel.
    mv_hierarchy_size_pixel = value.
  ENDMETHOD.

  METHOD is_hierarchy_size_in_pixel.
    value = mv_hierarchy_size_pixel.
  ENDMETHOD.

ENDCLASS.
