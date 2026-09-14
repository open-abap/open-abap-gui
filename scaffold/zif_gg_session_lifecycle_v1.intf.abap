INTERFACE zif_gg_session_lifecycle_v1 PUBLIC.

* Optional callback for report-owned resources which must be stopped when the
* browser session is closed or replaced by another transaction.

  METHODS on_close.

ENDINTERFACE.
