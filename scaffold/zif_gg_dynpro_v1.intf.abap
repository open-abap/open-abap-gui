INTERFACE zif_gg_dynpro_v1 PUBLIC.

* Implement this in a dialog program. build_screens declares screen elements;
* build_flow_logic declares ordered PBO, PAI, POV and POH processing. The
* runtime transports fields and invokes the module callbacks in that order.

  "! Screen entered when the dialog program starts.
  "! @parameter rv_screen | initial dynpro number
  METHODS get_initial_screen
    RETURNING
      VALUE(rv_screen) TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

  "! Describe every dynpro once, in screen-number and rendering order.
  "! @parameter io_builder | receives screens and their typed controls
  METHODS build_screens
    IMPORTING
      io_builder TYPE REF TO zif_gg_dynpro_builder_v1.

  "! Declare each screen's ordered flow logic. The runtime validates block
  "! nesting and performs automatic type, required and value checks at FIELD
  "! instructions before invoking the following input modules.
  "! @parameter io_builder | receives PBO, PAI, POV and POH instructions
  METHODS build_flow_logic
    IMPORTING
      io_builder TYPE REF TO zif_gg_dynpro_flow_builder_v1.

  "! Initialize program fields after the definitions have been built.
  "! @parameter ct_values | values seeded from all screen definitions
  METHODS initialization
    CHANGING
      ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.

  "! Execute one MODULE in PROCESS BEFORE OUTPUT. For table-control loops,
  "! is_context supplies the absolute row, sy-stepl and sy-loopc equivalents.
  "! @parameter is_context     | screen, module, field and loop context
  "! @parameter ct_values      | program data transported to the screen
  "! @parameter ct_states      | mutable SCREEN-like control state
  "! @parameter cs_screen_state | title, status, cursor and next screen
  METHODS process_output_module
    IMPORTING
      is_context      TYPE zif_gg_dynpro_types_v1=>ty_module_context
    CHANGING
      ct_values       TYPE zif_gg_dynpro_types_v1=>ty_values
      ct_states       TYPE zif_gg_dynpro_types_v1=>ty_states
      cs_screen_state TYPE zif_gg_dynpro_types_v1=>ty_screen_state.

  "! Execute one MODULE in PROCESS AFTER INPUT. FIELD and CHAIN transport is
  "! performed by the runtime immediately before the position declared in
  "! build_flow_logic. Error or warning messages stop the remaining PAI flow
  "! and reactivate the current field or complete chain.
  "! @parameter is_context | screen, module, field, command and loop context
  "! @parameter ct_values  | program data transported according to flow logic
  "! @parameter cs_result  | message and SET/LEAVE/CALL SCREEN navigation
  METHODS process_input_module
    IMPORTING
      is_context TYPE zif_gg_dynpro_types_v1=>ty_module_context
    CHANGING
      ct_values  TYPE zif_gg_dynpro_types_v1=>ty_values
      cs_result  TYPE zif_gg_dynpro_types_v1=>ty_result.

  "! Execute the MODULE declared in PROCESS ON VALUE-REQUEST.
  "! @parameter is_context | screen, module, requested field and row
  "! @parameter it_values  | current program data
  "! @parameter rt_values  | picked values; empty means cancelled
  METHODS process_on_value_request
    IMPORTING
      is_context       TYPE zif_gg_dynpro_types_v1=>ty_module_context
      it_values        TYPE zif_gg_dynpro_types_v1=>ty_values
    RETURNING
      VALUE(rt_values) TYPE zif_gg_dynpro_types_v1=>ty_values.

  "! Execute the MODULE declared in PROCESS ON HELP-REQUEST.
  "! @parameter is_context | screen, module, requested field and row
  "! @parameter it_values  | current program data
  "! @parameter rv_text    | help text; empty selects the default help
  METHODS process_on_help_request
    IMPORTING
      is_context     TYPE zif_gg_dynpro_types_v1=>ty_module_context
      it_values      TYPE zif_gg_dynpro_types_v1=>ty_values
    RETURNING
      VALUE(rv_text) TYPE string.

ENDINTERFACE.
