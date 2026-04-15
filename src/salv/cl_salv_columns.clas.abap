CLASS cl_salv_columns DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS set_column_position
      IMPORTING
        columnname TYPE lvc_fname
        position   TYPE i OPTIONAL.

ENDCLASS.

CLASS cl_salv_columns IMPLEMENTATION.
  METHOD set_column_position.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.