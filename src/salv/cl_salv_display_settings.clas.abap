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

ENDCLASS.

CLASS cl_salv_display_settings IMPLEMENTATION.
  METHOD set_fit_column_to_table_size.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_list_header.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_striped_pattern.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_list_header_size.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.