INTERFACE zif_gg_table_data_service_v1 PUBLIC.

  METHODS get_capabilities
    RETURNING
      VALUE(rs_capabilities) TYPE zif_gg_system_types_v1=>ty_capabilities.

  "! Tables and views the data-access policy allows this deployment to browse.
  "! The Data Browser generates one criteria screen per entry.
  METHODS get_table_names
    RETURNING
      VALUE(rt_names) TYPE string_table.

  METHODS get_fields
    IMPORTING iv_table_name TYPE string
    RETURNING
      VALUE(rt_fields)      TYPE zif_gg_system_types_v1=>ty_ddic_fields.

  "! Validate criteria against the field metadata before any data is read.
  "! Returns the first violation, or an empty string when the criteria are
  "! usable for a server-built query.
  METHODS validate
    IMPORTING is_criteria TYPE zif_gg_system_types_v1=>ty_table_criteria
    RETURNING
      VALUE(rv_error)     TYPE string.

  METHODS read
    IMPORTING is_criteria TYPE zif_gg_system_types_v1=>ty_table_criteria
    RETURNING
      VALUE(rs_result)    TYPE zif_gg_system_types_v1=>ty_table_result.

ENDINTERFACE.
