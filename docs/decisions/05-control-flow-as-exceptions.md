# Non-local control flow is an exception

Statements that do not return to the caller (`LEAVE TO SCREEN`, `STOP`,
`SUBMIT`, `LEAVE PROGRAM`, ...) raise `zcx_gg_control_flow`. The host records
the operation and catches the exception at the callback boundary.

- It derives from `cx_no_check`, so the interfaces carry no `RAISING` clauses,
  just like the ABAP statements they model.
- An operation the host cannot honour yet raises it with `kind_unsupported` and
  the statement it models, so it fails loudly instead of silently doing nothing.

Code: [framework/host/zcx_gg_control_flow.clas.abap](../../framework/host/zcx_gg_control_flow.clas.abap)
