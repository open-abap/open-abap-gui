INTERFACE zif_gg_dynpro_v1 PUBLIC.

* Implement this in a dialog program. build_screens describes its dynpros;
* the other methods correspond to the classic dynpro processing blocks.

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

  "! Initialize program fields after the definitions have been built.
  "! @parameter ct_values | values seeded from all screen definitions
  METHODS initialization
    CHANGING
      ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.

  "! Corresponds to PROCESS BEFORE OUTPUT for the screen being displayed.
  "! @parameter iv_screen       | current dynpro number
  "! @parameter it_values       | current program data
  "! @parameter ct_states       | mutable SCREEN-like control state
  "! @parameter cs_screen_state | title, status, cursor and next screen
  METHODS process_before_output
    IMPORTING
      iv_screen       TYPE zif_gg_dynpro_types_v1=>ty_screen_number
      it_values       TYPE zif_gg_dynpro_types_v1=>ty_values
    CHANGING
      ct_states       TYPE zif_gg_dynpro_types_v1=>ty_states
      cs_screen_state TYPE zif_gg_dynpro_types_v1=>ty_screen_state.

  "! Corresponds to PROCESS AFTER INPUT. The method may normalize values,
  "! report field errors, or request SET/LEAVE/CALL SCREEN navigation.
  "! @parameter iv_screen       | current dynpro number
  "! @parameter iv_ucomm        | function code from the OK field
  "! @parameter iv_cursor_field | field containing the cursor
  "! @parameter iv_cursor_row   | current table-control row, or zero
  "! @parameter ct_values       | transported program data
  "! @parameter cs_result       | messages and requested navigation
  METHODS process_after_input
    IMPORTING
      iv_screen       TYPE zif_gg_dynpro_types_v1=>ty_screen_number
      iv_ucomm        TYPE zif_gg_dynpro_types_v1=>ty_ucomm
      iv_cursor_field TYPE zif_gg_dynpro_types_v1=>ty_name
      iv_cursor_row   TYPE i
    CHANGING
      ct_values       TYPE zif_gg_dynpro_types_v1=>ty_values
      cs_result       TYPE zif_gg_dynpro_types_v1=>ty_result.

  "! Corresponds to PROCESS ON VALUE-REQUEST for a field.
  "! @parameter iv_screen | current dynpro number
  "! @parameter iv_name   | field requesting F4 help
  "! @parameter iv_row    | table-control row, or zero
  "! @parameter it_values | current program data
  "! @parameter rt_values | picked values; empty means cancelled
  METHODS process_on_value_request
    IMPORTING
      iv_screen        TYPE zif_gg_dynpro_types_v1=>ty_screen_number
      iv_name          TYPE zif_gg_dynpro_types_v1=>ty_name
      iv_row           TYPE i
      it_values        TYPE zif_gg_dynpro_types_v1=>ty_values
    RETURNING
      VALUE(rt_values) TYPE zif_gg_dynpro_types_v1=>ty_values.

  "! Corresponds to PROCESS ON HELP-REQUEST for a field.
  "! @parameter iv_screen | current dynpro number
  "! @parameter iv_name   | field requesting F1 help
  "! @parameter iv_row    | table-control row, or zero
  "! @parameter it_values | current program data
  "! @parameter rv_text   | help text; empty selects the default help
  METHODS process_on_help_request
    IMPORTING
      iv_screen      TYPE zif_gg_dynpro_types_v1=>ty_screen_number
      iv_name        TYPE zif_gg_dynpro_types_v1=>ty_name
      iv_row         TYPE i
      it_values      TYPE zif_gg_dynpro_types_v1=>ty_values
    RETURNING
      VALUE(rv_text) TYPE string.

ENDINTERFACE.
