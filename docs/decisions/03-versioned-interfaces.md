# Versioned interfaces

The contract between a generated class and the host is a set of interfaces
with a version suffix: `zif_gg_report_v1`, `zif_gg_dynpro_v1`,
`zif_gg_session_v1`, `zif_gg_list_writer_v1`, and so on.

- Builders (`zif_gg_sel_screen_builder_v1`, `zif_gg_dynpro_builder_v1`)
  are command sinks with separate methods per kind, so invalid combinations
  cannot be expressed.
- Shared vocabulary lives in `*_types_v1` interfaces.
- An incompatible change needs a new version and a new major converter release.

Why: consumers commit generated code; the host must be able to change without
breaking classes generated earlier.

Code: [framework/](../../framework/) (`zif_gg_*_v1.intf.abap`)
