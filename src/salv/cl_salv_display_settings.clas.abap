CLASS cl_salv_display_settings DEFINITION PUBLIC.
  PUBLIC SECTION.

    CONSTANTS true TYPE abap_bool VALUE abap_true.
    CONSTANTS false TYPE abap_bool VALUE abap_false.

    METHODS set_list_header_size
      IMPORTING
        value TYPE any.

    METHODS set_striped_pattern
      IMPORTING
        value TYPE abap_bool.

    METHODS set_list_header
      IMPORTING
        value TYPE lvc_title.

    METHODS set_fit_column_to_table_size
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS get_list_header
      RETURNING
        VALUE(value) TYPE lvc_title.

    METHODS is_striped_pattern
      RETURNING
        VALUE(value) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mv_list_header_size TYPE i.
    DATA mv_striped_pattern TYPE abap_bool.
    DATA mv_list_header TYPE lvc_title.
    DATA mv_fit_column TYPE abap_bool.

ENDCLASS.

CLASS cl_salv_display_settings IMPLEMENTATION.
  METHOD set_fit_column_to_table_size.
    mv_fit_column = value.
  ENDMETHOD.

  METHOD set_list_header.
    mv_list_header = value.
  ENDMETHOD.

  METHOD set_striped_pattern.
    mv_striped_pattern = value.
  ENDMETHOD.

  METHOD set_list_header_size.
    mv_list_header_size = value.
  ENDMETHOD.

  METHOD get_list_header.
    value = mv_list_header.
  ENDMETHOD.

  METHOD is_striped_pattern.
    value = mv_striped_pattern.
  ENDMETHOD.

ENDCLASS.
