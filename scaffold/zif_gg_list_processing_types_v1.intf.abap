INTERFACE zif_gg_list_processing_types_v1 PUBLIC.

* Vocabulary shared between a program that writes a classic list and
* whatever renders and drives that list, see zif_gg_list_processing_v1

  TYPES ty_name          TYPE c LENGTH 30.
  TYPES ty_ucomm         TYPE c LENGTH 70.
  TYPES ty_color         TYPE i.
  TYPES ty_justification TYPE string.

* FORMAT COLOR, the classic col_* constants
  CONSTANTS color_background TYPE ty_color VALUE 0.
  CONSTANTS color_heading    TYPE ty_color VALUE 1.
  CONSTANTS color_normal     TYPE ty_color VALUE 2.
  CONSTANTS color_total      TYPE ty_color VALUE 3.
  CONSTANTS color_key        TYPE ty_color VALUE 4.
  CONSTANTS color_positive   TYPE ty_color VALUE 5.
  CONSTANTS color_negative   TYPE ty_color VALUE 6.
  CONSTANTS color_group      TYPE ty_color VALUE 7.

* WRITE ... LEFT-JUSTIFIED | CENTERED | RIGHT-JUSTIFIED
  CONSTANTS justify_left   TYPE ty_justification VALUE 'LEFT'.
  CONSTANTS justify_center TYPE ty_justification VALUE 'CENTER'.
  CONSTANTS justify_right  TYPE ty_justification VALUE 'RIGHT'.

* the values carried along with a line, as HIDE stores them and
* READ LINE gives them back
  TYPES: BEGIN OF ty_hidden_field,
           name  TYPE ty_name,
           value TYPE string,
         END OF ty_hidden_field.
  TYPES ty_hidden_fields TYPE STANDARD TABLE OF ty_hidden_field
    WITH DEFAULT KEY.

* Current FORMAT state. set_format replaces the current state; reset_format
* restores the renderer defaults.
  TYPES: BEGIN OF ty_format,
           color       TYPE ty_color,
           intensified TYPE abap_bool,
           inverse     TYPE abap_bool,
           hotspot     TYPE abap_bool,
           input       TYPE abap_bool,
           quickinfo   TYPE string,
         END OF ty_format.

* Placement shared by the operation-specific WRITE methods.
  TYPES: BEGIN OF ty_placement,
           position TYPE i,
           length   TYPE i,
           new_line TYPE abap_bool,
           no_gap   TYPE abap_bool,
         END OF ty_placement.

* Numeric and character formatting additions valid for a normal WRITE.
  TYPES: BEGIN OF ty_write_format,
           justification TYPE ty_justification,
           currency      TYPE ty_name,
           unit          TYPE ty_name,
           decimals      TYPE i,
           round         TYPE i,
           exponent      TYPE i,
           edit_mask     TYPE string,
           no_zero       TYPE abap_bool,
           no_sign       TYPE abap_bool,
         END OF ty_write_format.

  TYPES: BEGIN OF ty_write_field,
           name         TYPE ty_name,
           text         TYPE string,
           placement    TYPE ty_placement,
           write_format TYPE ty_write_format,
           hide         TYPE ty_hidden_fields,
         END OF ty_write_field.

  TYPES: BEGIN OF ty_write_checkbox,
           name      TYPE ty_name,
           value     TYPE abap_bool,
           placement TYPE ty_placement,
           hide      TYPE ty_hidden_fields,
         END OF ty_write_checkbox.

  TYPES: BEGIN OF ty_write_icon,
           name      TYPE ty_name,
           placement TYPE ty_placement,
           hide      TYPE ty_hidden_fields,
         END OF ty_write_icon.

  TYPES: BEGIN OF ty_write_symbol,
           name      TYPE ty_name,
           placement TYPE ty_placement,
           hide      TYPE ty_hidden_fields,
         END OF ty_write_symbol.

  TYPES: BEGIN OF ty_uline,
           position TYPE i,
           length   TYPE i,
         END OF ty_uline.

  TYPES: BEGIN OF ty_new_page,
           no_title   TYPE abap_bool,
           no_heading TYPE abap_bool,
           line_size  TYPE i,
           line_count TYPE i,
         END OF ty_new_page.

* the line the user acted on, ie sy-lisel and friends after READ LINE
  TYPES: BEGIN OF ty_line,
           level  TYPE i,
           index  TYPE i,
           page   TYPE i,
           text   TYPE string,
           fields TYPE ty_hidden_fields,
         END OF ty_line.

* REPORT ... LINE-SIZE n LINE-COUNT n(m) NO STANDARD PAGE HEADING,
* plus SET TITLEBAR and SET PF-STATUS
  TYPES: BEGIN OF ty_settings,
           title                 TYPE string,
           status                TYPE ty_name,
           line_size             TYPE i,
           line_count            TYPE i,
           footer_lines          TYPE i,
           no_standard_page_head TYPE abap_bool,
         END OF ty_settings.

ENDINTERFACE.
