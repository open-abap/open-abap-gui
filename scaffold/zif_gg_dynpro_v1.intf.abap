INTERFACE zif_gg_dynpro_v1 PUBLIC.

* Entry point for a dialog program. Builders declare the screens and ordered
* flow logic; module callbacks use one execution-scoped imperative session.

  "! Screen entered when the dialog program starts.
  METHODS get_initial_screen
    RETURNING
      VALUE(rv_screen) TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

  "! Describe every dynpro once, in screen-number and rendering order.
  METHODS build_screens
    IMPORTING
      io_builder TYPE REF TO zif_gg_dynpro_builder_v1.

  "! Declare ordered PBO, PAI, POV and POH flow logic.
  METHODS build_flow_logic
    IMPORTING
      io_builder TYPE REF TO zif_gg_dynpro_flow_builder_v1.

  "! Initialize program fields after the definitions have been built.
  METHODS initialization
    IMPORTING
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_dynpro_types_v1=>ty_values.

  "! Execute one MODULE in PROCESS BEFORE OUTPUT. SET PF-STATUS, SET TITLEBAR,
  "! SET CURSOR and SET SCREEN are operations of io_session->get_dialog( ).
  METHODS process_output_module
    IMPORTING
      is_context TYPE zif_gg_dynpro_types_v1=>ty_module_context
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_dynpro_types_v1=>ty_values
      ct_states  TYPE zif_gg_dynpro_types_v1=>ty_states.

  "! Execute one MODULE in PROCESS AFTER INPUT. MESSAGE and all screen
  "! transfers are operations of io_session.
  METHODS process_input_module
    IMPORTING
      is_context TYPE zif_gg_dynpro_types_v1=>ty_module_context
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_dynpro_types_v1=>ty_values.

  "! Execute the MODULE declared in PROCESS ON VALUE-REQUEST.
  METHODS process_on_value_request
    IMPORTING
      is_context       TYPE zif_gg_dynpro_types_v1=>ty_module_context
      it_values        TYPE zif_gg_dynpro_types_v1=>ty_values
      io_session       TYPE REF TO zif_gg_session_v1
    RETURNING
      VALUE(rt_values) TYPE zif_gg_dynpro_types_v1=>ty_values.

  "! Execute the MODULE declared in PROCESS ON HELP-REQUEST.
  METHODS process_on_help_request
    IMPORTING
      is_context     TYPE zif_gg_dynpro_types_v1=>ty_module_context
      it_values      TYPE zif_gg_dynpro_types_v1=>ty_values
      io_session     TYPE REF TO zif_gg_session_v1
    RETURNING
      VALUE(rv_text) TYPE string.

ENDINTERFACE.
