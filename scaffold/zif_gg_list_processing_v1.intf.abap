INTERFACE zif_gg_list_processing_v1 PUBLIC.

* Implement this in a program that writes a classic list. Output is sent to a
* zif_gg_list_writer in statement order; the remaining methods correspond to
* the events raised while the list is processed. All types and constants live
* in zif_gg_list_processing_types, which is shared across interface versions.

  "! Describe the basic list, ie what START-OF-SELECTION would WRITE.
  "! Called once; commands sent to io_writer are shown at level 0.
  "! @parameter io_writer | receives output and layout operations in order
  METHODS write_list
    IMPORTING
      io_writer TYPE REF TO zif_gg_list_writer.

  "! Page and status settings of the list, corresponds to the REPORT
  "! additions plus SET TITLEBAR and SET PF-STATUS.
  "! @parameter rs_settings | initial size, title and status of the list
  METHODS get_settings
    RETURNING
      VALUE(rs_settings) TYPE zif_gg_list_processing_types=>ty_settings.

  "! Write the page header, corresponds to TOP-OF-PAGE. Called for every
  "! page of the basic list, unless NO STANDARD PAGE HEADING is set.
  "! @parameter iv_page   | number of the page being started, ie sy-pagno
  "! @parameter io_writer | receives the header output
  METHODS top_of_page
    IMPORTING
      iv_page   TYPE i
      io_writer TYPE REF TO zif_gg_list_writer.

  "! Write the page footer, corresponds to END-OF-PAGE. Only called when
  "! footer_lines is set in get_settings.
  "! @parameter iv_page   | number of the page being closed
  "! @parameter io_writer | receives the footer output
  METHODS end_of_page
    IMPORTING
      iv_page   TYPE i
      io_writer TYPE REF TO zif_gg_list_writer.

  "! Write the page header of a detail list, corresponds to
  "! TOP-OF-PAGE DURING LINE-SELECTION.
  "! @parameter iv_level  | list level the header is written for, ie sy-lsind
  "! @parameter iv_page   | number of the page being started
  "! @parameter io_writer | receives the detail-list header output
  METHODS top_of_page_during_line_sel
    IMPORTING
      iv_level  TYPE i
      iv_page   TYPE i
      io_writer TYPE REF TO zif_gg_list_writer.

  "! The user picked a line, corresponds to AT LINE-SELECTION.
  "! @parameter is_line   | the picked line, including the HIDE'd values
  "! @parameter io_writer | receives the detail list; no output leaves the
  "!                        current list standing
  "! @parameter rs_result | message and navigation effects
  METHODS at_line_selection
    IMPORTING
      is_line          TYPE zif_gg_list_processing_types=>ty_line
      io_writer        TYPE REF TO zif_gg_list_writer
    RETURNING
      VALUE(rs_result) TYPE zif_gg_list_processing_types=>ty_result.

  "! The user triggered a function code, corresponds to AT USER-COMMAND.
  "! The codes come from the status set via get_settings.
  "! @parameter iv_ucomm  | the function code
  "! @parameter is_line   | the current line, including the HIDE'd values
  "! @parameter io_writer | receives an optional detail list
  "! @parameter rs_result | message and navigation effects
  METHODS at_user_command
    IMPORTING
      iv_ucomm         TYPE zif_gg_list_processing_types=>ty_ucomm
      is_line          TYPE zif_gg_list_processing_types=>ty_line
      io_writer        TYPE REF TO zif_gg_list_writer
    RETURNING
      VALUE(rs_result) TYPE zif_gg_list_processing_types=>ty_result.

  "! The user pressed a function key, corresponds to AT PFnn. Legacy, new
  "! code should use a status and at_user_command instead.
  "! @parameter iv_key    | number of the function key, 1 to 24
  "! @parameter is_line   | the current line, including the HIDE'd values
  "! @parameter io_writer | receives an optional detail list
  "! @parameter rs_result | message and navigation effects
  METHODS at_pf
    IMPORTING
      iv_key           TYPE i
      is_line          TYPE zif_gg_list_processing_types=>ty_line
      io_writer        TYPE REF TO zif_gg_list_writer
    RETURNING
      VALUE(rs_result) TYPE zif_gg_list_processing_types=>ty_result.

ENDINTERFACE.
