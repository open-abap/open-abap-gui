CLASS cl_salv_columns DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS set_column_position
      IMPORTING
        columnname TYPE lvc_fname
        position   TYPE i OPTIONAL.

    METHODS get_column
      IMPORTING
        columnname   TYPE lvc_fname
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_column
      RAISING
        cx_salv_not_found.

ENDCLASS.

CLASS cl_salv_columns IMPLEMENTATION.
  METHOD get_column.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_column_position.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.