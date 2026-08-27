INTERFACE zif_gg_selection_screen_v1 PUBLIC.

* Implement this in a program with a selection screen: get() describes the
* screen, the remaining methods correspond to the events raised while it is
* processed. All types and constants live in zif_gg_selection_screen_types,
* which is shared across versions of this interface

  "! Describe the selection screen, called once before it is rendered.
  "! Corresponds to the PARAMETERS, SELECT-OPTIONS and SELECTION-SCREEN
  "! declarations of a classic report.
  "! @parameter rt_elements | all elements, in the sequence they are rendered
  METHODS get
    RETURNING
      VALUE(rt_elements) TYPE zif_gg_selection_screen_types=>ty_elements.

  "! Set up the initial values, corresponds to INITIALIZATION.
  "! Called once after get(), before the screen is rendered the first time.
  "! @parameter ct_elements | elements as returned by get(), change value,
  "!                          ranges, text or fixed_values to set defaults
  METHODS initialization
    CHANGING
      ct_elements TYPE zif_gg_selection_screen_types=>ty_elements.

  "! Adjust the screen before each rendering, corresponds to
  "! AT SELECTION-SCREEN OUTPUT. This is where LOOP AT SCREEN would go.
  "! @parameter ct_elements | current elements, change visible, enabled,
  "!                          obligatory or text to modify the screen
  METHODS at_selection_screen_output
    CHANGING
      ct_elements TYPE zif_gg_selection_screen_types=>ty_elements.

  "! Validate the screen as a whole, corresponds to AT SELECTION-SCREEN.
  "! Called after all field level events, and for every function code
  "! raised by a pushbutton.
  "! @parameter iv_ucomm    | function code that triggered the event, the
  "!                          name of the pushbutton, or initial
  "! @parameter it_elements | current elements, including user input
  "! @parameter rt_messages | messages to display, an entry of type
  "!                          message_type_error keeps the screen open
  METHODS at_selection_screen
    IMPORTING
      iv_ucomm           TYPE zif_gg_selection_screen_types=>ty_ucomm
      it_elements        TYPE zif_gg_selection_screen_types=>ty_elements
    RETURNING
      VALUE(rt_messages) TYPE zif_gg_selection_screen_types=>ty_messages.

  "! Validate a single field, corresponds to
  "! AT SELECTION-SCREEN ON <field>.
  "! @parameter iv_name     | name of the element that was left
  "! @parameter it_elements | current elements, including user input
  "! @parameter rt_messages | messages to display, an entry of type
  "!                          message_type_error keeps the screen open
  METHODS at_selection_screen_on_field
    IMPORTING
      iv_name            TYPE zif_gg_selection_screen_types=>ty_name
      it_elements        TYPE zif_gg_selection_screen_types=>ty_elements
    RETURNING
      VALUE(rt_messages) TYPE zif_gg_selection_screen_types=>ty_messages.

  "! Validate a complete SELECT-OPTIONS, corresponds to
  "! AT SELECTION-SCREEN ON END OF <field>. Called once all rows of the
  "! multiple selection dialog have been entered.
  "! @parameter iv_name     | name of the select-option
  "! @parameter it_elements | current elements, including user input
  "! @parameter rt_messages | messages to display, an entry of type
  "!                          message_type_error keeps the screen open
  METHODS at_selection_screen_on_end_of
    IMPORTING
      iv_name            TYPE zif_gg_selection_screen_types=>ty_name
      it_elements        TYPE zif_gg_selection_screen_types=>ty_elements
    RETURNING
      VALUE(rt_messages) TYPE zif_gg_selection_screen_types=>ty_messages.

  "! Validate all fields of one block, corresponds to
  "! AT SELECTION-SCREEN ON BLOCK <block>.
  "! @parameter iv_block    | name of the block, as given on kind_block_begin
  "! @parameter it_elements | current elements, including user input
  "! @parameter rt_messages | messages to display, an entry of type
  "!                          message_type_error keeps the screen open
  METHODS at_selection_screen_on_block
    IMPORTING
      iv_block           TYPE zif_gg_selection_screen_types=>ty_name
      it_elements        TYPE zif_gg_selection_screen_types=>ty_elements
    RETURNING
      VALUE(rt_messages) TYPE zif_gg_selection_screen_types=>ty_messages.

  "! Validate a radiobutton group, corresponds to
  "! AT SELECTION-SCREEN ON RADIOBUTTON GROUP <group>.
  "! @parameter iv_group    | the radio_group of the elements involved
  "! @parameter it_elements | current elements, including user input
  "! @parameter rt_messages | messages to display, an entry of type
  "!                          message_type_error keeps the screen open
  METHODS at_selection_screen_on_radio
    IMPORTING
      iv_group           TYPE zif_gg_selection_screen_types=>ty_group
      it_elements        TYPE zif_gg_selection_screen_types=>ty_elements
    RETURNING
      VALUE(rt_messages) TYPE zif_gg_selection_screen_types=>ty_messages.

  "! Supply the input help for a field, corresponds to
  "! AT SELECTION-SCREEN ON VALUE-REQUEST FOR <field>, ie F4. Only called
  "! for elements flagged with value_help.
  "! @parameter iv_name     | name of the element the help was requested for
  "! @parameter it_elements | current elements, including user input
  "! @parameter rt_values   | the picked values, empty if the user cancelled,
  "!                          one row for a parameter, more for a
  "!                          select-option
  METHODS at_selection_screen_value_req
    IMPORTING
      iv_name          TYPE zif_gg_selection_screen_types=>ty_name
      it_elements      TYPE zif_gg_selection_screen_types=>ty_elements
    RETURNING
      VALUE(rt_values) TYPE zif_gg_selection_screen_types=>ty_ranges.

  "! Supply the documentation for a field, corresponds to
  "! AT SELECTION-SCREEN ON HELP-REQUEST FOR <field>, ie F1.
  "! @parameter iv_name     | name of the element the help was requested for
  "! @parameter it_elements | current elements, including user input
  "! @parameter rv_text     | text to display, empty to fall back to the
  "!                          help of the underlying data element
  METHODS at_selection_screen_help_req
    IMPORTING
      iv_name        TYPE zif_gg_selection_screen_types=>ty_name
      it_elements    TYPE zif_gg_selection_screen_types=>ty_elements
    RETURNING
      VALUE(rv_text) TYPE string.

  "! The user left the screen without executing it, corresponds to
  "! AT SELECTION-SCREEN ON EXIT-COMMAND. No further method is called.
  METHODS at_selection_screen_on_exit.

  "! Run the program, corresponds to START-OF-SELECTION. Called once the
  "! screen has been validated without errors.
  "! @parameter it_elements | the elements as confirmed by the user
  METHODS start_of_selection
    IMPORTING
      it_elements TYPE zif_gg_selection_screen_types=>ty_elements.

  "! Called after start_of_selection, corresponds to END-OF-SELECTION.
  METHODS end_of_selection.

ENDINTERFACE.
