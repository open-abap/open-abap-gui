# Dependency-free HTML

Pages are built by a small HTML writer in ABAP, with no frontend framework and
no external assets.

- Dynamic values enter HTML only through `escape_text` or `escape_attribute`.
- Icons are a local SVG sprite (Tabler outline set). Callers use semantic
  names, and SAP icon values (`@08@`) and `ICON_*` names resolve through one
  table.

Why: the output works offline and in a single file, and every escaping
decision is in one place.

Code: [framework/zcl_gg_host_html.clas.abap](../../framework/zcl_gg_host_html.clas.abap),
[framework/zcl_gg_host_icons.clas.abap](../../framework/zcl_gg_host_icons.clas.abap)
