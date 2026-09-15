CLASS cl_salv_sorts DEFINITION PUBLIC.
  PUBLIC SECTION.

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
        VALUE(value) TYPE salv_t_sort_ref.

  PRIVATE SECTION.
    DATA mt_sorts TYPE salv_t_sort_ref.
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
    IF line_exists( mt_sorts[ columnname = lv_columnname ] ).
      RAISE EXCEPTION TYPE cx_salv_existing.
    ENDIF.
    value = NEW cl_salv_sort(
      columnname = lv_columnname
      sequence   = CONV i( sequence )
      subtotal   = subtotal
      group      = group
      obligatory = obligatory ).
    APPEND VALUE #( columnname = lv_columnname
                    r_sort     = value ) TO mt_sorts.
  ENDMETHOD.

  METHOD get.
    value = mt_sorts.
  ENDMETHOD.
ENDCLASS.
