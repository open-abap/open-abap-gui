CLASS zcl_gg_program_registry DEFINITION PUBLIC FINAL CREATE PUBLIC.

* The catalog of executable reports that declare their program without a
* transaction. It discovers zif_gg_program_v1 implementations, validates their
* executable contract, normalizes program names, and owns the process-local
* catalog cache. Reports started by a transaction are cataloged by
* zcl_gg_transaction_registry instead.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_program,
             program     TYPE zif_gg_session_types_v1=>ty_program,
             description TYPE string,
             class_name  TYPE string,
           END OF ty_program.
    TYPES ty_programs TYPE STANDARD TABLE OF ty_program WITH DEFAULT KEY.

    CLASS-METHODS get_all
      RETURNING
        VALUE(rt_programs) TYPE ty_programs.

    CLASS-METHODS lookup
      IMPORTING
        iv_program        TYPE string
      RETURNING
        VALUE(rs_program) TYPE ty_program.

    CLASS-METHODS clear.

  PRIVATE SECTION.
    CLASS-DATA mt_programs TYPE ty_programs.
    CLASS-DATA mv_initialized TYPE abap_bool.

    CLASS-METHODS ensure_catalog.

ENDCLASS.

CLASS zcl_gg_program_registry IMPLEMENTATION.

  METHOD get_all.
    ensure_catalog( ).
    rt_programs = mt_programs.
  ENDMETHOD.

  METHOD lookup.
    DATA lv_program TYPE zif_gg_session_types_v1=>ty_program.

    ensure_catalog( ).
    lv_program = to_upper( condense( iv_program ) ).
    IF lv_program IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE mt_programs INTO rs_program WITH KEY program = lv_program.
  ENDMETHOD.

  METHOD clear.
    CLEAR mt_programs.
    CLEAR mv_initialized.
  ENDMETHOD.

  METHOD ensure_catalog.
    DATA lt_names TYPE string_table.
    DATA lo_object TYPE REF TO object.
    DATA lo_metadata TYPE REF TO zif_gg_program_v1.
    DATA lo_report TYPE REF TO zif_gg_report_v1.
    DATA ls_metadata TYPE zif_gg_program_v1=>ty_program.
    DATA ls_program TYPE ty_program.
    DATA lv_class_name TYPE string.

    IF mv_initialized = abap_true.
      RETURN.
    ENDIF.
    CLEAR mt_programs.
    lt_names = zcl_gg_class_discovery=>implementations_of( `ZIF_GG_PROGRAM_V1` ).

    LOOP AT lt_names INTO lv_class_name.
      TRY.
          CREATE OBJECT lo_object TYPE (lv_class_name).
          lo_metadata ?= lo_object.
        CATCH cx_root INTO DATA(lx_metadata).
          RAISE EXCEPTION NEW zcx_gg_transaction_error(
            iv_message = |Program class { lv_class_name } cannot provide metadata: { lx_metadata->get_text( ) }| ).
      ENDTRY.
      TRY.
          lo_report ?= lo_object.
        CATCH cx_root.
          RAISE EXCEPTION NEW zcx_gg_transaction_error(
            iv_message = |Program class { lv_class_name } does not implement ZIF_GG_REPORT_V1| ).
      ENDTRY.

      ls_metadata = lo_metadata->get_program( ).
      CLEAR ls_program.
      ls_program-program = to_upper( condense( ls_metadata-program ) ).
      ls_program-description = condense( ls_metadata-description ).
      ls_program-class_name = lv_class_name.
      IF ls_program-program IS INITIAL.
        RAISE EXCEPTION NEW zcx_gg_transaction_error(
          iv_message = |Invalid program metadata in { lv_class_name }: program is initial| ).
      ENDIF.
      IF ls_program-description IS INITIAL.
        ls_program-description = ls_program-program.
      ENDIF.
      APPEND ls_program TO mt_programs.
    ENDLOOP.

    SORT mt_programs BY program class_name.
    LOOP AT mt_programs INTO DATA(ls_current).
      IF sy-tabix > 1.
        READ TABLE mt_programs INTO DATA(ls_previous) INDEX sy-tabix - 1.
        IF ls_current-program = ls_previous-program.
          RAISE EXCEPTION NEW zcx_gg_transaction_error(
            iv_message = |Duplicate program { ls_current-program } in { ls_previous-class_name } and { ls_current-class_name }| ).
        ENDIF.
      ENDIF.
    ENDLOOP.
    mv_initialized = abap_true.
  ENDMETHOD.

ENDCLASS.
