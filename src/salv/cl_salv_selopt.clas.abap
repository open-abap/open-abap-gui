CLASS cl_salv_selopt DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        sign   TYPE salv_de_selopt_sign
        option TYPE salv_de_selopt_option
        low    TYPE salv_de_selopt_low
        high   TYPE salv_de_selopt_high OPTIONAL.

    METHODS get_sign
      RETURNING
        VALUE(value) TYPE salv_de_selopt_sign.

    METHODS get_option
      RETURNING
        VALUE(value) TYPE salv_de_selopt_option.

    METHODS get_low
      RETURNING
        VALUE(value) TYPE salv_de_selopt_low.

    METHODS get_high
      RETURNING
        VALUE(value) TYPE salv_de_selopt_high.

    METHODS set_sign
      IMPORTING
        value TYPE salv_de_selopt_sign
      RAISING
        cx_salv_data_error.

    METHODS set_option
      IMPORTING
        value TYPE salv_de_selopt_option
      RAISING
        cx_salv_data_error.

    METHODS set_low
      IMPORTING
        value TYPE salv_de_selopt_low.

    METHODS set_high
      IMPORTING
        value TYPE salv_de_selopt_high.

  PRIVATE SECTION.
    DATA mv_sign TYPE salv_de_selopt_sign.
    DATA mv_option TYPE salv_de_selopt_option.
    DATA mv_low TYPE salv_de_selopt_low.
    DATA mv_high TYPE salv_de_selopt_high.

ENDCLASS.

CLASS cl_salv_selopt IMPLEMENTATION.

  METHOD constructor.
    mv_sign = sign.
    mv_option = option.
    mv_low = low.
    mv_high = high.
  ENDMETHOD.

  METHOD get_sign.
    value = mv_sign.
  ENDMETHOD.

  METHOD get_option.
    value = mv_option.
  ENDMETHOD.

  METHOD get_low.
    value = mv_low.
  ENDMETHOD.

  METHOD get_high.
    value = mv_high.
  ENDMETHOD.

  METHOD set_sign.
    IF value <> 'I' AND value <> 'E'.
      RAISE EXCEPTION TYPE cx_salv_data_error.
    ENDIF.
    mv_sign = value.
  ENDMETHOD.

  METHOD set_option.
    mv_option = value.
  ENDMETHOD.

  METHOD set_low.
    mv_low = value.
  ENDMETHOD.

  METHOD set_high.
    mv_high = value.
  ENDMETHOD.

ENDCLASS.
