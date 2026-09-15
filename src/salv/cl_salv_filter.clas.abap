CLASS cl_salv_filter DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        columnname TYPE lvc_fname.

    METHODS get_columnname
      RETURNING
        VALUE(value) TYPE lvc_fname.

    METHODS add_selopt
      IMPORTING
        sign         TYPE salv_de_selopt_sign DEFAULT 'I'
        option       TYPE salv_de_selopt_option DEFAULT 'EQ'
        low          TYPE salv_de_selopt_low OPTIONAL
        high         TYPE salv_de_selopt_high OPTIONAL
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_selopt
      RAISING
        cx_salv_data_error.

    METHODS get
      RETURNING
        VALUE(value) TYPE salv_t_selopt.

    METHODS clear.

  PRIVATE SECTION.
    DATA mv_columnname TYPE lvc_fname.
    DATA mt_selopt TYPE salv_t_selopt.

ENDCLASS.

CLASS cl_salv_filter IMPLEMENTATION.

  METHOD constructor.
    mv_columnname = columnname.
  ENDMETHOD.

  METHOD get_columnname.
    value = mv_columnname.
  ENDMETHOD.

  METHOD add_selopt.
    IF sign <> 'I' AND sign <> 'E'.
      RAISE EXCEPTION TYPE cx_salv_data_error.
    ENDIF.
    value = NEW cl_salv_selopt( sign   = sign
                                option = option
                                low    = low
                                high   = high ).
    APPEND value TO mt_selopt.
  ENDMETHOD.

  METHOD get.
    value = mt_selopt.
  ENDMETHOD.

  METHOD clear.
    CLEAR mt_selopt.
  ENDMETHOD.

ENDCLASS.
