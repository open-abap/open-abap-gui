# Transpiler anomalies

Record every transpiler statement or construct gap here, including the
affected plan feature, exact source statement, error text, and date observed.

## Open HTML-host limitations

| Feature | Exact statement/limitation | Tool/runtime result | Date | Visible fallback |
| --- | --- | --- | --- | --- |
| Structured ALV row reflection | `ASSIGN COMPONENT ... OF STRUCTURE <row> TO <component>` in the ALV HTML adapter | abaplint rejects dynamic access with `no_dynamic_stuff`; the transpiler gate therefore cannot accept the adapter | 2026-08-28 | The first scalar field or whole-row text is rendered in a safe semantic table cell; field-catalog metadata remains available |
| Browser-only frontend services | Native desktop frontend services, timers, drag/drop, and progress callbacks have no browser-equivalent lifecycle in the current host API | No transpiler construct is involved; the compatibility methods are intentional no-ops | 2026-08-28 | Host state is retained where meaningful and no executable or false browser action is emitted |
