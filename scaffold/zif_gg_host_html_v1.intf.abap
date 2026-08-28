INTERFACE zif_gg_host_html_v1 PUBLIC.

* Transport-neutral vocabulary for pages emitted by the scaffold host. The
* browser or HTTP adapter may carry these values, but does not define them.

  CONSTANTS page_selection TYPE string VALUE 'SELECTION'.
  CONSTANTS page_list      TYPE string VALUE 'LIST'.
  CONSTANTS page_dynpro    TYPE string VALUE 'DYNPRO'.
  CONSTANTS page_message   TYPE string VALUE 'MESSAGE'.
  CONSTANTS page_navigation TYPE string VALUE 'NAVIGATION'.
  CONSTANTS page_terminal  TYPE string VALUE 'TERMINAL'.
  CONSTANTS page_error     TYPE string VALUE 'ERROR'.

  CONSTANTS action_submit       TYPE string VALUE 'SUBMIT'.
  CONSTANTS action_exit         TYPE string VALUE 'EXIT'.
  CONSTANTS action_line         TYPE string VALUE 'LINE'.
  CONSTANTS action_command      TYPE string VALUE 'COMMAND'.
  CONSTANTS action_pf           TYPE string VALUE 'PF'.
  CONSTANTS action_help         TYPE string VALUE 'HELP'.
  CONSTANTS action_value_help   TYPE string VALUE 'VALUE_HELP'.
  CONSTANTS action_screen       TYPE string VALUE 'SCREEN'.
  CONSTANTS action_tab          TYPE string VALUE 'TAB'.
  CONSTANTS action_back         TYPE string VALUE 'BACK'.

  TYPES: BEGIN OF ty_action,
           kind   TYPE string,
           ucomm  TYPE string,
           target TYPE string,
           row    TYPE i,
           token  TYPE string,
         END OF ty_action.
  TYPES ty_actions TYPE STANDARD TABLE OF ty_action WITH DEFAULT KEY.
  TYPES ty_messages TYPE STANDARD TABLE OF zif_gg_session_types_v1=>ty_message
    WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_navigation,
           kind         TYPE string,
           target       TYPE string,
           continuation TYPE string,
           modal        TYPE abap_bool,
         END OF ty_navigation.

  TYPES: BEGIN OF ty_renderer_context,
           program             TYPE zif_gg_session_types_v1=>ty_program,
           processor           TYPE zif_gg_session_types_v1=>ty_processor,
           screen              TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
           list_level          TYPE i,
           locale              TYPE string,
           date_format         TYPE string,
           decimal_separator   TYPE c LENGTH 1,
           thousands_separator TYPE c LENGTH 1,
           csp_nonce           TYPE string,
         END OF ty_renderer_context.

  TYPES: BEGIN OF ty_compatibility,
           lines        TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
           line_formats TYPE STANDARD TABLE OF zif_gg_list_processing_types_v1=>ty_format WITH DEFAULT KEY,
           messages     TYPE ty_messages,
           values       TYPE zif_gg_selection_screen_types=>ty_values,
           states       TYPE zif_gg_selection_screen_types=>ty_states,
           terminal     TYPE string,
         END OF ty_compatibility.

  TYPES: BEGIN OF ty_page,
           session_id TYPE string,
           page_id    TYPE string,
           kind       TYPE string,
           processor  TYPE zif_gg_session_types_v1=>ty_processor,
           screen     TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
           list_level TYPE i,
           title      TYPE string,
           status     TYPE zif_gg_session_types_v1=>ty_gui_status,
           terminal   TYPE abap_bool,
           navigation TYPE ty_navigation,
           messages   TYPE ty_messages,
           html       TYPE string,
           actions    TYPE ty_actions,
         END OF ty_page.
  TYPES ty_pages TYPE STANDARD TABLE OF ty_page WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_request,
           session_id    TYPE string,
           page_id       TYPE string,
           action        TYPE string,
           ucomm         TYPE string,
           target        TYPE string,
           value         TYPE string,
           row           TYPE i,
           pf_key        TYPE i,
           token         TYPE string,
           cursor_field  TYPE string,
           cursor_value  TYPE string,
           values        TYPE zif_gg_selection_screen_types=>ty_values,
           dynpro_values TYPE zif_gg_dynpro_types_v1=>ty_values,
         END OF ty_request.

  TYPES: BEGIN OF ty_response,
           valid         TYPE abap_bool,
           error         TYPE string,
           session_id    TYPE string,
           page_id       TYPE string,
           page_kind     TYPE string,
           html          TYPE string,
           messages      TYPE ty_messages,
           compatibility TYPE ty_compatibility,
           current_page  TYPE ty_page,
           pages         TYPE ty_pages,
         END OF ty_response.

ENDINTERFACE.
