INTERFACE zif_gg_report_v1 PUBLIC.

* Normal entry point for an executable report. The runtime calls
* load_of_program, builds and processes the selection screen, then calls
* start_of_selection, optional logical-database events, and end_of_selection
* with one basic-list writer.

  TYPES ty_logical_database TYPE c LENGTH 30.
  TYPES ty_node             TYPE c LENGTH 30.

  "! Called once when the executable program is loaded, before INITIALIZATION.
  METHODS load_of_program.

  "! Logical database assigned to the executable program. An initial result
  "! means that START-OF-SELECTION is followed directly by END-OF-SELECTION.
  "! @parameter rv_logical_database | assigned logical database, if any
  METHODS get_logical_database
    RETURNING
      VALUE(rv_logical_database) TYPE ty_logical_database.

  "! Supply optional classic-list event handling and page settings. The
  "! returned reference may be initial when the report handles no list events.
  "! @parameter ro_list_processing | classic-list event handler, if any
  METHODS get_list_processing
    RETURNING
      VALUE(ro_list_processing) TYPE REF TO zif_gg_list_processing_v1.

  "! Describe the selection screen, called once before it is rendered.
  "! Corresponds to the PARAMETERS, SELECT-OPTIONS and SELECTION-SCREEN
  "! declarations of a classic report.
  "! @parameter io_builder | receives the declarations in rendering order
  METHODS build_screen
    IMPORTING
      io_builder TYPE REF TO zif_gg_selection_screen_builder_v1.

  "! Set up the initial values, corresponds to INITIALIZATION.
  "! Called once after build_screen, before the first rendering.
  "! @parameter ct_values | values initialized from the screen definition
  METHODS initialization
    CHANGING
      ct_values TYPE zif_gg_selection_screen_types=>ty_values.

  "! Adjust the screen before each rendering, corresponds to
  "! AT SELECTION-SCREEN OUTPUT. This is where LOOP AT SCREEN would go.
  "! @parameter iv_screen | active selection-screen number, ie sy-dynnr
  "! @parameter it_values | current input values
  "! @parameter ct_states | current presentation state, change visible,
  "!                        enabled, obligatory, text or fixed_values
  METHODS at_selection_screen_output
    IMPORTING
      iv_screen TYPE zif_gg_selection_screen_types=>ty_screen_number
      it_values TYPE zif_gg_selection_screen_types=>ty_values
    CHANGING
      ct_states TYPE zif_gg_selection_screen_types=>ty_states.

  "! Validate the screen as a whole, corresponds to AT SELECTION-SCREEN.
  "! Called after all field level events, and for every function code
  "! raised by a pushbutton.
  "! @parameter iv_screen   | active selection-screen number, ie sy-dynnr
  "! @parameter iv_ucomm    | function code that triggered the event, the
  "!                          name of the pushbutton, or initial
  "! @parameter it_values   | current user input
  "! @parameter rt_messages | messages to display, an entry of type
  "!                          message_type_error keeps the screen open
  METHODS at_selection_screen
    IMPORTING
      iv_screen          TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_ucomm           TYPE zif_gg_selection_screen_types=>ty_ucomm
      it_values          TYPE zif_gg_selection_screen_types=>ty_values
    RETURNING
      VALUE(rt_messages) TYPE zif_gg_selection_screen_types=>ty_messages.

  "! Validate a single field, corresponds to
  "! AT SELECTION-SCREEN ON <field>.
  "! @parameter iv_screen   | active selection-screen number, ie sy-dynnr
  "! @parameter iv_name     | name of the element that was left
  "! @parameter it_values   | current user input
  "! @parameter rt_messages | messages to display, an entry of type
  "!                          message_type_error keeps the screen open
  METHODS at_selection_screen_on_field
    IMPORTING
      iv_screen          TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_name            TYPE zif_gg_selection_screen_types=>ty_name
      it_values          TYPE zif_gg_selection_screen_types=>ty_values
    RETURNING
      VALUE(rt_messages) TYPE zif_gg_selection_screen_types=>ty_messages.

  "! Validate a complete SELECT-OPTIONS, corresponds to
  "! AT SELECTION-SCREEN ON END OF <field>. Called once all rows of the
  "! multiple selection dialog have been entered.
  "! @parameter iv_screen   | active selection-screen number, ie sy-dynnr
  "! @parameter iv_name     | name of the select-option
  "! @parameter it_values   | current user input
  "! @parameter rt_messages | messages to display, an entry of type
  "!                          message_type_error keeps the screen open
  METHODS at_selection_screen_on_end_of
    IMPORTING
      iv_screen          TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_name            TYPE zif_gg_selection_screen_types=>ty_name
      it_values          TYPE zif_gg_selection_screen_types=>ty_values
    RETURNING
      VALUE(rt_messages) TYPE zif_gg_selection_screen_types=>ty_messages.

  "! Validate all fields of one block, corresponds to
  "! AT SELECTION-SCREEN ON BLOCK <block>.
  "! @parameter iv_screen   | active selection-screen number, ie sy-dynnr
  "! @parameter iv_block    | name passed to begin_block
  "! @parameter it_values   | current user input
  "! @parameter rt_messages | messages to display, an entry of type
  "!                          message_type_error keeps the screen open
  METHODS at_selection_screen_on_block
    IMPORTING
      iv_screen          TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_block           TYPE zif_gg_selection_screen_types=>ty_name
      it_values          TYPE zif_gg_selection_screen_types=>ty_values
    RETURNING
      VALUE(rt_messages) TYPE zif_gg_selection_screen_types=>ty_messages.

  "! Validate a radiobutton group, corresponds to
  "! AT SELECTION-SCREEN ON RADIOBUTTON GROUP <group>.
  "! @parameter iv_screen   | active selection-screen number, ie sy-dynnr
  "! @parameter iv_group    | the radio_group of the elements involved
  "! @parameter it_values   | current user input
  "! @parameter rt_messages | messages to display, an entry of type
  "!                          message_type_error keeps the screen open
  METHODS at_selection_screen_on_radio
    IMPORTING
      iv_screen          TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_group           TYPE zif_gg_selection_screen_types=>ty_group
      it_values          TYPE zif_gg_selection_screen_types=>ty_values
    RETURNING
      VALUE(rt_messages) TYPE zif_gg_selection_screen_types=>ty_messages.

  "! Supply the input help for a field, corresponds to
  "! AT SELECTION-SCREEN ON VALUE-REQUEST FOR <field>, ie F4. Only called
  "! for elements flagged with value_help.
  "! @parameter iv_screen | active selection-screen number, ie sy-dynnr
  "! @parameter iv_name     | name of the element the help was requested for
  "! @parameter it_values   | current user input
  "! @parameter rt_values   | the picked values, empty if the user cancelled,
  "!                          one row for a parameter, more for a
  "!                          select-option
  METHODS at_selection_screen_value_req
    IMPORTING
      iv_screen        TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_name          TYPE zif_gg_selection_screen_types=>ty_name
      it_values        TYPE zif_gg_selection_screen_types=>ty_values
    RETURNING
      VALUE(rt_values) TYPE zif_gg_selection_screen_types=>ty_ranges.

  "! Supply the documentation for a field, corresponds to
  "! AT SELECTION-SCREEN ON HELP-REQUEST FOR <field>, ie F1.
  "! @parameter iv_screen | active selection-screen number, ie sy-dynnr
  "! @parameter iv_name     | name of the element the help was requested for
  "! @parameter it_values   | current user input
  "! @parameter rv_text     | text to display, empty to fall back to the
  "!                          help of the underlying data element
  METHODS at_selection_screen_help_req
    IMPORTING
      iv_screen      TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_name        TYPE zif_gg_selection_screen_types=>ty_name
      it_values      TYPE zif_gg_selection_screen_types=>ty_values
    RETURNING
      VALUE(rv_text) TYPE string.

  "! The user left the screen without executing it, corresponds to
  "! AT SELECTION-SCREEN ON EXIT-COMMAND. Values are the program values from
  "! before PAI transport; no further selection-screen method is called.
  "! @parameter iv_screen | active selection-screen number, ie sy-dynnr
  "! @parameter iv_ucomm  | exit function code, such as Back, Exit or Cancel
  "! @parameter it_values | values available before input transport
  METHODS at_selection_screen_on_exit
    IMPORTING
      iv_screen TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_ucomm  TYPE zif_gg_selection_screen_types=>ty_ucomm
      it_values TYPE zif_gg_selection_screen_types=>ty_values.

  "! Run the program, corresponds to START-OF-SELECTION. Called once the
  "! screen has been validated without errors. All output is appended to the
  "! basic list represented by io_writer.
  "! @parameter it_values | values confirmed by the user
  "! @parameter io_writer | basic-list output and layout operations
  "! @parameter rv_stop   | abap_true models STOP and skips to END-OF-SELECTION
  METHODS start_of_selection
    IMPORTING
      it_values      TYPE zif_gg_selection_screen_types=>ty_values
      io_writer      TYPE REF TO zif_gg_list_writer_v1
    RETURNING
      VALUE(rv_stop) TYPE abap_bool.

  "! Corresponds to GET <node> while a logical database supplies records.
  "! ir_record points to the typed node work area owned by the runtime.
  "! @parameter iv_node   | logical-database node name
  "! @parameter ir_record | current typed node work area
  "! @parameter io_writer | same basic-list writer used by report events
  "! @parameter rv_stop   | abap_true models STOP and skips to END-OF-SELECTION
  METHODS at_get
    IMPORTING
      iv_node        TYPE ty_node
      ir_record      TYPE REF TO data
      io_writer      TYPE REF TO zif_gg_list_writer_v1
    RETURNING
      VALUE(rv_stop) TYPE abap_bool.

  "! Corresponds to GET <node> LATE after subordinate nodes were processed.
  "! @parameter iv_node   | logical-database node name
  "! @parameter ir_record | current typed node work area
  "! @parameter io_writer | same basic-list writer used by report events
  "! @parameter rv_stop   | abap_true models STOP and skips to END-OF-SELECTION
  METHODS at_get_late
    IMPORTING
      iv_node        TYPE ty_node
      ir_record      TYPE REF TO data
      io_writer      TYPE REF TO zif_gg_list_writer_v1
    RETURNING
      VALUE(rv_stop) TYPE abap_bool.

  "! Called after start_of_selection, corresponds to END-OF-SELECTION. It
  "! continues writing to the same basic list.
  "! @parameter it_values | values confirmed by the user
  "! @parameter io_writer | same writer passed to start_of_selection
  METHODS end_of_selection
    IMPORTING
      it_values TYPE zif_gg_selection_screen_types=>ty_values
      io_writer TYPE REF TO zif_gg_list_writer_v1.

ENDINTERFACE.
