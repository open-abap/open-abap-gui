CLASS zcl_gg_host_variant DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_record,
             report TYPE string,
             owner  TYPE string,
             name   TYPE zif_gg_session_types_v1=>ty_variant,
             values TYPE zif_gg_selection_screen_types=>ty_values,
             states TYPE zif_gg_selection_screen_types=>ty_states,
             screen TYPE zif_gg_selection_screen_types=>ty_screen_number,
           END OF ty_record.
    TYPES ty_records TYPE STANDARD TABLE OF ty_record WITH DEFAULT KEY.

    CLASS-METHODS save
      IMPORTING
        iv_name   TYPE zif_gg_session_types_v1=>ty_variant
        it_values TYPE zif_gg_selection_screen_types=>ty_values
        iv_report TYPE string DEFAULT ''
        iv_owner  TYPE string DEFAULT 'GG_DEFAULT'
        it_states TYPE zif_gg_selection_screen_types=>ty_states OPTIONAL
        iv_screen TYPE zif_gg_selection_screen_types=>ty_screen_number DEFAULT '1000'.

    CLASS-METHODS exists
      IMPORTING
        iv_name          TYPE zif_gg_session_types_v1=>ty_variant
        iv_report        TYPE string DEFAULT ''
        iv_owner         TYPE string DEFAULT 'GG_DEFAULT'
      RETURNING
        VALUE(rv_exists) TYPE abap_bool.

    CLASS-METHODS load_record
      IMPORTING
        iv_name          TYPE zif_gg_session_types_v1=>ty_variant
        iv_report        TYPE string DEFAULT ''
        iv_owner         TYPE string DEFAULT 'GG_DEFAULT'
      RETURNING
        VALUE(rs_record) TYPE ty_record.

    CLASS-METHODS first_name
      IMPORTING
        iv_report      TYPE string DEFAULT ''
        iv_owner       TYPE string DEFAULT 'GG_DEFAULT'
      RETURNING
        VALUE(rv_name) TYPE zif_gg_session_types_v1=>ty_variant.

    CLASS-METHODS load
      IMPORTING
        iv_name          TYPE zif_gg_session_types_v1=>ty_variant
        iv_report        TYPE string DEFAULT ''
        iv_owner         TYPE string DEFAULT 'GG_DEFAULT'
      RETURNING
        VALUE(rt_values) TYPE zif_gg_selection_screen_types=>ty_values.

    CLASS-METHODS delete
      IMPORTING
        iv_name   TYPE zif_gg_session_types_v1=>ty_variant
        iv_report TYPE string DEFAULT ''
        iv_owner  TYPE string DEFAULT 'GG_DEFAULT'.

    CLASS-METHODS clear.

  PRIVATE SECTION.
    CLASS-DATA mt_records TYPE ty_records.

ENDCLASS.

CLASS zcl_gg_host_variant IMPLEMENTATION.

  METHOD save.
    DELETE mt_records WHERE report = iv_report
                        AND owner = iv_owner
                        AND name = iv_name.
    APPEND VALUE #( report = iv_report
                    owner  = iv_owner
                    name   = iv_name
                    values = it_values
                    states = it_states
                    screen = iv_screen ) TO mt_records.
  ENDMETHOD.

  METHOD exists.
    READ TABLE mt_records TRANSPORTING NO FIELDS
      WITH KEY report = iv_report owner = iv_owner name = iv_name.
    rv_exists = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD load_record.
    READ TABLE mt_records INTO rs_record
      WITH KEY report = iv_report owner = iv_owner name = iv_name.
  ENDMETHOD.

  METHOD first_name.
    READ TABLE mt_records INTO DATA(ls_record)
      WITH KEY report = iv_report owner = iv_owner.
    IF sy-subrc = 0.
      rv_name = ls_record-name.
    ENDIF.
  ENDMETHOD.

  METHOD load.
    READ TABLE mt_records INTO DATA(ls_record)
      WITH KEY report = iv_report owner = iv_owner name = iv_name.
    IF sy-subrc = 0.
      rt_values = ls_record-values.
    ENDIF.
  ENDMETHOD.

  METHOD delete.
    DELETE mt_records WHERE report = iv_report
                        AND owner = iv_owner
                        AND name = iv_name.
  ENDMETHOD.

  METHOD clear.
    CLEAR mt_records.
  ENDMETHOD.

ENDCLASS.
