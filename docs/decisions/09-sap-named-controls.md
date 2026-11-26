# GUI controls keep their SAP names

`src/` reimplements the SAP control classes under their real names:
`cl_gui_alv_grid`, `cl_gui_cfw`, `cl_salv_table`, `cl_gui_column_tree`, ...
Existing code that calls them compiles unchanged.

The frontend half of a control is HTML. On each round trip `cl_gui_cfw` hands
every control the fields its HTML posted (named `gg-ctl:<control_id>:<key>`) and
the event the user triggered. System events are dispatched before PAI,
application events in PAI, as in SAP.

Code: [src/cl_gui_cfw.clas.abap](../../src/cl_gui_cfw.clas.abap),
[src/cl_gui_control.clas.abap](../../src/cl_gui_control.clas.abap)
