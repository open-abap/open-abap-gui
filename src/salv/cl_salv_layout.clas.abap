CLASS cl_salv_layout DEFINITION PUBLIC.
  PUBLIC SECTION.
    CONSTANTS restrict_none TYPE i VALUE 3.

    METHODS set_key
      IMPORTING
        value TYPE any.

    METHODS set_save_restriction
      IMPORTING
        value TYPE any OPTIONAL.

    METHODS set_default
      IMPORTING
        value TYPE abap_bool.

    METHODS has_default
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS set_initial_layout
      IMPORTING
        value TYPE clike.

    METHODS get_default_layout
      RETURNING
        VALUE(sdf) TYPE string.
ENDCLASS.

CLASS cl_salv_layout IMPLEMENTATION.
  METHOD get_default_layout.
    ASSERT 1 = 'not supported'.
  ENDMETHOD.

  METHOD set_key.
    ASSERT 1 = 'not supported'.
  ENDMETHOD.

  METHOD set_initial_layout.
    ASSERT 1 = 'not supported'.
  ENDMETHOD.

  METHOD set_save_restriction.
    ASSERT 1 = 'not supported'.
  ENDMETHOD.

  METHOD set_default.
    ASSERT 1 = 'not supported'.
  ENDMETHOD.

  METHOD has_default.
    ASSERT 1 = 'not supported'.
  ENDMETHOD.
ENDCLASS.