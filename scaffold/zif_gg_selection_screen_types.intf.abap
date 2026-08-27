INTERFACE zif_gg_selection_screen_types PUBLIC.

* Vocabulary shared between a program with a selection screen and whatever
* renders and drives that screen, see zif_gg_report_v1

  TYPES ty_name         TYPE c LENGTH 30.
  TYPES ty_group        TYPE c LENGTH 4.
  TYPES ty_modif_id     TYPE c LENGTH 3.
  TYPES ty_ucomm        TYPE c LENGTH 70.
  TYPES ty_sign         TYPE c LENGTH 1.
  TYPES ty_option       TYPE c LENGTH 2.
  TYPES ty_message_type TYPE c LENGTH 1.

  CONSTANTS sign_include TYPE ty_sign VALUE 'I'.
  CONSTANTS sign_exclude TYPE ty_sign VALUE 'E'.

  CONSTANTS option_eq TYPE ty_option VALUE 'EQ'.
  CONSTANTS option_ne TYPE ty_option VALUE 'NE'.
  CONSTANTS option_gt TYPE ty_option VALUE 'GT'.
  CONSTANTS option_ge TYPE ty_option VALUE 'GE'.
  CONSTANTS option_lt TYPE ty_option VALUE 'LT'.
  CONSTANTS option_le TYPE ty_option VALUE 'LE'.
  CONSTANTS option_bt TYPE ty_option VALUE 'BT'.
  CONSTANTS option_nb TYPE ty_option VALUE 'NB'.
  CONSTANTS option_cp TYPE ty_option VALUE 'CP'.
  CONSTANTS option_np TYPE ty_option VALUE 'NP'.

* one row of a SELECT-OPTIONS range table
  TYPES: BEGIN OF ty_range,
           sign   TYPE ty_sign,
           option TYPE ty_option,
           low    TYPE string,
           high   TYPE string,
         END OF ty_range.
  TYPES ty_ranges TYPE STANDARD TABLE OF ty_range WITH DEFAULT KEY.

* the entries of a LISTBOX, or the fixed values of a data element
  TYPES: BEGIN OF ty_fixed_value,
           key  TYPE string,
           text TYPE string,
         END OF ty_fixed_value.
  TYPES ty_fixed_values TYPE STANDARD TABLE OF ty_fixed_value
    WITH DEFAULT KEY.

* type information shared by input fields
  TYPES: BEGIN OF ty_data_type,
           rollname       TYPE ty_name,
           typ            TYPE string,
           length         TYPE i,
           decimals       TYPE i,
           visible_length TYPE i,
         END OF ty_data_type.

* Definitions passed to the operation-specific screen builder methods.
* Every component applies to its operation, so invalid combinations cannot be
* represented by filling unrelated fields.
  TYPES: BEGIN OF ty_parameter,
           name        TYPE ty_name,
           text        TYPE string,
           data_type   TYPE ty_data_type,
           modif_id    TYPE ty_modif_id,
           memory_id   TYPE ty_name,
           search_help TYPE ty_name,
           obligatory  TYPE abap_bool,
           lower_case  TYPE abap_bool,
           no_display  TYPE abap_bool,
           value_check TYPE abap_bool,
           value_help  TYPE abap_bool,
         END OF ty_parameter.

  TYPES: BEGIN OF ty_checkbox,
           name       TYPE ty_name,
           text       TYPE string,
           modif_id   TYPE ty_modif_id,
           memory_id  TYPE ty_name,
           ucomm      TYPE ty_ucomm,
           obligatory TYPE abap_bool,
           no_display TYPE abap_bool,
         END OF ty_checkbox.

  TYPES: BEGIN OF ty_radiobutton,
           name        TYPE ty_name,
           text        TYPE string,
           radio_group TYPE ty_group,
           modif_id    TYPE ty_modif_id,
           ucomm       TYPE ty_ucomm,
           obligatory  TYPE abap_bool,
           no_display  TYPE abap_bool,
         END OF ty_radiobutton.

  TYPES: BEGIN OF ty_listbox,
           name         TYPE ty_name,
           text         TYPE string,
           data_type    TYPE ty_data_type,
           fixed_values TYPE ty_fixed_values,
           modif_id     TYPE ty_modif_id,
           memory_id    TYPE ty_name,
           ucomm        TYPE ty_ucomm,
           obligatory   TYPE abap_bool,
           no_display   TYPE abap_bool,
           value_help   TYPE abap_bool,
         END OF ty_listbox.

  TYPES: BEGIN OF ty_select_option,
           name            TYPE ty_name,
           text            TYPE string,
           data_type       TYPE ty_data_type,
           modif_id        TYPE ty_modif_id,
           memory_id       TYPE ty_name,
           search_help     TYPE ty_name,
           obligatory      TYPE abap_bool,
           lower_case      TYPE abap_bool,
           no_display      TYPE abap_bool,
           no_extension    TYPE abap_bool,
           no_intervals    TYPE abap_bool,
           no_db_selection TYPE abap_bool,
           value_check     TYPE abap_bool,
           value_help      TYPE abap_bool,
         END OF ty_select_option.

  TYPES: BEGIN OF ty_pushbutton,
           name     TYPE ty_name,
           text     TYPE string,
           position TYPE i,
           length   TYPE i,
           modif_id TYPE ty_modif_id,
           ucomm    TYPE ty_ucomm,
         END OF ty_pushbutton.

  TYPES: BEGIN OF ty_comment,
           name           TYPE ty_name,
           text           TYPE string,
           position       TYPE i,
           visible_length TYPE i,
           for_field      TYPE ty_name,
           modif_id       TYPE ty_modif_id,
         END OF ty_comment.

  TYPES: BEGIN OF ty_uline,
           position TYPE i,
           length   TYPE i,
           modif_id TYPE ty_modif_id,
         END OF ty_uline.

  TYPES: BEGIN OF ty_function_key,
           number TYPE i,
           text   TYPE string,
           ucomm  TYPE ty_ucomm,
         END OF ty_function_key.

  TYPES: BEGIN OF ty_block,
           name       TYPE ty_name,
           title      TYPE string,
           with_frame TYPE abap_bool,
         END OF ty_block.

  TYPES: BEGIN OF ty_tabbed_block,
           name  TYPE ty_name,
           lines TYPE i,
         END OF ty_tabbed_block.

  TYPES: BEGIN OF ty_tab,
           name      TYPE ty_name,
           text      TYPE string,
           subscreen TYPE ty_name,
           ucomm     TYPE ty_ucomm,
         END OF ty_tab.

  TYPES: BEGIN OF ty_screen,
           name         TYPE ty_name,
           as_window    TYPE abap_bool,
           as_subscreen TYPE abap_bool,
         END OF ty_screen.

* Current input, separate from the immutable screen definition. Parameters
* use value; select-options use ranges.
  TYPES: BEGIN OF ty_value,
           name   TYPE ty_name,
           value  TYPE string,
           ranges TYPE ty_ranges,
         END OF ty_value.
  TYPES ty_values TYPE SORTED TABLE OF ty_value WITH UNIQUE KEY name.

* Mutable presentation state, populated from the definition before each
* AT SELECTION-SCREEN OUTPUT call.
  TYPES: BEGIN OF ty_state,
           name         TYPE ty_name,
           text         TYPE string,
           fixed_values TYPE ty_fixed_values,
           visible      TYPE abap_bool,
           enabled      TYPE abap_bool,
           obligatory   TYPE abap_bool,
         END OF ty_state.
  TYPES ty_states TYPE SORTED TABLE OF ty_state WITH UNIQUE KEY name.

  CONSTANTS message_type_error   TYPE ty_message_type VALUE 'E'.
  CONSTANTS message_type_warning TYPE ty_message_type VALUE 'W'.
  CONSTANTS message_type_info    TYPE ty_message_type VALUE 'I'.
  CONSTANTS message_type_success TYPE ty_message_type VALUE 'S'.

* returned instead of MESSAGE, an error keeps the screen open
  TYPES: BEGIN OF ty_message,
           type  TYPE ty_message_type,
           text  TYPE string,
           field TYPE ty_name,
         END OF ty_message.
  TYPES ty_messages TYPE STANDARD TABLE OF ty_message WITH DEFAULT KEY.

ENDINTERFACE.
