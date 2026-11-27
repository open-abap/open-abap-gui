# src/ stands on its own

`src/` holds the SAP-named classes (see [9](09-sap-named-controls.md)).
`framework/` holds the host, the runtime and everything else prefixed
`zcl_gg_`/`zif_gg_`. Dependencies go from `framework/` to `src/`, rarely the
other way.

- `src/` should have few to no references into `framework/`. Each one that
  remains needs a reason.
- Public sections in `src/` never reference `framework/`. They are the SAP API
  that existing code compiles against, and SAP's definitions do not mention
  `zcl_gg_` classes.
- Static data in `src/` (`CLASS-DATA`, constants) is never typed with a
  `framework/` type. It is evaluated when the class loads, so it fails even if
  no method using it is ever called.

Consumers such as abapGit load only `src/` as a transpiler library
(`files: /src/**`). Any `framework/` reference they reach fails with "Void
type: ZCL_GG_...". Where `src/` needs a framework type in a declaration, it
declares a structurally identical type of its own.

`npm run regression` runs the abapGit unit tests against `src/`.

Code: [src/](../../src/), [framework/](../../framework/)
