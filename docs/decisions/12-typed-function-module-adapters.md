# Function modules go through typed adapters

Classic GUI function modules (popups, ALV, F4, variants, list memory, ...) are
not called by name. The converter maps a finite list of known families to
typed methods of `zif_gg_compatibility_v1`, and the manifest records which
adapters a conversion used. Unknown function modules stay diagnostics.

Why: nothing is dispatched dynamically on a string, and an unsupported call
shows up at conversion time instead of at runtime.

Code: [framework/zif_gg_compatibility_v1.intf.abap](../../framework/zif_gg_compatibility_v1.intf.abap),
[converter/src/function-modules.ts](../../converter/src/function-modules.ts)
