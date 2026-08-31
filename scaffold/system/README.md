# System transactions

This folder owns first-class SAP-style workbench and system transactions. They
are registered by their real transaction codes and are not numbered examples.

Planned transactions:

- `SE01` — Transport Organizer (Extended View)
- `SE09` — Transport Organizer
- `SE11` — ABAP Dictionary
- `SE16` — Data Browser
- `SE38` — ABAP Editor

Each transaction implementation and its ABAP Unit companion belong here, using
names such as `zcl_gg_se11.clas.abap` and
`zcl_gg_se11.clas.testclasses.abap`. Shared Dictionary, repository, table-data,
and transport services also belong here when they are specific to this system
transaction family. Browser specs remain under `test/specs/`, one spec per
executable transaction class.

System transactions must use typed server-owned state and the existing host
runtime. They must not add transaction-specific methods to the public
definitions of `cl_gui_control` or `cl_gui_selector`, duplicate the complete
repository/transaction inventory as a test fixture, interpret ABAP in
JavaScript, or report successful persistence, activation, transport release,
or debugging when the corresponding backend capability does not exist.

The implementation sequence and researched SAP behavior are tracked in
[`PLAN8.md`](../PLAN8.md).
