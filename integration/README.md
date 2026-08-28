# Integration test setup

Integration scenarios use the transpiled ABAP runtime and the custom
`ZSFLIGHT` SQLite fixture. They are ABAP Unit test methods in
`scaffold/integration` and run through the generated ABAP Unit runner.

The shared `zcl_gg_integration_db` fixture creates an
`CL_OSQL_TEST_ENVIRONMENT` for `ZSFLIGHT`, inserts typed fixture data in the
ABAP Unit `SETUP` hook, and destroys the test double in `CLASS_TEARDOWN`.
The empty-database case clears the double explicitly.

The complete suite is run with:

```text
npm test
```

For only the transpiled ABAP Unit runner, use:

```text
npm run unit
```

JavaScript is used only by the transpiler setup hook to create the base SQLite
schema. Test rows and per-test isolation are owned by the ABAP Unit fixture.
CI runs `npm test` on every push and pull request.

## Host/runtime differences

The fixture is deterministic SQLite data, not a connection to an SAP system.
Transaction and authorization cases therefore verify the host's recorded
control-flow and message boundaries; they do not execute SAP GUI or a real
backend transaction. Variants are process-local test state rather than SAP's
persistent variant repository.

The runtime currently cannot evaluate `IN @range` for a `BT` range. The
selection scenarios use equivalent `BETWEEN` and explicit `OR` predicates so
the database behavior remains covered while that host limitation is visible.
Database-backed test classes reset the double before each test and create a
fresh host session, with no timing or eventual-consistency dependency.
