# Messages live in the status bar

Every message goes to the status bar at the bottom, never into the page body.
The last message sent wins, and it keeps its ABAP type (E, A and X are errors,
W is a warning, ...).

Why: a message cannot move or shrink the screen below it.

Code: [framework/zcl_gg_host_html.clas.abap](../../framework/zcl_gg_host_html.clas.abap),
[framework/zcl_gg_workbench_utility.clas.abap](../../framework/zcl_gg_workbench_utility.clas.abap)
