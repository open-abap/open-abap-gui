CLASS cl_salv_tree DEFINITION PUBLIC.
  PUBLIC SECTION.

    CLASS-METHODS factory
      IMPORTING
        hide_header TYPE abap_bool OPTIONAL
        r_container TYPE REF TO cl_gui_container OPTIONAL
      EXPORTING
        r_salv_tree TYPE REF TO cl_salv_tree
      CHANGING
        t_table     TYPE STANDARD TABLE
      RAISING
        cx_salv_error.

    METHODS get_nodes
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_nodes.

    METHODS get_columns
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_columns_tree.

    METHODS get_functions
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_functions_tree.

    METHODS get_selections
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_selections_tree.

    METHODS get_event
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_events_tree.

    METHODS get_display_settings
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_display_settings.

    METHODS display.

    METHODS refresh.

ENDCLASS.

CLASS cl_salv_tree IMPLEMENTATION.

  METHOD factory.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_nodes.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_columns.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_functions.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selections.
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
