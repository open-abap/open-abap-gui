INTERFACE zif_gg_resumable_v1 PUBLIC.

* Optional companion interface for application objects that issue CALL SCREEN
* or CALL SELECTION-SCREEN. The host calls resume after the nested processor
* returns. Application-owned continuation state replaces an implicit language
* stack; a transpiler may generate this state machine automatically.

  METHODS resume
    IMPORTING
      is_resume  TYPE zif_gg_session_types_v1=>ty_resume
      io_session TYPE REF TO zif_gg_session_v1.

ENDINTERFACE.
