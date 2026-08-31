INTERFACE zif_gg_program_repository_v1 PUBLIC.

  METHODS get_capabilities
    RETURNING
      VALUE(rs_capabilities) TYPE zif_gg_system_types_v1=>ty_capabilities.

  METHODS get_program
    IMPORTING iv_program TYPE string
    RETURNING
      VALUE(rs_program)  TYPE zif_gg_system_types_v1=>ty_program.

  METHODS get_variants
    IMPORTING iv_program TYPE string
    RETURNING
      VALUE(rt_variants) TYPE zif_gg_system_types_v1=>ty_variants.

  METHODS get_program_names
    RETURNING
      VALUE(rt_programs) TYPE string_table.

ENDINTERFACE.
