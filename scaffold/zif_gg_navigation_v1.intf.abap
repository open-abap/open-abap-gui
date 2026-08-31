INTERFACE zif_gg_navigation_v1 PUBLIC.

* Imperative transfers between programs. Like the dialog transfers, these are
* non-returning from the application's perspective: the host records the
* operation and unwinds to its callback boundary. Transfers that come back
* take an explicit continuation, the remaining ones are terminal.

  "! SUBMIT without AND RETURN. It ends the current program.
  METHODS submit
    IMPORTING
      is_submit TYPE zif_gg_session_types_v1=>ty_submit.

  "! SUBMIT ... AND RETURN. The callback is suspended; once the submitted
  "! program ends, the host invokes zif_gg_resumable_v1 with is_continuation.
  METHODS submit_and_return
    IMPORTING
      is_submit       TYPE zif_gg_session_types_v1=>ty_submit
      is_continuation TYPE zif_gg_session_types_v1=>ty_continuation.

  "! Basic list of the last submit that requested list_to_memory, as
  "! LIST_FROM_MEMORY returns it. Readable from the resumed callback onwards.
  METHODS get_list_from_memory
    RETURNING
      VALUE(rt_lines) TYPE zif_gg_session_types_v1=>ty_memory_list.

  "! CALL TRANSACTION with the same explicit continuation contract.
  METHODS call_transaction
    IMPORTING
      is_call         TYPE zif_gg_session_types_v1=>ty_transaction_call
      is_continuation TYPE zif_gg_session_types_v1=>ty_continuation.

  "! LEAVE TO TRANSACTION. It ends the current program and starts the target.
  METHODS leave_to_transaction
    IMPORTING
      is_call TYPE zif_gg_session_types_v1=>ty_transaction_call.

  "! LEAVE PROGRAM. It terminates the current internal session.
  METHODS leave_program.

ENDINTERFACE.
