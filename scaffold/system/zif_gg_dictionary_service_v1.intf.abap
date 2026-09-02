INTERFACE zif_gg_dictionary_service_v1 PUBLIC.

  METHODS get_capabilities
    RETURNING
      VALUE(rs_capabilities) TYPE zif_gg_system_types_v1=>ty_capabilities.

  "! Dictionary object kinds this deployment can display. A kind outside the
  "! list is rejected as unsupported, never as an unknown name.
  METHODS get_object_types
    RETURNING
      VALUE(rt_types) TYPE string_table.

  METHODS get_object
    IMPORTING
      iv_object_type   TYPE string
      iv_name          TYPE string
    RETURNING
      VALUE(rs_object) TYPE zif_gg_system_types_v1=>ty_ddic_object.

  METHODS get_names
    IMPORTING iv_object_type TYPE string
    RETURNING
      VALUE(rt_names)        TYPE string_table.

ENDINTERFACE.
