CLASS cl_salv_sorts DEFINITION PUBLIC.
  PUBLIC SECTION.
    TYPES ty_sort_refs TYPE STANDARD TABLE OF REF TO cl_salv_sort WITH DEFAULT KEY.

    METHODS add_sort
      IMPORTING
        columnname   TYPE clike
        sequence     TYPE any OPTIONAL
        position     TYPE i OPTIONAL
        subtotal     TYPE abap_bool DEFAULT abap_false
        group        TYPE i OPTIONAL
        obligatory   TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_sort
      RAISING
        cx_salv_not_found
        cx_salv_existing
        cx_salv_data_error.

    METHODS set_compressed_subtotal
      IMPORTING
        value TYPE lvc_fname OPTIONAL.

    METHODS clear.

    METHODS get
      RETURNING
        VALUE(value) TYPE ty_sort_refs.

  PRIVATE SECTION.
    DATA mt_sorts TYPE ty_sort_refs.
    DATA mv_compressed_subtotal TYPE lvc_fname.
ENDCLASS.

CLASS cl_salv_sorts IMPLEMENTATION.
  METHOD clear.
    CLEAR mt_sorts.
    CLEAR mv_compressed_subtotal.
  ENDMETHOD.

  METHOD set_compressed_subtotal.
    mv_compressed_subtotal = value.
  ENDMETHOD.

  METHOD add_sort.
    DATA(lv_columnname) = CONV lvc_fname( columnname ).
    IF lv_columnname IS INITIAL.
      RAISE EXCEPTION TYPE cx_salv_data_error.
    ENDIF.
    LOOP AT mt_sorts INTO DATA(lo_existing).
      IF lo_existing->get_columnname( ) = lv_columnname.
        RAISE EXCEPTION TYPE cx_salv_existing.
      ENDIF.
    ENDLOOP.
    value = NEW cl_salv_sort(
      columnname = lv_columnname
      sequence   = CONV i( sequence )
      position   = position
      subtotal   = subtotal
      group      = group
      obligatory = obligatory ).
    APPEND value TO mt_sorts.
  ENDMETHOD.

  METHOD get.
    value = mt_sorts.
  ENDMETHOD.
ENDCLASS.
