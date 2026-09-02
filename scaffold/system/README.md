# System transactions

This folder owns first-class SAP-style workbench and system transactions. They
are registered by their real transaction codes and are not numbered examples.

Implemented read-only transactions:

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

## Shared services

- `zif_gg_transport_service_v1` — transport catalog, request-number
  conventions, and per-tab resolution.
- `zif_gg_dictionary_service_v1` — supported Dictionary object kinds and one
  typed detail record per kind.
- `zif_gg_table_data_service_v1` — permitted tables, field metadata, criteria
  validation, and bounded reads.
- `zif_gg_program_repository_v1` — program metadata, source, and variants.
- `zcl_gg_system_request_view` — the transport request editor shared by SE09
  and SE01, so the Transport Organizer and its extended view cannot drift
  apart. It owns screens `0200`–`0240` in both transactions.

## Screens generated from metadata

`SE16` generates one criteria screen and one result table per table the
data-access policy permits, from that table's Dictionary fields. A criterion
control is named after the field *position*, so a browser can never submit a
field name, a sort, or a filter expression. `SE11` gives every supported
object kind its own detail screen rather than one generic property dump.

## Transport-number policy

This deployment's request numbers are three system-id letters, a two-character
category, and five digits. The category belongs to the transport type:

| Transport type | Category | Example |
| --- | --- | --- |
| Standard request | `K9` | `DEVK900001` |
| Piece list | `K9` | `DEVK900010` |
| Client transport | `KO` | `DEVKO00001` |
| Delivery transport | `KD` | `DEVKD00001` |

This is the scaffold's own policy, not a claim about a specific SAP system.
The number convention is only the first check: the catalog record decides
which selection tab may display a request, so a piece list is rejected on the
standard requests tab even though both use `K9`.

## Program states

The repository adapter keeps missing, inactive, non-executable, and
unauthorized programs distinguishable. An unauthorized program is never
reported as missing, and an inactive or non-executable program stays
displayable while execution is refused with its own reason.

The implementation sequence and researched SAP behavior are tracked in
[`PLAN8.md`](../PLAN8.md).
