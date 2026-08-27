INTERFACE zif_gg_dynpro_types_v1 PUBLIC.

* Versioned vocabulary shared by a dialog program and its dynpro renderer.

  TYPES ty_screen_number TYPE n LENGTH 4.
  TYPES ty_name          TYPE c LENGTH 30.
  TYPES ty_group         TYPE c LENGTH 4.
  TYPES ty_modif_id      TYPE c LENGTH 3.
  TYPES ty_ucomm         TYPE c LENGTH 70.
  TYPES ty_message_type  TYPE c LENGTH 1.
  TYPES ty_navigation    TYPE string.

  TYPES ty_ucomms TYPE STANDARD TABLE OF ty_ucomm WITH DEFAULT KEY.

  CONSTANTS navigation_none          TYPE ty_navigation VALUE 'NONE'.
  CONSTANTS navigation_set_screen    TYPE ty_navigation VALUE 'SET-SCREEN'.
  CONSTANTS navigation_call_screen   TYPE ty_navigation VALUE 'CALL-SCREEN'.
  CONSTANTS navigation_leave_screen  TYPE ty_navigation VALUE 'LEAVE-SCREEN'.
  CONSTANTS navigation_leave_program TYPE ty_navigation VALUE 'LEAVE-PROGRAM'.

  CONSTANTS message_type_error   TYPE ty_message_type VALUE 'E'.
  CONSTANTS message_type_warning TYPE ty_message_type VALUE 'W'.
  CONSTANTS message_type_info    TYPE ty_message_type VALUE 'I'.
  CONSTANTS message_type_success TYPE ty_message_type VALUE 'S'.

  TYPES: BEGIN OF ty_fixed_value,
           key  TYPE string,
           text TYPE string,
         END OF ty_fixed_value.
  TYPES ty_fixed_values TYPE STANDARD TABLE OF ty_fixed_value
    WITH DEFAULT KEY.

  TYPES: BEGIN OF ty_data_type,
           rollname TYPE ty_name,
           typ      TYPE string,
           length   TYPE i,
           decimals TYPE i,
         END OF ty_data_type.

  TYPES: BEGIN OF ty_position,
           row    TYPE i,
           column TYPE i,
           width  TYPE i,
           height TYPE i,
         END OF ty_position.

  TYPES: BEGIN OF ty_control,
           name     TYPE ty_name,
           position TYPE ty_position,
           modif_id TYPE ty_modif_id,
         END OF ty_control.

  TYPES: BEGIN OF ty_screen,
           number      TYPE ty_screen_number,
           title       TYPE string,
           next_screen TYPE ty_screen_number,
           modal       TYPE abap_bool,
           width       TYPE i,
           height      TYPE i,
         END OF ty_screen.

* Definitions consumed by the operation-specific builder methods.
  TYPES: BEGIN OF ty_input_field,
           control     TYPE ty_control,
           data_type   TYPE ty_data_type,
           search_help TYPE ty_name,
           uppercase   TYPE abap_bool,
           required    TYPE abap_bool,
           value_check TYPE abap_bool,
           value_help  TYPE abap_bool,
           password    TYPE abap_bool,
         END OF ty_input_field.

  TYPES: BEGIN OF ty_output_field,
           control   TYPE ty_control,
           data_type TYPE ty_data_type,
         END OF ty_output_field.

  TYPES: BEGIN OF ty_text,
           control TYPE ty_control,
           text    TYPE string,
         END OF ty_text.

  TYPES: BEGIN OF ty_pushbutton,
           control TYPE ty_control,
           text    TYPE string,
           ucomm   TYPE ty_ucomm,
         END OF ty_pushbutton.

  TYPES: BEGIN OF ty_checkbox,
           control TYPE ty_control,
           text    TYPE string,
           ucomm   TYPE ty_ucomm,
         END OF ty_checkbox.

  TYPES: BEGIN OF ty_radiobutton,
           control TYPE ty_control,
           text    TYPE string,
           group   TYPE ty_group,
           ucomm   TYPE ty_ucomm,
         END OF ty_radiobutton.

  TYPES: BEGIN OF ty_listbox,
           control      TYPE ty_control,
           data_type    TYPE ty_data_type,
           fixed_values TYPE ty_fixed_values,
           ucomm        TYPE ty_ucomm,
         END OF ty_listbox.

  TYPES: BEGIN OF ty_box,
           control TYPE ty_control,
           text    TYPE string,
         END OF ty_box.

  TYPES: BEGIN OF ty_subscreen_area,
           control TYPE ty_control,
         END OF ty_subscreen_area.

  TYPES: BEGIN OF ty_custom_control,
           control TYPE ty_control,
         END OF ty_custom_control.

  TYPES: BEGIN OF ty_tabstrip,
           control TYPE ty_control,
           ucomm   TYPE ty_ucomm,
         END OF ty_tabstrip.

  TYPES: BEGIN OF ty_tab,
           control   TYPE ty_control,
           tabstrip  TYPE ty_name,
           text      TYPE string,
           subscreen TYPE ty_screen_number,
           ucomm     TYPE ty_ucomm,
         END OF ty_tab.

  TYPES: BEGIN OF ty_table_control,
           control        TYPE ty_control,
           visible_rows   TYPE i,
           selection_mode TYPE string,
           with_hscroll   TYPE abap_bool,
           with_vscroll   TYPE abap_bool,
         END OF ty_table_control.

  TYPES: BEGIN OF ty_table_column,
           table_control TYPE ty_name,
           name          TYPE ty_name,
           title         TYPE string,
           data_type     TYPE ty_data_type,
           width         TYPE i,
           input         TYPE abap_bool,
           required      TYPE abap_bool,
         END OF ty_table_column.

* Current program data. row is zero for ordinary controls and one-based for
* table-control rows; container identifies the table control when applicable.
  TYPES: BEGIN OF ty_value,
           container TYPE ty_name,
           name      TYPE ty_name,
           row       TYPE i,
           value     TYPE string,
         END OF ty_value.
  TYPES ty_values TYPE SORTED TABLE OF ty_value
    WITH UNIQUE KEY container name row.

* Mutable SCREEN-like state, seeded from the definition before every PBO.
  TYPES: BEGIN OF ty_state,
           container    TYPE ty_name,
           name         TYPE ty_name,
           row          TYPE i,
           text         TYPE string,
           fixed_values TYPE ty_fixed_values,
           visible      TYPE abap_bool,
           enabled      TYPE abap_bool,
           required     TYPE abap_bool,
           intensified  TYPE abap_bool,
           password     TYPE abap_bool,
           value_help   TYPE abap_bool,
           subscreen    TYPE ty_screen_number,
         END OF ty_state.
  TYPES ty_states TYPE SORTED TABLE OF ty_state
    WITH UNIQUE KEY container name row.

* SET PF-STATUS, SET TITLEBAR, SET CURSOR and a dynamic next screen from PBO.
  TYPES: BEGIN OF ty_screen_state,
           title          TYPE string,
           status         TYPE ty_name,
           excluded_ucomm TYPE ty_ucomms,
           cursor_field   TYPE ty_name,
           cursor_row     TYPE i,
           next_screen    TYPE ty_screen_number,
         END OF ty_screen_state.

  TYPES: BEGIN OF ty_message,
           type      TYPE ty_message_type,
           text      TYPE string,
           field     TYPE ty_name,
           table_row TYPE i,
         END OF ty_message.
  TYPES ty_messages TYPE STANDARD TABLE OF ty_message WITH DEFAULT KEY.

* Navigation requested by PAI. screen is used by SET-SCREEN and CALL-SCREEN.
  TYPES: BEGIN OF ty_result,
           navigation TYPE ty_navigation,
           screen     TYPE ty_screen_number,
           messages   TYPE ty_messages,
         END OF ty_result.

ENDINTERFACE.
