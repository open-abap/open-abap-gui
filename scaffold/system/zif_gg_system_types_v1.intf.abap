INTERFACE zif_gg_system_types_v1 PUBLIC.

* Typed, server-owned records shared by the system transaction adapters. The
* browser never supplies or becomes the authority for any of these records.

  TYPES: BEGIN OF ty_capabilities,
           display_only TYPE abap_bool,
           can_change   TYPE abap_bool,
           can_create   TYPE abap_bool,
           can_save     TYPE abap_bool,
           can_activate TYPE abap_bool,
           can_release  TYPE abap_bool,
           can_export   TYPE abap_bool,
           can_debug    TYPE abap_bool,
           explanation  TYPE string,
         END OF ty_capabilities.

  TYPES: BEGIN OF ty_transport_request,
           request_id    TYPE string,
           request_type  TYPE string,
           owner         TYPE string,
           short_text    TYPE string,
           status        TYPE string,
           source_system TYPE string,
           target_system TYPE string,
           attributes    TYPE string,
           documentation TYPE string,
           error         TYPE string,
         END OF ty_transport_request.
  TYPES ty_transport_requests TYPE STANDARD TABLE OF ty_transport_request
    WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_transport_task,
           request_id TYPE string,
           task_id    TYPE string,
           owner      TYPE string,
           status     TYPE string,
           short_text TYPE string,
         END OF ty_transport_task.
  TYPES ty_transport_tasks TYPE STANDARD TABLE OF ty_transport_task
    WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_transport_object,
           request_id  TYPE string,
           object_id   TYPE string,
           object_type TYPE string,
           object_name TYPE string,
           description TYPE string,
         END OF ty_transport_object.
  TYPES ty_transport_objects TYPE STANDARD TABLE OF ty_transport_object
    WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_transport_log,
           request_id TYPE string,
           sequence   TYPE i,
           severity   TYPE string,
           text       TYPE string,
         END OF ty_transport_log.
  TYPES ty_transport_logs TYPE STANDARD TABLE OF ty_transport_log
    WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_ddic_field,
           position    TYPE i,
           name        TYPE string,
           key_flag    TYPE abap_bool,
           data_type   TYPE string,
           int_type    TYPE string,
           length      TYPE i,
           decimals    TYPE i,
           description TYPE string,
         END OF ty_ddic_field.
  TYPES ty_ddic_fields TYPE STANDARD TABLE OF ty_ddic_field WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_ddic_object,
           object_type    TYPE string,
           name           TYPE string,
           description    TYPE string,
           delivery_class TYPE string,
           fields         TYPE ty_ddic_fields,
           error          TYPE string,
         END OF ty_ddic_object.

  TYPES: BEGIN OF ty_table_criteria,
           table_name     TYPE string,
           carrid_low     TYPE string,
           carrid_high    TYPE string,
           exclude_carrid TYPE abap_bool,
           max_rows       TYPE i,
         END OF ty_table_criteria.

  TYPES ty_flights TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.
  TYPES: BEGIN OF ty_table_result,
           table_name    TYPE string,
           rows          TYPE ty_flights,
           total_rows    TYPE i,
           returned_rows TYPE i,
           truncated     TYPE abap_bool,
           error         TYPE string,
         END OF ty_table_result.

  TYPES: BEGIN OF ty_program,
           program       TYPE string,
           status        TYPE string,
           executable    TYPE abap_bool,
           description   TYPE string,
           source_lines  TYPE string_table,
           documentation TYPE string,
           text_elements TYPE string_table,
           error         TYPE string,
         END OF ty_program.

  TYPES: BEGIN OF ty_variant,
           program     TYPE string,
           name        TYPE string,
           description TYPE string,
           values      TYPE zif_gg_selection_screen_types=>ty_values,
           error       TYPE string,
         END OF ty_variant.
  TYPES ty_variants TYPE STANDARD TABLE OF ty_variant WITH DEFAULT KEY.

ENDINTERFACE.
