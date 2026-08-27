INTERFACE zif_gg_list_processing_v1 PUBLIC.

* Optional classic-list event handler returned by zif_gg_report_v1. All list
* output and processor effects are imperative operations of io_session.

  "! REPORT additions plus the initial title and PF-STATUS.
  METHODS get_settings
    IMPORTING
      io_session         TYPE REF TO zif_gg_session_v1
    RETURNING
      VALUE(rs_settings) TYPE zif_gg_list_processing_types_v1=>ty_settings.

  "! Corresponds to TOP-OF-PAGE. NO STANDARD PAGE HEADING suppresses only
  "! the built-in header and does not suppress this event.
  METHODS top_of_page
    IMPORTING
      iv_page    TYPE i
      io_session TYPE REF TO zif_gg_session_v1.

  "! Corresponds to END-OF-PAGE.
  METHODS end_of_page
    IMPORTING
      iv_page    TYPE i
      io_session TYPE REF TO zif_gg_session_v1.

  "! Corresponds to TOP-OF-PAGE DURING LINE-SELECTION.
  METHODS top_of_page_during_line_sel
    IMPORTING
      iv_level   TYPE i
      iv_page    TYPE i
      io_session TYPE REF TO zif_gg_session_v1.

  "! Corresponds to AT LINE-SELECTION. The selected line contains HIDE data.
  METHODS at_line_selection
    IMPORTING
      is_line    TYPE zif_gg_list_processing_types_v1=>ty_line
      io_session TYPE REF TO zif_gg_session_v1.

  "! Corresponds to AT USER-COMMAND.
  METHODS at_user_command
    IMPORTING
      iv_ucomm   TYPE zif_gg_list_processing_types_v1=>ty_ucomm
      is_line    TYPE zif_gg_list_processing_types_v1=>ty_line
      io_session TYPE REF TO zif_gg_session_v1.

  "! Corresponds to AT PFnn. Prefer a status and at_user_command in new code.
  METHODS at_pf
    IMPORTING
      iv_key     TYPE i
      is_line    TYPE zif_gg_list_processing_types_v1=>ty_line
      io_session TYPE REF TO zif_gg_session_v1.

ENDINTERFACE.
