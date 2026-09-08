INTERFACE zif_gg_list_session_v1 PUBLIC.

* Imperative operations of the classic list processor. get_writer always
* addresses the list currently selected by the host.

  METHODS get_writer
    RETURNING
      VALUE(ro_writer) TYPE REF TO zif_gg_list_writer_v1.

  "! LEAVE TO LIST-PROCESSING. This transfers control to the list processor.
  METHODS enter_list_processing.

  "! LEAVE LIST-PROCESSING. This ends the current interactive list event.
  METHODS leave_list_processing.

  METHODS get_cursor
    RETURNING
      VALUE(rs_cursor) TYPE zif_gg_session_types_v1=>ty_list_cursor.

  METHODS get_context
    RETURNING
      VALUE(rs_context) TYPE zif_gg_session_types_v1=>ty_list_context.

  METHODS read_line
    IMPORTING
      iv_level       TYPE i OPTIONAL
      iv_index       TYPE i
    RETURNING
      VALUE(rs_line) TYPE zif_gg_list_processing_types_v1=>ty_line.

  METHODS modify_line
    IMPORTING
      is_line TYPE zif_gg_list_processing_types_v1=>ty_line.

  METHODS set_title
    IMPORTING
      iv_title TYPE string.

  METHODS set_status
    IMPORTING
      is_status TYPE zif_gg_session_types_v1=>ty_gui_status.

ENDINTERFACE.
