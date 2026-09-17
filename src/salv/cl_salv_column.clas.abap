CLASS cl_salv_column DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS set_technical IMPORTING value TYPE abap_bool DEFAULT abap_true.
    METHODS set_short_text IMPORTING value TYPE clike.
    METHODS set_medium_text IMPORTING value TYPE clike.
    METHODS set_long_text IMPORTING value TYPE clike.
    METHODS set_output_length IMPORTING value TYPE any.
    METHODS get_output_length RETURNING VALUE(length) TYPE i.
    METHODS set_sign IMPORTING value TYPE any OPTIONAL.
    METHODS set_optimized IMPORTING value TYPE abap_bool DEFAULT abap_true.
    METHODS set_alignment IMPORTING value TYPE any OPTIONAL.
    METHODS set_visible IMPORTING value TYPE abap_bool.
    METHODS set_zero IMPORTING value TYPE abap_bool DEFAULT abap_true.

    METHODS constructor
      IMPORTING
        columnname TYPE lvc_fname.

    METHODS get_columnname
      RETURNING
        VALUE(value) TYPE lvc_fname.

    METHODS is_technical
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS get_short_text
      RETURNING
        VALUE(value) TYPE string.

    METHODS get_medium_text
      RETURNING
        VALUE(value) TYPE string.

    METHODS get_long_text
      RETURNING
        VALUE(value) TYPE string.

    METHODS get_currency_column
      RETURNING
        VALUE(value) TYPE lvc_fname.

    METHODS get_quantity_column
      RETURNING
        VALUE(value) TYPE lvc_fname.

    METHODS get_tooltip
      RETURNING
        VALUE(value) TYPE lvc_tip.

    METHODS set_currency_column
      IMPORTING
        value TYPE any
      RAISING
        cx_salv_not_found
        cx_salv_data_error.

    METHODS set_tooltip
      IMPORTING
        value TYPE lvc_tip.

    METHODS set_quantity
      IMPORTING
        value TYPE any.

    METHODS set_quantity_column
      IMPORTING
        value TYPE any
      RAISING
        cx_salv_not_found
        cx_salv_data_error.

    METHODS set_currency
      IMPORTING
        value TYPE clike.

    METHODS get_ddic_datatype
      RETURNING
        VALUE(value) TYPE char4.

    METHODS get_ddic_inttype
      RETURNING
        VALUE(value) TYPE char1.

    METHODS get_ddic_domain
      RETURNING
        VALUE(value) TYPE char30.

    METHODS set_edit_mask
      IMPORTING
        value TYPE any.

    METHODS set_ddic_reference
      IMPORTING
        value TYPE salv_s_ddic_reference.

    METHODS get_ddic_reference
      RETURNING
        VALUE(value) TYPE salv_s_ddic_reference.

  PROTECTED SECTION.
    DATA mv_columnname TYPE lvc_fname.
    DATA mv_short_text TYPE string.
    DATA mv_medium_text TYPE string.
    DATA mv_long_text TYPE string.
    DATA mv_tooltip TYPE lvc_tip.
    DATA mv_output_length TYPE i.
    DATA mv_currency_column TYPE lvc_fname.
    DATA mv_quantity_column TYPE lvc_fname.
    DATA mv_technical TYPE abap_bool.
    DATA mv_optimized TYPE abap_bool.
    DATA mv_visible TYPE abap_bool.
    DATA mv_zero TYPE abap_bool.
    DATA mv_sign TYPE abap_bool.
    DATA mv_alignment TYPE i.
    DATA mv_edit_mask TYPE string.
    DATA mv_ddic_datatype TYPE char4.
    DATA mv_ddic_inttype TYPE char1.
    DATA mv_ddic_domain TYPE char30.
    DATA ms_ddic_reference TYPE salv_s_ddic_reference.
ENDCLASS.

CLASS cl_salv_column IMPLEMENTATION.
  METHOD set_edit_mask.
    mv_edit_mask = CONV string( value ).
  ENDMETHOD.

  METHOD set_ddic_reference.
    ms_ddic_reference = value.
  ENDMETHOD.

  METHOD get_ddic_reference.
    value = ms_ddic_reference.
  ENDMETHOD.

  METHOD get_ddic_domain.
    value = mv_ddic_domain.
  ENDMETHOD.

  METHOD get_ddic_inttype.
    value = mv_ddic_inttype.
  ENDMETHOD.

  METHOD get_ddic_datatype.
    value = mv_ddic_datatype.
  ENDMETHOD.

  METHOD get_columnname.
    value = mv_columnname.
  ENDMETHOD.

  METHOD is_technical.
    value = mv_technical.
  ENDMETHOD.

  METHOD constructor.
    mv_columnname = columnname.
    mv_visible = abap_true.
  ENDMETHOD.

  METHOD get_short_text.
    value = mv_short_text.
  ENDMETHOD.

  METHOD get_medium_text.
    value = mv_medium_text.
  ENDMETHOD.

  METHOD get_long_text.
    value = mv_long_text.
  ENDMETHOD.

  METHOD get_currency_column.
    value = mv_currency_column.
  ENDMETHOD.

  METHOD get_quantity_column.
    value = mv_quantity_column.
  ENDMETHOD.

  METHOD get_tooltip.
    value = mv_tooltip.
  ENDMETHOD.

  METHOD set_currency.
    mv_currency_column = CONV lvc_fname( value ).
  ENDMETHOD.

  METHOD set_quantity_column.
    mv_quantity_column = CONV lvc_fname( value ).
  ENDMETHOD.

  METHOD set_quantity.
    mv_quantity_column = CONV lvc_fname( value ).
  ENDMETHOD.

  METHOD set_tooltip.
    mv_tooltip = value.
  ENDMETHOD.

  METHOD set_currency_column.
    mv_currency_column = CONV lvc_fname( value ).
  ENDMETHOD.

  METHOD set_zero.
    mv_zero = value.
  ENDMETHOD.

  METHOD set_visible.
    mv_visible = value.
  ENDMETHOD.

  METHOD set_alignment.
    mv_alignment = value.
  ENDMETHOD.

  METHOD set_optimized.
    mv_optimized = value.
  ENDMETHOD.

  METHOD set_technical.
    mv_technical = value.
  ENDMETHOD.

  METHOD set_short_text.
    mv_short_text = CONV string( value ).
  ENDMETHOD.

  METHOD set_medium_text.
    mv_medium_text = CONV string( value ).
  ENDMETHOD.

  METHOD set_long_text.
    mv_long_text = CONV string( value ).
  ENDMETHOD.

  METHOD set_output_length.
    mv_output_length = value.
  ENDMETHOD.

  METHOD get_output_length.
    length = mv_output_length.
  ENDMETHOD.

  METHOD set_sign.
    mv_sign = value.
  ENDMETHOD.
ENDCLASS.
