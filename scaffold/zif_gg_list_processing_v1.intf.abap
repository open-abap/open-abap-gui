INTERFACE zif_gg_list_processing_v1 PUBLIC.

* Optional classic-list event handler returned by zif_gg_report_v1. The basic
* list itself is written by the report's START-OF-SELECTION and
* END-OF-SELECTION callbacks using one zif_gg_list_writer_v1.

  "! Page and status settings of the list, corresponds to the REPORT
  "! additions plus SET TITLEBAR and SET PF-STATUS.
  "! @parameter rs_settings | initial size, title and status of the list
  METHODS get_settings
    RETURNING
      VALUE(rs_settings) TYPE zif_gg_list_processing_types_v1=>ty_settings.

  "! Write the page header, corresponds to TOP-OF-PAGE. Called for every
  "! page of the basic list. NO STANDARD PAGE HEADING suppresses only the
  "! built-in header and does not suppress this event.
  "! @parameter iv_page   | number of the page being started, ie sy-pagno
  "! @parameter io_writer | receives the header output
  METHODS top_of_page
    IMPORTING
      iv_page   TYPE i
      io_writer TYPE REF TO zif_gg_list_writer_v1.

  "! Write the page footer, corresponds to END-OF-PAGE. Only called when
  "! footer_lines is set in get_settings.
  "! @parameter iv_page   | number of the page being closed
  "! @parameter io_writer | receives the footer output
  METHODS end_of_page
    IMPORTING
      iv_page   TYPE i
      io_writer TYPE REF TO zif_gg_list_writer_v1.

  "! Write the page header of a detail list, corresponds to
  "! TOP-OF-PAGE DURING LINE-SELECTION.
  "! @parameter iv_level  | list level the header is written for, ie sy-lsind
  "! @parameter iv_page   | number of the page being started
  "! @parameter io_writer | receives the detail-list header output
  METHODS top_of_page_during_line_sel
    IMPORTING
      iv_level  TYPE i
      iv_page   TYPE i
      io_writer TYPE REF TO zif_gg_list_writer_v1.

  "! The user picked a line, corresponds to AT LINE-SELECTION.
  "! @parameter is_line   | the picked line, including the HIDE'd values
  "! @parameter io_writer | receives the detail list; no output leaves the
  "!                        current list standing
  "! @parameter rs_result | message and navigation effects
  METHODS at_line_selection
    IMPORTING
      is_line          TYPE zif_gg_list_processing_types_v1=>ty_line
      io_writer        TYPE REF TO zif_gg_list_writer_v1
    RETURNING
      VALUE(rs_result) TYPE zif_gg_list_processing_types_v1=>ty_result.

  "! The user triggered a function code, corresponds to AT USER-COMMAND.
  "! The codes come from the status set via get_settings.
  "! @parameter iv_ucomm  | the function code
  "! @parameter is_line   | the current line, including the HIDE'd values
  "! @parameter io_writer | receives an optional detail list
  "! @parameter rs_result | message and navigation effects
  METHODS at_user_command
    IMPORTING
      iv_ucomm         TYPE zif_gg_list_processing_types_v1=>ty_ucomm
      is_line          TYPE zif_gg_list_processing_types_v1=>ty_line
      io_writer        TYPE REF TO zif_gg_list_writer_v1
    RETURNING
      VALUE(rs_result) TYPE zif_gg_list_processing_types_v1=>ty_result.

  "! The user pressed a function key, corresponds to AT PFnn. Legacy, new
  "! code should use a status and at_user_command instead.
  "! @parameter iv_key    | number of the function key, 1 to 24
  "! @parameter is_line   | the current line, including the HIDE'd values
  "! @parameter io_writer | receives an optional detail list
  "! @parameter rs_result | message and navigation effects
  METHODS at_pf
    IMPORTING
      iv_key           TYPE i
      is_line          TYPE zif_gg_list_processing_types_v1=>ty_line
      io_writer        TYPE REF TO zif_gg_list_writer_v1
    RETURNING
      VALUE(rs_result) TYPE zif_gg_list_processing_types_v1=>ty_result.

ENDINTERFACE.
