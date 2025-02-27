CLASS cl_salv_column DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS set_technical IMPORTING value TYPE abap_bool DEFAULT abap_true.
    METHODS set_short_text IMPORTING value TYPE clike.
    METHODS set_medium_text IMPORTING value TYPE clike.
    METHODS set_long_text IMPORTING value TYPE clike.
    METHODS set_output_length IMPORTING value TYPE any.
    METHODS set_sign IMPORTING value TYPE any OPTIONAL.
    METHODS set_optimized IMPORTING value TYPE abap_bool DEFAULT abap_true.
    METHODS set_alignment IMPORTING svalue TYPE any OPTIONAL.
    METHODS set_visible IMPORTING value TYPE abap_bool.
ENDCLASS.

CLASS cl_salv_column IMPLEMENTATION.
  METHOD set_visible.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_alignment.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_optimized.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_technical.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_short_text.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_medium_text.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_long_text.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_output_length.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_sign.
    ASSERT 1 = 'todo'.
  ENDMETHOD.
ENDCLASS.
