# Program end returns to the caller

When a program ends, the user goes back to where it was started from: the
calling program after `CALL TRANSACTION` or `SUBMIT ... AND RETURN`, otherwise
the workbench, with the program's last message in the status bar. There is no
separate "program ended" page.

Code: [framework/zcl_gg_host_runtime.clas.abap](../../framework/zcl_gg_host_runtime.clas.abap) (`caller`),
[framework/http/zcl_gg_http_handler.clas.abap](../../framework/http/zcl_gg_http_handler.clas.abap) (`send_runtime_response`)
