INTERFACE zif_gg_session_types_v1 PUBLIC.

* Versioned vocabulary for one imperative internal-session execution. Context
* is grouped by processor so callbacks do not receive one growing flat bag of
* sy-* fields.

  TYPES ty_processor        TYPE string.
  TYPES ty_event            TYPE string.
  TYPES ty_program          TYPE c LENGTH 40.
  TYPES ty_name             TYPE c LENGTH 30.
  TYPES ty_ucomm            TYPE c LENGTH 70.
  TYPES ty_tcode            TYPE c LENGTH 20.
  TYPES ty_variant          TYPE c LENGTH 14.
  TYPES ty_message_type     TYPE c LENGTH 1.
  TYPES ty_message_id       TYPE c LENGTH 20.
  TYPES ty_message_number   TYPE n LENGTH 3.
  TYPES ty_message_variable TYPE c LENGTH 50.
  TYPES ty_continuation_id  TYPE string.

  CONSTANTS processor_report    TYPE ty_processor VALUE 'REPORT'.
  CONSTANTS processor_selection TYPE ty_processor VALUE 'SELECTION'.
  CONSTANTS processor_dynpro    TYPE ty_processor VALUE 'DYNPRO'.
  CONSTANTS processor_list      TYPE ty_processor VALUE 'LIST'.

* Types A and X end the program instead of returning to the callback.
  CONSTANTS message_type_error   TYPE ty_message_type VALUE 'E'.
  CONSTANTS message_type_warning TYPE ty_message_type VALUE 'W'.
  CONSTANTS message_type_info    TYPE ty_message_type VALUE 'I'.
  CONSTANTS message_type_success TYPE ty_message_type VALUE 'S'.
  CONSTANTS message_type_abort   TYPE ty_message_type VALUE 'A'.
  CONSTANTS message_type_exit    TYPE ty_message_type VALUE 'X'.

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

* SUBMIT <program> [USING SELECTION-SET <variant>] [WITH <sel> ...]
* [VIA SELECTION-SCREEN] [EXPORTING LIST TO MEMORY]. Selections supplied in
* values are applied on top of the variant, as WITH does.
  TYPES: BEGIN OF ty_submit,
           program              TYPE ty_program,
           variant              TYPE ty_variant,
           values               TYPE zif_gg_selection_screen_types=>ty_values,
           via_selection_screen TYPE abap_bool,
           list_to_memory       TYPE abap_bool,
         END OF ty_submit.

* The basic list of a submitted program, as LIST_FROM_MEMORY returns it.
  TYPES ty_memory_list TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

* CALL TRANSACTION or LEAVE TO TRANSACTION <tcode> [AND SKIP FIRST SCREEN].
  TYPES: BEGIN OF ty_transaction_call,
           tcode             TYPE ty_tcode,
           skip_first_screen TYPE abap_bool,
         END OF ty_transaction_call.

* id is opaque to the host. state is owned and interpreted by the program.
  TYPES: BEGIN OF ty_continuation,
           id    TYPE ty_continuation_id,
           state TYPE string,
         END OF ty_continuation.

  TYPES: BEGIN OF ty_resume,
           continuation TYPE ty_continuation,
           subrc        TYPE i,
         END OF ty_resume.

* MESSAGE <type><number>(<id>) WITH <v1> .. <v4>. An initial id means a free
* text message, where text carries the literal and the variables are unused.
* Otherwise the host resolves the text from id and number and substitutes the
* variables. display_like corresponds to DISPLAY LIKE and only changes how the
* message is rendered, not how it behaves.
  TYPES: BEGIN OF ty_message,
           type         TYPE ty_message_type,
           id           TYPE ty_message_id,
           number       TYPE ty_message_number,
           v1           TYPE ty_message_variable,
           v2           TYPE ty_message_variable,
           v3           TYPE ty_message_variable,
           v4           TYPE ty_message_variable,
           text         TYPE string,
           display_like TYPE ty_message_type,
           field        TYPE ty_name,
           row          TYPE i,
         END OF ty_message.

* Function codes of the standard toolbar. A CUA status activates the commands
* it lists in active_ucomm, every other standard command stays greyed out.
  CONSTANTS command_save          TYPE ty_ucomm VALUE 'SAVE'.
  CONSTANTS command_back          TYPE ty_ucomm VALUE 'BACK'.
  CONSTANTS command_exit          TYPE ty_ucomm VALUE '%EX'.
  CONSTANTS command_cancel        TYPE ty_ucomm VALUE 'RW'.
  CONSTANTS command_print         TYPE ty_ucomm VALUE 'PRI'.
  CONSTANTS command_find          TYPE ty_ucomm VALUE '%SC'.
  CONSTANTS command_find_next     TYPE ty_ucomm VALUE '%SC+'.
  CONSTANTS command_first_page    TYPE ty_ucomm VALUE 'P--'.
  CONSTANTS command_previous_page TYPE ty_ucomm VALUE 'P-'.
  CONSTANTS command_next_page     TYPE ty_ucomm VALUE 'P+'.
  CONSTANTS command_last_page     TYPE ty_ucomm VALUE 'P++'.

* Application icon-bar entries. The owning example supplies the visible
* buttons, including the function code and icon used for each entry.
  TYPES: BEGIN OF ty_icon_bar_item,
           ucomm     TYPE ty_ucomm,
           label     TYPE string,
           icon      TYPE string,
           separator TYPE abap_bool,
         END OF ty_icon_bar_item.
  TYPES ty_icon_bar TYPE STANDARD TABLE OF ty_icon_bar_item WITH DEFAULT KEY.
  TYPES ty_pf_keys TYPE SORTED TABLE OF i WITH UNIQUE KEY table_line.

* status names the CUA status, active_ucomm lists the function codes it
* activates, excluded_ucomm removes function codes again, as EXCLUDING does,
* and active_pf_keys declares the AT PFnn events accepted by the HTML runtime.
* A command that is not active is rendered disabled and rejected server-side.
* icon_bar is the application-owned icon bar for the same status.
  TYPES: BEGIN OF ty_gui_status,
           status         TYPE ty_name,
           active_ucomm   TYPE ty_ucomms,
           excluded_ucomm TYPE ty_ucomms,
           active_pf_keys TYPE ty_pf_keys,
           icon_bar       TYPE ty_icon_bar,
           END OF ty_gui_status.

  TYPES: BEGIN OF ty_breadcrumb,
           label   TYPE string,
           target  TYPE string,
           current TYPE abap_bool,
         END OF ty_breadcrumb.
  TYPES ty_breadcrumbs TYPE STANDARD TABLE OF ty_breadcrumb WITH DEFAULT KEY.

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
