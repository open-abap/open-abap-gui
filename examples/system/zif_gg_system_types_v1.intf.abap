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

* Transport types recognized by the transport catalog. A selection tab names
* one of them; the catalog record decides which requests belong to it.
  CONSTANTS transport_standard TYPE string VALUE 'STANDARD'.
  CONSTANTS transport_piece TYPE string VALUE 'PIECE'.
  CONSTANTS transport_client TYPE string VALUE 'CLIENT'.
  CONSTANTS transport_delivery TYPE string VALUE 'DELIVERY'.
* Individual display accepts every convention the catalog knows.
  CONSTANTS transport_individual TYPE string VALUE 'INDIVIDUAL'.

  TYPES: BEGIN OF ty_transport_request,
           request_id     TYPE string,
           transport_type TYPE string,
           request_type   TYPE string,
           owner          TYPE string,
           short_text     TYPE string,
           status         TYPE string,
           source_system  TYPE string,
           target_system  TYPE string,
           attributes     TYPE string,
           documentation  TYPE string,
           error          TYPE string,
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

* Dictionary object kinds. Each kind keeps its own detail record; unlike kinds
* are never flattened into one generic property dump.
  CONSTANTS ddic_table TYPE string VALUE 'TABLE'.
  CONSTANTS ddic_structure TYPE string VALUE 'STRUCTURE'.
  CONSTANTS ddic_data_element TYPE string VALUE 'DATA_ELEMENT'.
  CONSTANTS ddic_domain TYPE string VALUE 'DOMAIN'.
  CONSTANTS ddic_view TYPE string VALUE 'VIEW'.
  CONSTANTS ddic_search_help TYPE string VALUE 'SEARCH_HELP'.
  CONSTANTS ddic_lock_object TYPE string VALUE 'LOCK_OBJECT'.
  CONSTANTS ddic_table_type TYPE string VALUE 'TABLE_TYPE'.
  CONSTANTS ddic_type_group TYPE string VALUE 'TYPE_GROUP'.

  TYPES: BEGIN OF ty_ddic_field,
           position     TYPE i,
           name         TYPE string,
           key_flag     TYPE abap_bool,
           data_element TYPE string,
           data_type    TYPE string,
           int_type     TYPE string,
           length       TYPE i,
           decimals     TYPE i,
           check_table  TYPE string,
           search_help  TYPE string,
           description  TYPE string,
         END OF ty_ddic_field.
  TYPES ty_ddic_fields TYPE STANDARD TABLE OF ty_ddic_field WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_ddic_fixed_value,
           value       TYPE string,
           description TYPE string,
         END OF ty_ddic_fixed_value.
  TYPES ty_ddic_fixed_values TYPE STANDARD TABLE OF ty_ddic_fixed_value
    WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_ddic_technical,
           data_class    TYPE string,
           size_category TYPE string,
           buffering     TYPE string,
           log_changes   TYPE abap_bool,
         END OF ty_ddic_technical.

  TYPES: BEGIN OF ty_ddic_domain,
           data_type     TYPE string,
           length        TYPE i,
           decimals      TYPE i,
           output_length TYPE i,
           value_table   TYPE string,
           fixed_values  TYPE ty_ddic_fixed_values,
         END OF ty_ddic_domain.

  TYPES: BEGIN OF ty_ddic_data_element,
           domain       TYPE string,
           data_type    TYPE string,
           length       TYPE i,
           decimals     TYPE i,
           short_label  TYPE string,
           medium_label TYPE string,
           long_label   TYPE string,
           heading      TYPE string,
         END OF ty_ddic_data_element.

  TYPES: BEGIN OF ty_ddic_view,
           view_type            TYPE string,
           base_tables          TYPE string_table,
           join_conditions      TYPE string_table,
           selection_conditions TYPE string_table,
         END OF ty_ddic_view.

  TYPES: BEGIN OF ty_ddic_search_help_param,
           name            TYPE string,
           import          TYPE abap_bool,
           export          TYPE abap_bool,
           list_position   TYPE i,
           screen_position TYPE i,
         END OF ty_ddic_search_help_param.
  TYPES ty_ddic_search_help_params TYPE STANDARD TABLE OF
    ty_ddic_search_help_param WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_ddic_search_help,
           selection_method TYPE string,
           dialog_type      TYPE string,
           text_table       TYPE string,
           parameters       TYPE ty_ddic_search_help_params,
         END OF ty_ddic_search_help.

  TYPES: BEGIN OF ty_ddic_lock_parameter,
           name       TYPE string,
           table_name TYPE string,
           field_name TYPE string,
         END OF ty_ddic_lock_parameter.
  TYPES ty_ddic_lock_parameters TYPE STANDARD TABLE OF ty_ddic_lock_parameter
    WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_ddic_lock_object,
           primary_table TYPE string,
           lock_mode     TYPE string,
           parameters    TYPE ty_ddic_lock_parameters,
         END OF ty_ddic_lock_object.

  TYPES: BEGIN OF ty_ddic_table_type,
           line_type   TYPE string,
           access_kind TYPE string,
           key_kind    TYPE string,
           key_fields  TYPE string_table,
         END OF ty_ddic_table_type.

  TYPES: BEGIN OF ty_ddic_type_group,
           source_lines TYPE string_table,
         END OF ty_ddic_type_group.

* One Dictionary object. object_type selects which detail component carries
* meaning; the remaining components stay initial.
  TYPES: BEGIN OF ty_ddic_object,
           object_type    TYPE string,
           name           TYPE string,
           description    TYPE string,
           delivery_class TYPE string,
           fields         TYPE ty_ddic_fields,
           technical      TYPE ty_ddic_technical,
           domain         TYPE ty_ddic_domain,
           data_element   TYPE ty_ddic_data_element,
           view           TYPE ty_ddic_view,
           search_help    TYPE ty_ddic_search_help,
           lock_object    TYPE ty_ddic_lock_object,
           table_type     TYPE ty_ddic_table_type,
           type_group     TYPE ty_ddic_type_group,
           error          TYPE string,
         END OF ty_ddic_object.

* Data Browser criteria. A criterion addresses a field by its Dictionary
* position, never by a browser-supplied field name.
  CONSTANTS operator_eq TYPE string VALUE 'EQ'.
  CONSTANTS operator_bt TYPE string VALUE 'BT'.
  CONSTANTS operator_ne TYPE string VALUE 'NE'.
  CONSTANTS operator_nb TYPE string VALUE 'NB'.

  TYPES: BEGIN OF ty_table_criterion,
           position TYPE i,
           operator TYPE string,
           low      TYPE string,
           high     TYPE string,
           output   TYPE abap_bool,
         END OF ty_table_criterion.
  TYPES ty_table_criterion_rows TYPE STANDARD TABLE OF ty_table_criterion
    WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_table_criteria,
           table_name TYPE string,
           max_rows   TYPE i,
           rows       TYPE ty_table_criterion_rows,
         END OF ty_table_criteria.

* One rendered result cell. position refers to the Dictionary field position,
* value carries the server-formatted representation of that typed field.
  TYPES: BEGIN OF ty_table_cell,
           row      TYPE i,
           position TYPE i,
           value    TYPE string,
         END OF ty_table_cell.
  TYPES ty_table_cells TYPE STANDARD TABLE OF ty_table_cell WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_table_result,
           table_name    TYPE string,
           fields        TYPE ty_ddic_fields,
           cells         TYPE ty_table_cells,
           total_rows    TYPE i,
           returned_rows TYPE i,
           truncated     TYPE abap_bool,
           error         TYPE string,
         END OF ty_table_result.

* Why a program cannot be displayed or executed. The kinds stay distinct so
* the editor never reports a missing program as an unauthorized one.
  CONSTANTS program_active TYPE string VALUE 'ACTIVE'.
  CONSTANTS program_inactive TYPE string VALUE 'INACTIVE'.
  CONSTANTS program_missing TYPE string VALUE 'MISSING'.
  CONSTANTS program_unauthorized TYPE string VALUE 'UNAUTHORIZED'.

  TYPES: BEGIN OF ty_program,
           program       TYPE string,
           status        TYPE string,
           program_type  TYPE string,
           executable    TYPE abap_bool,
           description   TYPE string,
           source_lines  TYPE string_table,
           documentation TYPE string,
           text_elements TYPE string_table,
           error_kind    TYPE string,
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
