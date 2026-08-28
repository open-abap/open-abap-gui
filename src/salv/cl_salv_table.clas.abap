CLASS cl_salv_table DEFINITION PUBLIC INHERITING FROM cl_salv_model_base.
  PUBLIC SECTION.
    TYPES ty_rows TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

    CLASS-METHODS is_offline
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS set_end_of_list
      IMPORTING
        value TYPE REF TO cl_salv_form_element.

    CLASS-METHODS factory
      IMPORTING
        list_display   TYPE any OPTIONAL
        r_container    TYPE any OPTIONAL
        container_name TYPE clike OPTIONAL
      EXPORTING
        r_salv_table   TYPE REF TO cl_salv_table
      CHANGING
        t_table        TYPE any.

    METHODS get_screen_status
      EXPORTING
        report   TYPE syrepid
        pfstatus TYPE any.

    METHODS get_selections RETURNING VALUE(val) TYPE REF TO cl_salv_selections.
    METHODS close_screen.
    METHODS refresh
      IMPORTING
        s_stable     TYPE any OPTIONAL
        refresh_mode TYPE any OPTIONAL
      PREFERRED PARAMETER s_stable.
    METHODS display.

    METHODS get_metadata.
    METHODS get_layout
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_layout.
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
        VALUE(val) TYPE REF TO cl_salv_display_settings.

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

    METHODS get_html
      RETURNING
        VALUE(value) TYPE string.

  PRIVATE SECTION.
    DATA mv_row_count TYPE i.
    DATA mv_header TYPE string.
ENDCLASS.

CLASS cl_salv_table IMPLEMENTATION.
  METHOD get_screen_status.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_end_of_list.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_top_of_list_print.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_sorts.
    RETURN.
  ENDMETHOD.

  METHOD get_functional_settings.
    RETURN.
  ENDMETHOD.

  METHOD get_layout.
    RETURN.
  ENDMETHOD.

  METHOD to_xml.
    RETURN.
  ENDMETHOD.

  METHOD get_filters.
    RETURN.
  ENDMETHOD.

  METHOD get_aggregations.
    RETURN.
  ENDMETHOD.

  METHOD get_functions.
    RETURN.
  ENDMETHOD.

  METHOD get_metadata.
    RETURN.
  ENDMETHOD.

  METHOD set_striped_pattern.
    RETURN.
  ENDMETHOD.

  METHOD set_list_header.
    mv_header = CONV string( val ).
  ENDMETHOD.

  METHOD factory.
    r_salv_table = NEW cl_salv_table( ).
    r_salv_table->mv_row_count = lines( t_table ).
  ENDMETHOD.

  METHOD is_offline.
    value = abap_false.
  ENDMETHOD.

  METHOD get_selections.
    RETURN.
  ENDMETHOD.

  METHOD close_screen.
    RETURN.
  ENDMETHOD.

  METHOD refresh.
    RETURN.
  ENDMETHOD.

  METHOD display.
    cl_gui_control=>set_external_html( get_html( ) ).
  ENDMETHOD.

  METHOD set_screen_popup.
    RETURN.
  ENDMETHOD.

  METHOD get_event.
    RETURN.
  ENDMETHOD.

  METHOD get_display_settings.
    RETURN.
  ENDMETHOD.

  METHOD set_top_of_list.
    RETURN.
  ENDMETHOD.

  METHOD get_columns.
    RETURN.
  ENDMETHOD.

  METHOD get_html.
    value = |<section class="gg-salv-table" aria-label="SALV table"><h2>{ cl_gui_control=>escape_html( mv_header ) }</h2><p>{ mv_row_count } rows</p><table><caption>{ cl_gui_control=>escape_html( mv_header ) }</caption><tbody></tbody></table></section>|.
  ENDMETHOD.

ENDCLASS.
