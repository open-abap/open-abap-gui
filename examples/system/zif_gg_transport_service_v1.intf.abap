INTERFACE zif_gg_transport_service_v1 PUBLIC.

  METHODS get_capabilities
    RETURNING
      VALUE(rs_capabilities) TYPE zif_gg_system_types_v1=>ty_capabilities.

  "! Number convention this deployment expects for one transport type, as the
  "! two-character category between the system id and the five-digit number.
  METHODS get_number_category
    IMPORTING iv_transport_type TYPE string
    RETURNING
      VALUE(rv_category)        TYPE string.

  "! Resolve a request for one selection tab: check the number convention of
  "! that transport type, look the request up, and reject a request that
  "! belongs to a different type. The browser supplies a string, never an
  "! identity.
  METHODS resolve
    IMPORTING
      iv_transport_type TYPE string
      iv_request_id     TYPE string
    RETURNING
      VALUE(rs_request) TYPE zif_gg_system_types_v1=>ty_transport_request.

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

  "! Request numbers of one transport type, or of every type when the
  "! transport type is initial or the individual-display selection.
  METHODS get_request_ids
    IMPORTING iv_transport_type TYPE string OPTIONAL
    RETURNING
      VALUE(rt_request_ids)     TYPE string_table.

ENDINTERFACE.
