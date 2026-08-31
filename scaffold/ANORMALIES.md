# Transpiler anomalies

Record every transpiler statement or construct gap here, including the
affected plan feature, exact source statement, error text, and date observed.

## Open HTML-host limitations

| Feature | Exact statement/limitation | Tool/runtime result | Date | Visible fallback |
| --- | --- | --- | --- | --- |
| Browser-only frontend services | Native desktop frontend services, timers, drag/drop, and progress callbacks have no browser-equivalent lifecycle in the current host API | No transpiler construct is involved; the compatibility methods are intentional no-ops | 2026-08-28 | Host state is retained where meaningful and no executable or false browser action is emitted |
