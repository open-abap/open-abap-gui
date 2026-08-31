CLASS zcl_gg_host_variant DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_record,
             name   TYPE zif_gg_session_types_v1=>ty_variant,
             values TYPE zif_gg_selection_screen_types=>ty_values,
           END OF ty_record.
    TYPES ty_records TYPE STANDARD TABLE OF ty_record WITH DEFAULT KEY.

    CLASS-METHODS save
      IMPORTING
        iv_name   TYPE zif_gg_session_types_v1=>ty_variant
        it_values TYPE zif_gg_selection_screen_types=>ty_values.

    CLASS-METHODS load
      IMPORTING
        iv_name          TYPE zif_gg_session_types_v1=>ty_variant
      RETURNING
        VALUE(rt_values) TYPE zif_gg_selection_screen_types=>ty_values.

    CLASS-METHODS delete
      IMPORTING
        iv_name TYPE zif_gg_session_types_v1=>ty_variant.

    CLASS-METHODS clear.

  PRIVATE SECTION.
    CLASS-DATA mt_records TYPE ty_records.

ENDCLASS.

CLASS zcl_gg_host_variant IMPLEMENTATION.

  METHOD save.
    DELETE mt_records WHERE name = iv_name.
    APPEND VALUE #( name = iv_name values = it_values ) TO mt_records.
  ENDMETHOD.

  METHOD load.
    READ TABLE mt_records INTO DATA(ls_record) WITH KEY name = iv_name.
    IF sy-subrc = 0.
      rt_values = ls_record-values.
    ENDIF.
  ENDMETHOD.

  METHOD delete.
    DELETE mt_records WHERE name = iv_name.
  ENDMETHOD.

  METHOD clear.
    CLEAR mt_records.
  ENDMETHOD.

ENDCLASS.
