CLASS cl_salv_filters DEFINITION PUBLIC.
  PUBLIC SECTION.
    TYPES ty_filter_refs TYPE STANDARD TABLE OF REF TO cl_salv_filter WITH DEFAULT KEY.

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

    METHODS get
      RETURNING
        VALUE(value) TYPE ty_filter_refs.

    METHODS matches
      IMPORTING
        columnname    TYPE lvc_fname
        value         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mt_filters TYPE ty_filter_refs.

ENDCLASS.

CLASS cl_salv_filters IMPLEMENTATION.
  METHOD add_filter.
    IF columnname IS INITIAL.
      RAISE EXCEPTION TYPE cx_salv_data_error.
    ENDIF.
    IF sign <> 'I' AND sign <> 'E'.
      RAISE EXCEPTION TYPE cx_salv_data_error.
    ENDIF.
    IF option IS INITIAL.
      RAISE EXCEPTION TYPE cx_salv_data_error.
    ENDIF.
    LOOP AT mt_filters INTO DATA(lo_filter).
      IF lo_filter->get_columnname( ) = columnname.
        RAISE EXCEPTION TYPE cx_salv_existing.
      ENDIF.
    ENDLOOP.
    value = NEW cl_salv_filter(
      columnname = columnname
      sign       = sign
      option     = option
      low        = low
      high       = high ).
    APPEND value TO mt_filters.
  ENDMETHOD.

  METHOD clear.
    CLEAR mt_filters.
  ENDMETHOD.

  METHOD get.
    value = mt_filters.
  ENDMETHOD.

  METHOD matches.
    result = abap_true.
    LOOP AT mt_filters INTO DATA(lo_filter).
      IF lo_filter->get_columnname( ) = columnname.
        result = lo_filter->matches( value ).
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
