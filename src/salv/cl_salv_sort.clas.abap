CLASS cl_salv_sort DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        columnname TYPE lvc_fname
        sequence   TYPE i
        subtotal   TYPE abap_bool
        group      TYPE i
        obligatory TYPE abap_bool.

    METHODS get_columnname
      RETURNING
        VALUE(value) TYPE lvc_fname.

    METHODS get_sequence
      RETURNING
        VALUE(value) TYPE i.

    METHODS is_subtotalled
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS set_subtotal
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true
      RAISING
        cx_salv_data_error.

  PRIVATE SECTION.
    DATA mv_columnname TYPE lvc_fname.
    DATA mv_sequence TYPE i.
    DATA mv_subtotal TYPE abap_bool.
    DATA mv_group TYPE i.
    DATA mv_obligatory TYPE abap_bool.

ENDCLASS.

CLASS cl_salv_sort IMPLEMENTATION.

  METHOD constructor.
    mv_columnname = columnname.
    mv_sequence = sequence.
    mv_subtotal = subtotal.
    mv_group = group.
    mv_obligatory = obligatory.
  ENDMETHOD.

  METHOD get_columnname.
    value = mv_columnname.
  ENDMETHOD.

  METHOD get_sequence.
    value = mv_sequence.
  ENDMETHOD.

  METHOD is_subtotalled.
    value = mv_subtotal.
  ENDMETHOD.

  METHOD set_subtotal.
    mv_subtotal = value.
  ENDMETHOD.

ENDCLASS.
