CLASS cl_salv_filters DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS clear.

    METHODS add_filter
      IMPORTING
        columnname   TYPE lvc_fname
        sign         TYPE any DEFAULT 'I'
        option       TYPE any DEFAULT 'EQ'
        low          TYPE any OPTIONAL
        high         TYPE any OPTIONAL
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_filter
      RAISING
        cx_salv_not_found
        cx_salv_data_error
        cx_salv_existing.

ENDCLASS.

CLASS cl_salv_filters IMPLEMENTATION.
  METHOD add_filter.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD clear.
    RETURN. " todo, implement method
  ENDMETHOD.
ENDCLASS.