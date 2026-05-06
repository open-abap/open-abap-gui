CLASS cl_salv_sort DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS set_subtotal
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true
       RAISING
        cx_salv_data_error.

ENDCLASS.

CLASS cl_salv_sort IMPLEMENTATION.
  METHOD set_subtotal.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.