CLASS cl_salv_tree_settings DEFINITION PUBLIC.
  PUBLIC SECTION.

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

ENDCLASS.

CLASS cl_salv_tree_settings IMPLEMENTATION.

  METHOD set_hierarchy_header.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_hierarchy_header.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_hierarchy_tooltip.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_hierarchy_tooltip.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_hierarchy_size.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_hierarchy_size.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_hierarchy_size_in_pixel.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD is_hierarchy_size_in_pixel.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
