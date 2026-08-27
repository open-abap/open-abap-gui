INTERFACE zif_gg_dialog_session_v1 PUBLIC.

* Imperative operations of the selection-screen and dynpro processors.
* Transfer methods are non-returning from the application's perspective: the
* host records the operation and unwinds to its callback boundary.

  METHODS set_title
    IMPORTING
      iv_title TYPE string.

  METHODS set_status
    IMPORTING
      is_status TYPE zif_gg_session_types_v1=>ty_gui_status.

  METHODS set_cursor
    IMPORTING
      is_cursor TYPE zif_gg_session_types_v1=>ty_dialog_cursor.

  "! SET SCREEN. It changes the next screen but does not end current PAI.
  METHODS set_next_screen
    IMPORTING
      iv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

  "! LEAVE SCREEN. It ends PAI and enters the configured next screen.
  METHODS leave_screen.

  "! LEAVE TO SCREEN. It sets and immediately enters the target screen.
  METHODS leave_to_screen
    IMPORTING
      iv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

  "! CALL SCREEN. The callback is suspended; after the called screen sequence
  "! ends, the host invokes zif_gg_resumable_v1 with is_continuation.
  METHODS call_screen
    IMPORTING
      is_call         TYPE zif_gg_session_types_v1=>ty_screen_call
      is_continuation TYPE zif_gg_session_types_v1=>ty_continuation.

  "! CALL SELECTION-SCREEN with the same explicit continuation contract.
  METHODS call_selection_screen
    IMPORTING
      is_call         TYPE zif_gg_session_types_v1=>ty_selection_screen_call
      is_continuation TYPE zif_gg_session_types_v1=>ty_continuation.

  "! Suppress the next selection-screen display, corresponding to
  "! sscrfields-ucomm-driven background flows and runtime-owned skipping.
  METHODS suppress_dialog.

  "! LEAVE PROGRAM. It terminates the current internal session.
  METHODS leave_program.

ENDINTERFACE.
