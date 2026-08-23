CLASS cl_salv_filters DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS clear.

    METHODS add_filter
      IMPORTING
        columnname   TYPE lvc_fname
        sign         TYPE char1 DEFAULT 'I'
        option       TYPE char2 DEFAULT 'EQ'
        low          TYPE char80 OPTIONAL
        high         TYPE char80 OPTIONAL
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