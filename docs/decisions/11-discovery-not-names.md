# The framework never names application classes

Transactions, reports and environment setup are found by interface, not by
class name.

- `zcl_gg_class_discovery` finds the classes implementing an interface: XCO
  where it exists, else the class library, else a scan of the repository
  sources.
- `zcl_gg_transaction_registry` catalogs `zif_gg_transaction_v1` and
  `zcl_gg_program_registry` catalogs `zif_gg_program_v1`. Their metadata
  methods are static, so nothing is instantiated to list them.
- `zif_gg_host_environment_v1` implementations (database fixtures and similar)
  get `setup` before the first program runs and `teardown` on shutdown.

`npm run lint:framework` lints `src/` and `framework/` without the examples, so
a reference to an example class fails there.

Code: [framework/zcl_gg_class_discovery.clas.abap](../../framework/zcl_gg_class_discovery.clas.abap),
[test/lint-framework.mjs](../../test/lint-framework.mjs)
