CLASS cl_salv_filter DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        columnname TYPE lvc_fname
        sign       TYPE char1
        option     TYPE char2
        low        TYPE char80
        high       TYPE char80.

    METHODS get_columnname
      RETURNING
        VALUE(value) TYPE lvc_fname.

    METHODS get_sign
      RETURNING
        VALUE(value) TYPE char1.

    METHODS get_option
      RETURNING
        VALUE(value) TYPE char2.

    METHODS get_low
      RETURNING
        VALUE(value) TYPE char80.

    METHODS get_high
      RETURNING
        VALUE(value) TYPE char80.

    METHODS matches
      IMPORTING
        value         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mv_columnname TYPE lvc_fname.
    DATA mv_sign TYPE char1.
    DATA mv_option TYPE char2.
    DATA mv_low TYPE char80.
    DATA mv_high TYPE char80.
ENDCLASS.

CLASS cl_salv_filter IMPLEMENTATION.

  METHOD constructor.
    mv_columnname = columnname.
    mv_sign = sign.
    mv_option = option.
    mv_low = low.
    mv_high = high.
  ENDMETHOD.

  METHOD get_columnname.
    value = mv_columnname.
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

  METHOD matches.
    DATA(lv_low) = CONV string( mv_low ).
    DATA(lv_high) = CONV string( mv_high ).
    CASE mv_option.
      WHEN 'EQ'.
        result = xsdbool( value = lv_low ).
      WHEN 'NE'.
        result = xsdbool( value <> lv_low ).
      WHEN 'BT'.
        result = xsdbool( value >= lv_low AND value <= lv_high ).
      WHEN 'NB'.
        result = xsdbool( value < lv_low OR value > lv_high ).
      WHEN 'GE'.
        result = xsdbool( value >= lv_low ).
      WHEN 'GT'.
        result = xsdbool( value > lv_low ).
      WHEN 'LE'.
        result = xsdbool( value <= lv_low ).
      WHEN 'LT'.
        result = xsdbool( value < lv_low ).
      WHEN 'CP'.
        result = xsdbool( value CP lv_low ).
      WHEN 'NP'.
        result = xsdbool( value NP lv_low ).
      WHEN OTHERS.
        result = abap_false.
    ENDCASE.
    IF mv_sign = 'E'.
      result = xsdbool( result = abap_false ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
