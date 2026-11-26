# Controls

`src/` holds the SAP GUI classes under their SAP names, so programs using them
compile unchanged.

| area | classes |
| --- | --- |
| control framework | `cl_gui_cfw`, `cl_gui_control` |
| containers | custom, docking, dialog box, splitter |
| ALV grid | `cl_gui_alv_grid`, `src/alv/` |
| SALV | `cl_salv_table` and friends in `src/salv/` |
| trees | `cl_gui_column_tree`, plus tree controls, tree models and `cl_gui_alv_tree` in `src/tree/` |
| other | `cl_gui_html_viewer`, `cl_gui_calendar`, `cl_gui_timer`, `cl_ctmenu`, `cl_abap_browser`, ... |

## How a control works

- **Backend half**: the ABAP object, created and called by the program as in SAP.
- **Frontend half**: HTML, produced on every render by
  `zcl_gg_gui_runtime=>render_html`.

On each round trip:

1. The browser posts the fields of every control, named
   `gg-ctl:<control_id>:<key>`, and the event the user triggered.
2. Before PAI, `cl_gui_cfw` hands each control its values and runs system
   event handlers.
3. Application events wait for `cl_gui_cfw=>dispatch` in PAI, or are
   dispatched at the end of PAI.

Control state is static, and is saved and restored per GUI session and around
calls to other programs, see `save_state` and `restore_state`.
