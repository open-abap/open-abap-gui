CLASS zcl_gg_system_repository DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_program_repository_v1.

ENDCLASS.

CLASS zcl_gg_system_repository IMPLEMENTATION.

  METHOD zif_gg_program_repository_v1~get_capabilities.
    rs_capabilities = VALUE #(
      display_only = abap_true
      can_change   = abap_false
      can_create   = abap_false
      can_save     = abap_false
      can_activate = abap_false
      can_release  = abap_false
      can_export   = abap_false
      can_debug    = abap_false
      explanation  = 'Display-only deployment: source edits, activation, and debugging require a real repository backend.' ).
  ENDMETHOD.

  METHOD zif_gg_program_repository_v1~get_program.
    DATA lv_program TYPE string.

    lv_program = iv_program.
    SHIFT lv_program LEFT DELETING LEADING space.
    TRANSLATE lv_program TO UPPER CASE.
    IF lv_program <> 'ZGG_EX_015'.
      rs_program-program = lv_program.
      rs_program-error = 'Program is missing, inactive, non-executable, or not authorized.'.
      RETURN.
    ENDIF.
    rs_program = VALUE #(
      program       = 'ZGG_EX_015'
      status        = 'ACTIVE'
      executable    = abap_true
      description   = 'PARAMETERS with DEFAULT'
      source_lines  = VALUE string_table(
        ( `REPORT zgg_ex_015.` )
        ( `` )
        ( `PARAMETERS p_carr TYPE c LENGTH 3 DEFAULT 'LH'.` )
        ( `` )
        ( `START-OF-SELECTION.` )
        ( `  WRITE p_carr.` ) )
      documentation = 'Executable report used by the read-only ABAP Editor demonstration.'
      text_elements = VALUE string_table( ( `Carrier` ) ( `Execute` ) ) ).
  ENDMETHOD.

  METHOD zif_gg_program_repository_v1~get_variants.
    DATA lv_program TYPE string.

    lv_program = iv_program.
    TRANSLATE lv_program TO UPPER CASE.
    IF lv_program = 'ZGG_EX_015'.
      rt_variants = VALUE #(
        ( program     = 'ZGG_EX_015'
          name        = 'DEFAULT'
          description = 'Demo carrier LH'
          values      = VALUE #( ( name = 'P_CARR' value = 'LH' ) ) ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_program_repository_v1~get_program_names.
    rt_programs = VALUE string_table( ( `ZGG_EX_015` ) ).
  ENDMETHOD.

ENDCLASS.
