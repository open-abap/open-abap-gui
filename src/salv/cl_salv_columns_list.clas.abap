CLASS cl_salv_columns_list DEFINITION PUBLIC INHERITING FROM cl_salv_columns.
  PUBLIC SECTION.

    METHODS set_key_fixation
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

ENDCLASS.

CLASS cl_salv_columns_list IMPLEMENTATION.
  METHOD set_key_fixation.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.