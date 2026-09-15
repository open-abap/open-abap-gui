CLASS cl_salv_filters DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS clear.

    METHODS add_filter
      IMPORTING
        columnname   TYPE lvc_fname
        sign         TYPE salv_de_selopt_sign DEFAULT 'I'
        option       TYPE salv_de_selopt_option DEFAULT 'EQ'
        low          TYPE salv_de_selopt_low OPTIONAL
        high         TYPE salv_de_selopt_high OPTIONAL
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_filter
      RAISING
        cx_salv_not_found
        cx_salv_data_error
        cx_salv_existing.

    METHODS get
      RETURNING
        VALUE(value) TYPE salv_t_filter_ref.

    METHODS get_filter
      IMPORTING
        columnname   TYPE lvc_fname
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_filter
      RAISING
        cx_salv_not_found.

    METHODS is_filter_defined
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS remove_filter
      IMPORTING
        columnname TYPE lvc_fname
      RAISING
        cx_salv_not_found.

  PRIVATE SECTION.
    DATA mt_filters TYPE salv_t_filter_ref.

ENDCLASS.

CLASS cl_salv_filters IMPLEMENTATION.

  METHOD add_filter.
    IF columnname IS INITIAL.
      RAISE EXCEPTION TYPE cx_salv_data_error.
    ENDIF.
    IF option IS INITIAL.
      RAISE EXCEPTION TYPE cx_salv_data_error.
    ENDIF.
    IF line_exists( mt_filters[ columnname = columnname ] ).
      RAISE EXCEPTION TYPE cx_salv_existing.
    ENDIF.
    value = NEW cl_salv_filter( columnname ).
    value->add_selopt( sign   = sign
                       option = option
                       low    = low
                       high   = high ).
    APPEND VALUE #( columnname = columnname
                    r_filter   = value ) TO mt_filters.
  ENDMETHOD.

  METHOD clear.
    CLEAR mt_filters.
  ENDMETHOD.

  METHOD get.
    value = mt_filters.
  ENDMETHOD.

  METHOD get_filter.
    READ TABLE mt_filters INTO DATA(ls_filter) WITH KEY columnname = columnname.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_salv_not_found.
    ENDIF.
    value = ls_filter-r_filter.
  ENDMETHOD.

  METHOD is_filter_defined.
    value = xsdbool( mt_filters IS NOT INITIAL ).
  ENDMETHOD.

  METHOD remove_filter.
    IF NOT line_exists( mt_filters[ columnname = columnname ] ).
      RAISE EXCEPTION TYPE cx_salv_not_found.
    ENDIF.
    DELETE mt_filters WHERE columnname = columnname.
  ENDMETHOD.

ENDCLASS.
