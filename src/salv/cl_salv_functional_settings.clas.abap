CLASS cl_salv_functional_settings DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS get_hyperlinks
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_hyperlinks.
  PRIVATE SECTION.
    DATA mo_hyperlinks TYPE REF TO cl_salv_hyperlinks.
ENDCLASS.

CLASS cl_salv_functional_settings IMPLEMENTATION.
  METHOD get_hyperlinks.
    IF mo_hyperlinks IS NOT BOUND.
      mo_hyperlinks = NEW cl_salv_hyperlinks( ).
    ENDIF.
    value = mo_hyperlinks.
  ENDMETHOD.
ENDCLASS.
