# Request flow

## Routes

| method | path | does |
| --- | --- | --- |
| GET | `/` | the shell, or the workbench when a shell session asks |
| GET | `/transaction?tcode=…` | start a transaction |
| GET | `/program?name=…` | start a report without a transaction |
| POST | `/transaction` | a command from the command field: `/n…`, `/o…` (new session) or `/i` (end session) |
| POST | `/dispatch` | a user action on the current page |
| DELETE | `/session/<id>` | close a running program |

A request names its GUI session in the `x-gg-window` header or the
`gg_window` field; one that names none belongs to the first session. The
`<id>` in `/session/<id>` is a running program, not a GUI session.

## One user action

```text
browser                 zcl_gg_http_handler     zcl_gg_host_runtime        program
   │ POST /dispatch            │                        │                      │
   │ (ucomm, field values)     │                        │                      │
   ├──────────────────────────►│ enter GUI session      │                      │
   │                           │ request_from_http      │                      │
   │                           ├───────────────────────►│ dispatch             │
   │                           │                        │ controls get values  │
   │                           │                        │ PAI / AT USER-COMMAND├──►
   │                           │                        │◄─────────────────────┤ session calls,
   │                           │                        │ next screen or list  │ or zcx_gg_control_flow
   │                           │                        │ render page          │
   │◄──────────────────────────┤ HTML                   │                      │
```

When a program ends, the runtime returns to its caller (after
`CALL TRANSACTION` or `SUBMIT ... AND RETURN`) or to the workbench, with the
last message in the status bar.

## Two hosts, one flow

On the express server, `fetch( )` from the shell goes over the network to the
handler. In the browser preview the same handler runs inside the tab, so
`fetch( )` never leaves the page.
