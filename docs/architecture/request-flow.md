# Request flow

## Routes

| method | path | does |
| --- | --- | --- |
| GET | `/` | the shell, or the workbench when a shell session asks |
| GET | `/transaction?tcode=…` | start a transaction |
| GET | `/program?name=…` | start a report without a transaction |
| POST | `/transaction` | a command from the command field: `/n…`, `/o…` (new session) or `/i` (end session); `session=close` ends all sessions of a shell whose page went |
| POST | `/dispatch` | a user action on the current page |
| DELETE | `/session/<id>` | close a running program |

The paths are the request's `~path_info`, the part below where the handler
is served; at the root of the server that is the whole path. The pages link
and post below the same place, `~path` without its `~path_info`, so the
handler can sit below any path, as an ICF node serves it.

A request names its GUI session in the `x-gg-window` header or the
`gg_window` field; one that names neither belongs to the session of the
running program it is for (its `session_id`, in a form, a JSON body or
`/session/<id>`), or else to the first session. The `<id>` in
`/session/<id>` is a running program, not a GUI session.

The sessions share the host's static GUI state, so both hosts run one
request at a time.

The shell at `/` opens a route given in the hash in its session, so
`/#/transaction?tcode=SE16` starts SE16 inside the shell.

## Headers for the shell

| response header | meaning |
| --- | --- |
| `x-gg-window` | the GUI session the host opened for a shell's first request |
| `x-gg-session` | `new` or `end`: a GUI session opened (`/o`) or ended (`/i`); `/o` for a transaction that does not start opens none |
| `x-gg-transaction` | the transaction, or program, on screen; the rail lists the session under it |

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
handler. In the browser preview, [web/web.mjs](../../web/web.mjs) replaces
`fetch( )` and hands each request to the same handler inside the tab, so it
never leaves the page. Apart from writing the shell into the page at start,
that is all `web.mjs` does: the shell, the pages and their scripts all come
from the ABAP host, in both hosts.
