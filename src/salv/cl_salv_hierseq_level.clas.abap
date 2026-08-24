CLASS cl_salv_hierseq_level DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS get_columns
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_columns_hierseq.

    METHODS get_selections
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_selections.

    METHODS get_sorts
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_sorts.

    METHODS get_filters
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_filters.

    METHODS get_aggregations
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_aggregations.

    METHODS get_binding
      RETURNING
        VALUE(value) TYPE salv_t_hierseq_binding.

    METHODS set_items_expanded
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS is_items_expanded
      RETURNING
        VALUE(value) TYPE abap_bool.

ENDCLASS.

CLASS cl_salv_hierseq_level IMPLEMENTATION.

  METHOD get_columns.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selections.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_sorts.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_filters.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_aggregations.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_binding.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_items_expanded.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD is_items_expanded.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
