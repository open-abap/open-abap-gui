# Explicit continuations instead of a call stack

`CALL SCREEN`, `CALL SELECTION-SCREEN`, `SUBMIT ... AND RETURN` and
`CALL TRANSACTION` must continue after the called thing returns, which may be
several browser requests later. There is no language stack to suspend, so a
program implementing `zif_gg_resumable_v1` keeps its own continuation state,
and the host calls `resume` when the nested processor returns.

- The converter generates that state machine.
- A suspension inside `IF`, `CASE` or `TRY` keeps the other branches; one
  inside a loop resumes after the loop and is diagnosed (`GGCONV-W402`).

Code: [framework/zif_gg_resumable_v1.intf.abap](../../framework/zif_gg_resumable_v1.intf.abap)
