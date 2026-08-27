INTERFACE zif_gg_session_v1 PUBLIC.

* Execution-scoped facade for the current ABAP internal session. A session is
* never a process-global singleton. The host updates its context before every
* callback and catches non-local control transfers at the callback boundary.

  "! Snapshot of the active report, selection-screen, dynpro or list processor.
  METHODS get_context
    RETURNING
      VALUE(rs_context) TYPE zif_gg_session_types_v1=>ty_context.

  "! Imperative dialog and selection-screen operations.
  METHODS get_dialog
    RETURNING
      VALUE(ro_dialog) TYPE REF TO zif_gg_dialog_session_v1.

  "! Imperative classic-list operations and the writer for the active list.
  METHODS get_list
    RETURNING
      VALUE(ro_list) TYPE REF TO zif_gg_list_session_v1.

  "! Transfers to another program or transaction.
  METHODS get_navigation
    RETURNING
      VALUE(ro_navigation) TYPE REF TO zif_gg_navigation_v1.

  "! Execute MESSAGE with processor-specific ABAP semantics. Error and warning
  "! messages may abort the current callback and return control to the host,
  "! and the types A and X end the program without returning at all.
  METHODS message
    IMPORTING
      is_message TYPE zif_gg_session_types_v1=>ty_message.

  "! Execute STOP. This ends logical-database processing and continues with
  "! END-OF-SELECTION; the call does not return to the current callback.
  METHODS stop.

ENDINTERFACE.
