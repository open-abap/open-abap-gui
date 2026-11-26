# Transport-neutral host

The host is split into layers, and only the last one knows about HTTP:

| class | role |
| --- | --- |
| `zcl_gg_host` | one deterministic run of a program, returns a typed result |
| `zcl_gg_host_runtime` | state between requests: running programs, pages, call chains |
| `zcl_gg_host_renderer` | turns a result into an HTML document string |
| `zcl_gg_http_handler` | the `if_http_extension` that carries requests and pages |

Why: the same host runs behind express, inside the browser preview, and in
ABAP Unit, where a rendered page is just a string to assert on.

Code: [framework/host/zcl_gg_host.clas.abap](../../framework/host/zcl_gg_host.clas.abap),
[framework/zcl_gg_host_runtime.clas.abap](../../framework/zcl_gg_host_runtime.clas.abap),
[framework/zcl_gg_host_renderer.clas.abap](../../framework/zcl_gg_host_renderer.clas.abap),
[framework/http/zcl_gg_http_handler.clas.abap](../../framework/http/zcl_gg_http_handler.clas.abap)
