INTERFACE zif_gg_selection_screen_types PUBLIC.

* Vocabulary shared between a program with a selection screen and whatever
* renders and drives that screen, see zif_gg_selection_screen_v1

  TYPES ty_kind     TYPE string.
  TYPES ty_name     TYPE c LENGTH 30.
  TYPES ty_group    TYPE c LENGTH 4.
  TYPES ty_modif_id TYPE c LENGTH 3.
  TYPES ty_ucomm    TYPE c LENGTH 70.

  CONSTANTS kind_parameter     TYPE ty_kind VALUE 'PARAMETER'.
  CONSTANTS kind_select_option TYPE ty_kind VALUE 'SELECT-OPTION'.
  CONSTANTS kind_checkbox      TYPE ty_kind VALUE 'CHECKBOX'.
  CONSTANTS kind_radiobutton   TYPE ty_kind VALUE 'RADIOBUTTON'.
  CONSTANTS kind_listbox       TYPE ty_kind VALUE 'LISTBOX'.
  CONSTANTS kind_pushbutton    TYPE ty_kind VALUE 'PUSHBUTTON'.
  CONSTANTS kind_comment       TYPE ty_kind VALUE 'COMMENT'.
  CONSTANTS kind_uline         TYPE ty_kind VALUE 'ULINE'.
  CONSTANTS kind_skip          TYPE ty_kind VALUE 'SKIP'.
  CONSTANTS kind_block_begin   TYPE ty_kind VALUE 'BLOCK-BEGIN'.
  CONSTANTS kind_block_end     TYPE ty_kind VALUE 'BLOCK-END'.
  CONSTANTS kind_line_begin    TYPE ty_kind VALUE 'LINE-BEGIN'.
  CONSTANTS kind_line_end      TYPE ty_kind VALUE 'LINE-END'.
  CONSTANTS kind_tab           TYPE ty_kind VALUE 'TAB'.

* one row of a SELECT-OPTIONS range table
  TYPES: BEGIN OF ty_range,
           sign   TYPE c LENGTH 1,
           option TYPE c LENGTH 2,
           low    TYPE string,
           high   TYPE string,
         END OF ty_range.
  TYPES ty_ranges TYPE STANDARD TABLE OF ty_range WITH DEFAULT KEY.

* fixed values, for a LISTBOX or a radiobutton group
  TYPES ty_values TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

* a single element of the selection screen, in the sequence it is rendered
  TYPES: BEGIN OF ty_element,
           kind         TYPE ty_kind,
           name         TYPE ty_name,
           text         TYPE string,
           block        TYPE ty_name,
           rollname     TYPE ty_name,
           typ          TYPE string,
           length       TYPE i,
           decimals     TYPE i,
           value        TYPE string,
           ranges       TYPE ty_ranges,
           fixed_values TYPE ty_values,
           radio_group  TYPE ty_group,
           modif_id     TYPE ty_modif_id,
           memory_id    TYPE ty_name,
           obligatory   TYPE abap_bool,
           lower_case   TYPE abap_bool,
           no_display   TYPE abap_bool,
           visible      TYPE abap_bool,
           enabled      TYPE abap_bool,
           value_help   TYPE abap_bool,
         END OF ty_element.
  TYPES ty_elements TYPE STANDARD TABLE OF ty_element WITH DEFAULT KEY.

  CONSTANTS message_type_error   TYPE c LENGTH 1 VALUE 'E'.
  CONSTANTS message_type_warning TYPE c LENGTH 1 VALUE 'W'.
  CONSTANTS message_type_info    TYPE c LENGTH 1 VALUE 'I'.
  CONSTANTS message_type_success TYPE c LENGTH 1 VALUE 'S'.

* returned instead of MESSAGE, an error keeps the screen open
  TYPES: BEGIN OF ty_message,
           type  TYPE c LENGTH 1,
           text  TYPE string,
           field TYPE ty_name,
         END OF ty_message.
  TYPES ty_messages TYPE STANDARD TABLE OF ty_message WITH DEFAULT KEY.

ENDINTERFACE.
