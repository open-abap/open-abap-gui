# GUI sessions and the roll area

Controls, ALV trees and screen attributes are held in static state. Each GUI
session (a window in the shell, or a browser tab) gets its own copy of that
state, and the copy for the session a request comes from is put in place
before the request runs, like the roll area in SAP.

- The shell at `/` shows a rail of sessions, with each session in its own
  iframe, so pages keep their own styles, ids and scripts.
- Requests name their session in the `x-gg-window` header or the `gg_window`
  field; a request that names none belongs to the first session. A shell's
  first request asks for a new session, so browser tabs never share one.
- Programs started in a session end with it; the last session stays open.

Code: [framework/zcl_gg_host_windows.clas.abap](../../framework/zcl_gg_host_windows.clas.abap),
[framework/zcl_gg_shell.clas.abap](../../framework/zcl_gg_shell.clas.abap)
