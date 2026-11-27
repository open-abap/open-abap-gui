# Execution-scoped session

Every event callback of a program receives the same session object for that
run. The list writer, `MESSAGE`, `STOP`, `CALL SCREEN`, `SUBMIT` and the
system fields are operations of that session.

- A session is never a process-global singleton.
- The host updates the session context before every callback.
- System fields are grouped by processor instead of one flat `sy` structure.

Why: programs stay testable in isolation, and several programs can run in one
process without sharing state by accident.

Code: [framework/zif_gg_session_v1.intf.abap](../../framework/zif_gg_session_v1.intf.abap),
[framework/host/zcl_gg_host_session.clas.abap](../../framework/host/zcl_gg_host_session.clas.abap)
