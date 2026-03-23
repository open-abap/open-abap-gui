CLASS cl_salv_sorts DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS add_sort
      IMPORTING
        columnname TYPE clike
        sequence   TYPE any OPTIONAL
        subtotal   TYPE abap_bool DEFAULT abap_false
      RAISING
        cx_salv_not_found
        cx_salv_existing
        cx_salv_data_error.

    METHODS set_compressed_subtotal
      IMPORTING
        value TYPE lvc_fname OPTIONAL.
ENDCLASS.

CLASS cl_salv_sorts IMPLEMENTATION.
  METHOD set_compressed_subtotal.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_sort.
    ASSERT 1 = 'todo'.
  ENDMETHOD.
ENDCLASS.