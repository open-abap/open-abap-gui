INTERFACE zif_gg_session_types_v1 PUBLIC.

* Versioned vocabulary for one imperative internal-session execution. Context
* is grouped by processor so callbacks do not receive one growing flat bag of
* sy-* fields.

  TYPES ty_processor     TYPE string.
  TYPES ty_event         TYPE string.
  TYPES ty_program       TYPE c LENGTH 40.
  TYPES ty_name          TYPE c LENGTH 30.
  TYPES ty_ucomm         TYPE c LENGTH 70.
  TYPES ty_message_type  TYPE c LENGTH 1.
  TYPES ty_continuation_id TYPE string.

  CONSTANTS processor_report    TYPE ty_processor VALUE 'REPORT'.
  CONSTANTS processor_selection TYPE ty_processor VALUE 'SELECTION'.
  CONSTANTS processor_dynpro    TYPE ty_processor VALUE 'DYNPRO'.
  CONSTANTS processor_list      TYPE ty_processor VALUE 'LIST'.

  CONSTANTS message_type_error   TYPE ty_message_type VALUE 'E'.
  CONSTANTS message_type_warning TYPE ty_message_type VALUE 'W'.
  CONSTANTS message_type_info    TYPE ty_message_type VALUE 'I'.
  CONSTANTS message_type_success TYPE ty_message_type VALUE 'S'.

  TYPES ty_ucomms TYPE STANDARD TABLE OF ty_ucomm WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_program_context,
           program TYPE ty_program,
           event   TYPE ty_event,
           batch   TYPE abap_bool,
         END OF ty_program_context.

  TYPES: BEGIN OF ty_selection_context,
           active TYPE abap_bool,
           screen TYPE zif_gg_selection_screen_types=>ty_screen_number,
           ucomm  TYPE zif_gg_selection_screen_types=>ty_ucomm,
           subrc  TYPE i,
         END OF ty_selection_context.

  TYPES: BEGIN OF ty_dynpro_context,
           active       TYPE abap_bool,
           program      TYPE zif_gg_dynpro_types_v1=>ty_program,
           screen       TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
           ucomm        TYPE zif_gg_dynpro_types_v1=>ty_ucomm,
           cursor_field TYPE zif_gg_dynpro_types_v1=>ty_name,
           cursor_row   TYPE i,
           loop_index   TYPE i,
           loop_lines   TYPE i,
         END OF ty_dynpro_context.

  TYPES: BEGIN OF ty_list_context,
           active TYPE abap_bool,
           level  TYPE i,
           page   TYPE i,
           line   TYPE i,
           column TYPE i,
           ucomm  TYPE zif_gg_list_processing_types_v1=>ty_ucomm,
         END OF ty_list_context.

  TYPES: BEGIN OF ty_context,
           processor TYPE ty_processor,
           program   TYPE ty_program_context,
           selection TYPE ty_selection_context,
           dynpro    TYPE ty_dynpro_context,
           list      TYPE ty_list_context,
         END OF ty_context.

  TYPES: BEGIN OF ty_modal_position,
           start_row    TYPE i,
           start_column TYPE i,
           end_row      TYPE i,
           end_column   TYPE i,
         END OF ty_modal_position.

* An initial program means the current dialog program.
  TYPES: BEGIN OF ty_screen_call,
           program TYPE zif_gg_dynpro_types_v1=>ty_program,
           screen  TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
           modal   TYPE ty_modal_position,
         END OF ty_screen_call.

  TYPES: BEGIN OF ty_selection_screen_call,
           screen TYPE zif_gg_selection_screen_types=>ty_screen_number,
           modal  TYPE ty_modal_position,
         END OF ty_selection_screen_call.

* id is opaque to the host. state is owned and interpreted by the program.
  TYPES: BEGIN OF ty_continuation,
           id    TYPE ty_continuation_id,
           state TYPE string,
         END OF ty_continuation.

  TYPES: BEGIN OF ty_resume,
           continuation TYPE ty_continuation,
           subrc        TYPE i,
         END OF ty_resume.

  TYPES: BEGIN OF ty_message,
           type  TYPE ty_message_type,
           text  TYPE string,
           field TYPE ty_name,
           row   TYPE i,
         END OF ty_message.

  TYPES: BEGIN OF ty_gui_status,
           status         TYPE ty_name,
           excluded_ucomm TYPE ty_ucomms,
         END OF ty_gui_status.

  TYPES: BEGIN OF ty_dialog_cursor,
           field TYPE ty_name,
           row   TYPE i,
         END OF ty_dialog_cursor.

  TYPES: BEGIN OF ty_list_cursor,
           level  TYPE i,
           page   TYPE i,
           line   TYPE i,
           column TYPE i,
           field  TYPE ty_name,
           value  TYPE string,
         END OF ty_list_cursor.

ENDINTERFACE.
