# Architecture

open-abap-gui runs classic SAP GUI programs (reports, selection screens, lists,
dynpros, GUI controls) in the browser, on the open-abap runtime.

```text
 report.prog.abap ──► converter ──► zcl_report.clas.abap ──► abap_transpile ──► JavaScript
                                                                                │
 browser ◄── HTML ◄── host (framework/) ◄── calls the report class ◄────────────┘
                         │
                         └── GUI controls (src/) render their part of the page
```

"Session" means three things in the code:

- **session object**: what a program calls during one run (`zif_gg_session_v1`)
- **running program**: the runtime's entry for a started program, its `session_id`
- **GUI session**: a window of the shell or a browser tab (`zcl_gg_host_windows`)

1. [Folders](folders.md): what lives where
2. [Converter](converter.md): from a report to a class
3. [Host](host.md): running a program and turning it into pages
4. [Request flow](request-flow.md): one click, from browser to ABAP and back
5. [Controls](controls.md): the SAP control classes in `src/`
6. [Testing](testing.md): the test layers

The reasons behind the design are in [../decisions/](../decisions/README.md).
