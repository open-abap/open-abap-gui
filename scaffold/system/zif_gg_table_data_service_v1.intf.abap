INTERFACE zif_gg_table_data_service_v1 PUBLIC.

  METHODS get_capabilities
    RETURNING
      VALUE(rs_capabilities) TYPE zif_gg_system_types_v1=>ty_capabilities.

  METHODS get_fields
    IMPORTING iv_table_name TYPE string
    RETURNING
      VALUE(rt_fields)      TYPE zif_gg_system_types_v1=>ty_ddic_fields.

  METHODS read
    IMPORTING is_criteria TYPE zif_gg_system_types_v1=>ty_table_criteria
    RETURNING
      VALUE(rs_result)    TYPE zif_gg_system_types_v1=>ty_table_result.

ENDINTERFACE.
