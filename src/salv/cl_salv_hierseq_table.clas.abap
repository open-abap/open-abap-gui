CLASS cl_salv_hierseq_table DEFINITION PUBLIC INHERITING FROM cl_salv_model_base.
  PUBLIC SECTION.

    CLASS-METHODS factory
      IMPORTING
        t_binding_level1_level2 TYPE salv_t_hierseq_binding
        r_container             TYPE REF TO cl_gui_container OPTIONAL
        container_name          TYPE clike OPTIONAL
      EXPORTING
        r_hierseq               TYPE REF TO cl_salv_hierseq_table
      CHANGING
        t_table_level1          TYPE STANDARD TABLE
        t_table_level2          TYPE STANDARD TABLE
      RAISING
        cx_salv_data_error
        cx_salv_not_found.

    METHODS get_columns
      IMPORTING
        level        TYPE i
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_columns_hierseq
      RAISING
        cx_salv_not_found.

    METHODS get_level
      IMPORTING
        level        TYPE i
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_hierseq_level
      RAISING
        cx_salv_not_found.

    METHODS get_selections
      IMPORTING
        level        TYPE i
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_selections
      RAISING
        cx_salv_not_found.

    METHODS get_functions
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_functions_list.

    METHODS get_layout
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_layout.

    METHODS get_sorts
      IMPORTING
        level        TYPE i
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_sorts
      RAISING
        cx_salv_not_found.

    METHODS get_filters
      IMPORTING
        level        TYPE i
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_filters
      RAISING
        cx_salv_not_found.

    METHODS get_aggregations
      IMPORTING
        level        TYPE i
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_aggregations
      RAISING
        cx_salv_not_found.

    METHODS get_event
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_events_hierseq.

    METHODS get_display_settings
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_display_settings.

    METHODS display.

    METHODS refresh.

ENDCLASS.

CLASS cl_salv_hierseq_table IMPLEMENTATION.

  METHOD factory.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_columns.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_level.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selections.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_functions.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_layout.
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

  METHOD get_event.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_display_settings.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD display.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD refresh.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
