INTERFACE zif_gg_screen_provider_v1 PUBLIC.

* Auxiliary screen contract for an executable report. A report may implement
* this interface in addition to zif_gg_report_v1; it must not implement
* zif_gg_dynpro_v1 directly because the transaction registry uses those two
* interfaces to select the executable application kind.
*
* zcl_gg_host_report_dynpro adapts this contract to the existing dynpro host
* at a CALL SCREEN boundary. Keeping the provider on the report preserves the
* report's private state while the registry continues to classify the object
* as REPORT.

  METHODS get_initial_screen
    RETURNING
      VALUE(rv_screen) TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

  METHODS build_screens
    IMPORTING
      io_builder TYPE REF TO zif_gg_dynpro_builder_v1.

  METHODS build_flow_logic
    IMPORTING
      io_builder TYPE REF TO zif_gg_dynpro_flow_builder_v1.

  METHODS initialization
    IMPORTING
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_dynpro_types_v1=>ty_values.

  METHODS process_output_module
    IMPORTING
      is_context TYPE zif_gg_dynpro_types_v1=>ty_module_context
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_dynpro_types_v1=>ty_values
      ct_states  TYPE zif_gg_dynpro_types_v1=>ty_states.

  METHODS process_input_module
    IMPORTING
      is_context TYPE zif_gg_dynpro_types_v1=>ty_module_context
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_dynpro_types_v1=>ty_values.

  METHODS process_on_value_request
    IMPORTING
      is_context       TYPE zif_gg_dynpro_types_v1=>ty_module_context
      it_values        TYPE zif_gg_dynpro_types_v1=>ty_values
      io_session       TYPE REF TO zif_gg_session_v1
    RETURNING
      VALUE(rt_values) TYPE zif_gg_dynpro_types_v1=>ty_values.

  METHODS process_on_help_request
    IMPORTING
      is_context     TYPE zif_gg_dynpro_types_v1=>ty_module_context
      it_values      TYPE zif_gg_dynpro_types_v1=>ty_values
      io_session     TYPE REF TO zif_gg_session_v1
    RETURNING
      VALUE(rv_text) TYPE string.

ENDINTERFACE.
