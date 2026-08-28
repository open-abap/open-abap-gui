# Integration test harness

Integration scenarios use the transpiled ABAP runtime and the custom
`ZSFLIGHT` SQLite fixture. They are named `*.integration.mjs` and use the
helpers in `integration/harness.mjs` for deterministic setup and observable
result assertions.

Each scenario must reset the fixture before it runs. Use
`resetScenario({ empty: true })` for an empty-database case. A normal host run
creates a fresh session, so resetting the fixture plus starting a new run
resets both database and runtime state.

The existing ABAP unit suite is run with:

```text
npm test
```

The focused integration suite rebuilds the transpiled runtime and will be run
with:

```text
npm run integration
```

`npm test` is the standard verification command and includes both the ABAP
unit suite and the focused integration suite. CI runs that command on every
push and pull request.

## Host/runtime differences

The fixture is deterministic SQLite data, not a connection to an SAP system.
Transaction and authorization cases therefore verify the host’s recorded
control-flow and message boundaries; they do not execute SAP GUI or a real
backend transaction. Variants are process-local test state rather than SAP’s
persistent variant repository.

The runtime currently cannot evaluate `IN @range` for a `BT` range. The
selection scenarios use equivalent `BETWEEN` and explicit `OR` predicates so
the database behavior remains covered while that host limitation is visible.
All scenarios reset the fixture and create a fresh session, with no timing or
eventual-consistency dependency.
