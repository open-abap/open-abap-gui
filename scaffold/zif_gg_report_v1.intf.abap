INTERFACE zif_gg_report_v1 PUBLIC.

* Normal entry point for an executable report. Every event callback receives
* the same execution-scoped session. The list writer, MESSAGE, STOP and dialog
* transfers are operations of that session rather than returned effects.
*
* Events that run while a selection screen is still being processed receive
* ct_values as CHANGING, matching the global program fields behind PARAMETERS
* and SELECT-OPTIONS. Changes made in at_selection_screen_output are
* transported to the screen and displayed; changes made in the PAI events stay
* in the program and reach the screen only if it is displayed again. The PAI
* events run in the order on_field, on_end_of, on_block, on_radio and finally
* at_selection_screen, each seeing the changes made by the previous ones.

  TYPES ty_logical_database TYPE c LENGTH 30.
  TYPES ty_node             TYPE c LENGTH 30.

  "! Called once when the executable program is loaded, before INITIALIZATION.
  METHODS load_of_program
    IMPORTING
      io_session TYPE REF TO zif_gg_session_v1.

  "! Logical database assigned to the executable program. An initial result
  "! means that START-OF-SELECTION is followed directly by END-OF-SELECTION.
  METHODS get_logical_database
    IMPORTING
      io_session                 TYPE REF TO zif_gg_session_v1
    RETURNING
      VALUE(rv_logical_database) TYPE ty_logical_database.

  "! Supply optional classic-list event handling and page settings.
  METHODS get_list_processing
    IMPORTING
      io_session                TYPE REF TO zif_gg_session_v1
    RETURNING
      VALUE(ro_list_processing) TYPE REF TO zif_gg_list_processing_v1.

  "! Describe the selection screens once, in rendering order.
  METHODS build_screen
    IMPORTING
      io_builder TYPE REF TO zif_gg_selection_screen_builder_v1.

  "! Corresponds to INITIALIZATION. ct_values already holds the defaults
  "! declared in the screen definition.
  METHODS initialization
    IMPORTING
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_selection_screen_types=>ty_values.

  "! Corresponds to AT SELECTION-SCREEN OUTPUT.
  METHODS at_selection_screen_output
    IMPORTING
      iv_screen  TYPE zif_gg_selection_screen_types=>ty_screen_number
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_selection_screen_types=>ty_values
      ct_states  TYPE zif_gg_selection_screen_types=>ty_states.

  "! Corresponds to AT SELECTION-SCREEN, the last event of the screen's PAI.
  "! MESSAGE and dialog control are performed through io_session.
  METHODS at_selection_screen
    IMPORTING
      iv_screen  TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_ucomm   TYPE zif_gg_selection_screen_types=>ty_ucomm
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_selection_screen_types=>ty_values.

  "! Corresponds to AT SELECTION-SCREEN ON <field>.
  METHODS at_selection_screen_on_field
    IMPORTING
      iv_screen  TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_name    TYPE zif_gg_selection_screen_types=>ty_name
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_selection_screen_types=>ty_values.

  "! Corresponds to AT SELECTION-SCREEN ON END OF <field>.
  METHODS at_selection_screen_on_end_of
    IMPORTING
      iv_screen  TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_name    TYPE zif_gg_selection_screen_types=>ty_name
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_selection_screen_types=>ty_values.

  "! Corresponds to AT SELECTION-SCREEN ON BLOCK <block>.
  METHODS at_selection_screen_on_block
    IMPORTING
      iv_screen  TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_block   TYPE zif_gg_selection_screen_types=>ty_name
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_selection_screen_types=>ty_values.

  "! Corresponds to AT SELECTION-SCREEN ON RADIOBUTTON GROUP <group>.
  METHODS at_selection_screen_on_radio
    IMPORTING
      iv_screen  TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_group   TYPE zif_gg_selection_screen_types=>ty_group
      io_session TYPE REF TO zif_gg_session_v1
    CHANGING
      ct_values  TYPE zif_gg_selection_screen_types=>ty_values.

  "! Corresponds to AT SELECTION-SCREEN ON VALUE-REQUEST FOR <field>.
  METHODS at_selection_screen_value_req
    IMPORTING
      iv_screen        TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_name          TYPE zif_gg_selection_screen_types=>ty_name
      it_values        TYPE zif_gg_selection_screen_types=>ty_values
      io_session       TYPE REF TO zif_gg_session_v1
    RETURNING
      VALUE(rt_values) TYPE zif_gg_selection_screen_types=>ty_ranges.

  "! Corresponds to AT SELECTION-SCREEN ON HELP-REQUEST FOR <field>.
  METHODS at_selection_screen_help_req
    IMPORTING
      iv_screen      TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_name        TYPE zif_gg_selection_screen_types=>ty_name
      it_values      TYPE zif_gg_selection_screen_types=>ty_values
      io_session     TYPE REF TO zif_gg_session_v1
    RETURNING
      VALUE(rv_text) TYPE string.

  "! Corresponds to AT SELECTION-SCREEN ON EXIT-COMMAND. Values are those
  "! available before PAI input transport.
  METHODS at_selection_screen_on_exit
    IMPORTING
      iv_screen  TYPE zif_gg_selection_screen_types=>ty_screen_number
      iv_ucomm   TYPE zif_gg_selection_screen_types=>ty_ucomm
      it_values  TYPE zif_gg_selection_screen_types=>ty_values
      io_session TYPE REF TO zif_gg_session_v1.

  "! Corresponds to START-OF-SELECTION. Use the session's list writer for
  "! output and io_session->stop( ) for STOP.
  METHODS start_of_selection
    IMPORTING
      it_values  TYPE zif_gg_selection_screen_types=>ty_values
      io_session TYPE REF TO zif_gg_session_v1.

  "! Corresponds to GET <node> while a logical database supplies records.
  METHODS at_get
    IMPORTING
      iv_node    TYPE ty_node
      ir_record  TYPE REF TO data
      io_session TYPE REF TO zif_gg_session_v1.

  "! Corresponds to GET <node> LATE.
  METHODS at_get_late
    IMPORTING
      iv_node    TYPE ty_node
      ir_record  TYPE REF TO data
      io_session TYPE REF TO zif_gg_session_v1.

  "! Corresponds to END-OF-SELECTION and continues the current basic list.
  METHODS end_of_selection
    IMPORTING
      it_values  TYPE zif_gg_selection_screen_types=>ty_values
      io_session TYPE REF TO zif_gg_session_v1.

ENDINTERFACE.
