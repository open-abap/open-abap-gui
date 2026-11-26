# Host

The host in `framework/` runs a converted program and turns its output into
HTML pages.

## Layers

| class | role |
| --- | --- |
| `zcl_gg_http_handler` | HTTP in and out: routes, form fields, response headers |
| `zcl_gg_host_runtime` | state between requests: running programs, call chains, pages |
| `zcl_gg_host` | one run of a report through its events, returns a typed result |
| `zcl_gg_host_dynpro` | PBO/PAI processing of dialog screens |
| `zcl_gg_host_renderer` | result to HTML page |
| `zcl_gg_host_windows` | GUI sessions; swaps static GUI state per session |

## Processors

A program describes its screens through builders
(`zif_gg_selection_screen_builder_v1`, `zif_gg_dynpro_builder_v1`), and does
everything else through the session object it gets in every callback
(`zcl_gg_host_session`). Behind them sit the processors:

| processor | class | models |
| --- | --- | --- |
| selection screen | `zcl_gg_host_screen` | PARAMETERS, SELECT-OPTIONS, blocks, AT SELECTION-SCREEN |
| list | `zcl_gg_host_list`, `zcl_gg_host_list_processor` | WRITE, list levels, pages, hidden fields, built-in list functions |
| dynpro | `zcl_gg_host_dynpro`, `zcl_gg_host_dynpro_flow` | screens, flow logic, table controls, GUI status |
| compatibility | `zcl_gg_host_compatibility` | the classic GUI function modules |

## Around the programs

- `zcl_gg_workbench`: the start page, listing transactions and reports.
- `zcl_gg_shell`: the page at `/`, a rail of GUI sessions, each in an iframe;
  a route in the hash (`/#/transaction?tcode=SE16`) opens in its session.
- `zcl_gg_transaction_registry`, `zcl_gg_program_registry`: catalogs built by
  `zcl_gg_class_discovery`.
- `zif_gg_host_environment_v1`: setup and teardown hooks, such as database
  fixtures.
