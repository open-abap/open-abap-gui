CLASS zcl_gg_system_repository DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Read-only program repository. Missing, inactive, non-executable and
* unauthorized programs stay distinguishable: an unauthorized program is never
* reported as missing, and an inactive or non-executable program can still be
* displayed while execution is refused with its own reason.

  PUBLIC SECTION.
    INTERFACES zif_gg_program_repository_v1.

  PRIVATE SECTION.
    METHODS normalized
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.

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

    lv_program = normalized( iv_program ).
    rs_program-program = lv_program.
    CASE lv_program.
      WHEN 'ZGG_EX_015'.
        rs_program = VALUE #(
          program       = 'ZGG_EX_015'
          status        = zif_gg_system_types_v1=>program_active
          program_type  = 'Executable program'
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
      WHEN 'ZGG_EX_015_INC'.
        rs_program = VALUE #(
          program       = 'ZGG_EX_015_INC'
          status        = zif_gg_system_types_v1=>program_active
          program_type  = 'Include program'
          executable    = abap_false
          description   = 'Include used by the editor demonstration'
          source_lines  = VALUE string_table(
            ( `* Include for zgg_ex_015.` )
            ( `CONSTANTS gc_default_carrier TYPE c LENGTH 3 VALUE 'LH'.` ) )
          documentation = 'An include has no standalone execution; SE38 refuses F8 for it.'
          text_elements = VALUE string_table( ) ).
      WHEN 'ZGG_DRAFT'.
        rs_program = VALUE #(
          program       = 'ZGG_DRAFT'
          status        = zif_gg_system_types_v1=>program_inactive
          program_type  = 'Executable program'
          executable    = abap_true
          description   = 'Inactive draft report'
          source_lines  = VALUE string_table(
            ( `REPORT zgg_draft.` )
            ( `* This version has never been activated.` ) )
          documentation = 'The inactive version is displayable; execution needs an activated version.'
          text_elements = VALUE string_table( ) ).
      WHEN 'ZGG_LOCKED'.
        rs_program-status = zif_gg_system_types_v1=>program_active.
        rs_program-error_kind = zif_gg_system_types_v1=>program_unauthorized.
        rs_program-error = 'You are not authorized to display this program.'.
      WHEN OTHERS.
        rs_program-status = zif_gg_system_types_v1=>program_missing.
        rs_program-error_kind = zif_gg_system_types_v1=>program_missing.
        rs_program-error = 'Program does not exist in the repository.'.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_program_repository_v1~get_variants.
    DATA lv_program TYPE string.

    lv_program = normalized( iv_program ).
    IF lv_program = 'ZGG_EX_015'.
      rt_variants = VALUE #(
        ( program     = 'ZGG_EX_015'
          name        = 'DEFAULT'
          description = 'Demo carrier LH'
          values      = VALUE #( ( name = 'P_CARR' value = 'LH' ) ) ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_program_repository_v1~get_program_names.
*   Value help never lists a program the caller may not display.
    rt_programs = VALUE string_table(
      ( `ZGG_EX_015` )
      ( `ZGG_EX_015_INC` )
      ( `ZGG_DRAFT` ) ).
  ENDMETHOD.

  METHOD normalized.
    rv_text = iv_text.
    SHIFT rv_text LEFT DELETING LEADING space.
    TRANSLATE rv_text TO UPPER CASE.
  ENDMETHOD.

ENDCLASS.
