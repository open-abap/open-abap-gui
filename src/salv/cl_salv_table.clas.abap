CLASS cl_salv_table DEFINITION PUBLIC.
  PUBLIC SECTION.
    CONSTANTS c_functions_all TYPE i VALUE 1.
    TYPES ty_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

    CLASS-METHODS factory
      IMPORTING
        list_display TYPE any OPTIONAL
        r_container  TYPE any OPTIONAL
      EXPORTING
        r_salv_table TYPE REF TO cl_salv_table
      CHANGING
        t_table      TYPE any.
    METHODS get_selections RETURNING VALUE(val) TYPE REF TO cl_salv_table.
    METHODS set_selected_rows IMPORTING val TYPE any.
    METHODS set_selection_mode IMPORTING val TYPE i.
    METHODS get_selected_rows RETURNING VALUE(rows) TYPE ty_rows.
    METHODS close_screen.
    METHODS refresh IMPORTING refresh_mode TYPE any OPTIONAL.
    METHODS display.
    METHODS is_offline RETURNING VALUE(value) TYPE abap_bool.
    METHODS get_metadata.
    METHODS get_layout
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_layout.
    METHODS set_screen_status
      IMPORTING
        pfstatus      TYPE any
        set_functions TYPE any OPTIONAL
        report        TYPE any.
    METHODS set_screen_popup
      IMPORTING
        start_column TYPE i
        end_column   TYPE i
        start_line   TYPE i
        end_line     TYPE i.

    METHODS get_event
      RETURNING
        VALUE(val) TYPE REF TO cl_salv_events_table.

    METHODS get_display_settings
      RETURNING
        VALUE(val) TYPE REF TO cl_salv_table.

    METHODS set_striped_pattern IMPORTING value TYPE any.
    METHODS set_list_header IMPORTING val TYPE any.
    METHODS set_top_of_list IMPORTING val TYPE any.
    METHODS set_top_of_list_print IMPORTING val TYPE any.
    METHODS get_columns RETURNING VALUE(val) TYPE REF TO cl_salv_columns_table.
    METHODS get_functions RETURNING VALUE(val) TYPE REF TO cl_salv_functions_list.

    METHODS get_aggregations
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_aggregations.
    METHODS get_filters
      RETURNING
        VALUE(foo) TYPE REF TO cl_salv_filters.

    METHODS to_xml
      IMPORTING
        xml_type   TYPE any
      RETURNING
        VALUE(xml) TYPE xstring.

    METHODS get_sorts
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_sorts.

    METHODS get_functional_settings
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_functional_settings.
ENDCLASS.

CLASS cl_salv_table IMPLEMENTATION.
  METHOD set_top_of_list_print.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_sorts.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_functional_settings.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_selected_rows.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_layout.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD to_xml.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_filters.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_aggregations.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_functions.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_selected_rows.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_metadata.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_selection_mode.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_striped_pattern.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_list_header.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD factory.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD is_offline.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_selections.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD close_screen.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD refresh.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD display.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_screen_status.
    ASSERT 1 = 'TODO'.
  ENDMETHOD.

  METHOD set_screen_popup.
    ASSERT 1 = 'TODO'.
  ENDMETHOD.

  METHOD get_event.
    ASSERT 1 = 'TODO'.
  ENDMETHOD.

  METHOD get_display_settings.
    ASSERT 1 = 'TODO'.
  ENDMETHOD.

  METHOD set_top_of_list.
    ASSERT 1 = 'TODO'.
  ENDMETHOD.

  METHOD get_columns.
    ASSERT 1 = 'TODO'.
  ENDMETHOD.

ENDCLASS.