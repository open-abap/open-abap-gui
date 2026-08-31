INTERFACE zif_gg_transport_service_v1 PUBLIC.

  METHODS get_capabilities
    RETURNING
      VALUE(rs_capabilities) TYPE zif_gg_system_types_v1=>ty_capabilities.

  METHODS get_request
    IMPORTING iv_request_id TYPE string
    RETURNING
      VALUE(rs_request)     TYPE zif_gg_system_types_v1=>ty_transport_request.

  METHODS get_tasks
    IMPORTING iv_request_id TYPE string
    RETURNING
      VALUE(rt_tasks)       TYPE zif_gg_system_types_v1=>ty_transport_tasks.

  METHODS get_objects
    IMPORTING iv_request_id TYPE string
    RETURNING
      VALUE(rt_objects)     TYPE zif_gg_system_types_v1=>ty_transport_objects.

  METHODS get_logs
    IMPORTING iv_request_id TYPE string
    RETURNING
      VALUE(rt_logs)        TYPE zif_gg_system_types_v1=>ty_transport_logs.

  METHODS get_request_ids
    RETURNING
      VALUE(rt_request_ids) TYPE string_table.

ENDINTERFACE.
