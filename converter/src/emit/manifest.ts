import { CONVERTER_VERSION, MANIFEST_SCHEMA_VERSION } from "../options.js";
import { sortDiagnostics } from "../diagnostics.js";
import { compatibilityAdapter } from "../function-modules.js";
import { functionModule } from "../abap/statements.js";

import type { Diagnostic, LocalClass, Metadata, NormalizedOptions, ReportIR, Routine, Statement } from "../types.js";

// The value with the keys of every object sorted, so the manifest is the same
// whatever order it was built in.
function stable(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === "object") return Object.fromEntries(Object.keys(value).sort().map((key) => [key, stable((value as Record<string, unknown>)[key])]));
  return value;
}

export function createManifest(ir: ReportIR, diagnostics: Diagnostic[], options: NormalizedOptions & Metadata): Metadata {
  const features = [...new Set(ir.features)].sort();
  const compatibilityAdapters = [...new Set((ir.statements ?? [])
    .map((statement: Statement) => statement.kind === "CallFunction" ? functionModule(statement.text) : undefined)
    .filter((name): name is string => Boolean(name && compatibilityAdapter(name))))]
    .sort();
  return stable({
    converterVersion: options.converterVersion ?? CONVERTER_VERSION,
    manifestSchema: MANIFEST_SCHEMA_VERSION,
    ...(options.partialStrategy === "skeleton" ? {partialStrategy: "skeleton"} : {}),
    sourceObject: ir.programName,
    sourceFilename: ir.source.filename,
    sourceHash: ir.source.sourceHash,
    targetClass: ir.targetClassName,
    helperClasses: (ir.localClasses ?? []).map((localClass: LocalClass) => ({ sourceName: localClass.name, targetClass: localClass.generatedName })).filter((item) => item.targetClass),
    transactionCode: ir.transactionCode,
    programKind: ir.programKind,
    interfaces: [...ir.interfaces].sort(),
    includes: ir.units.map((unit) => unit.filename).sort(),
    metadataInputs: {
      dynpro: Boolean(ir.dynproMetadata),
      screenProvider: Boolean(ir.screenMetadata),
      ddicTypes: Boolean(options.ddicTypes),
      compatibilityAdapters,
      resolvedTypes: Object.keys(ir.resolvedTypes ?? {}).sort(),
    },
    identifierRenames: ir.statePlan?.renames ?? {},
    state: ir.statePlan ? {
      globals: ir.statePlan.globals,
      selections: ir.statePlan.selections,
      selectionState: ir.statePlan.selectionState,
      hydration: ir.statePlan.hydration,
      flush: ir.statePlan.flush,
      systemFields: ir.statePlan.systemFields,
    } : {},
    features,
    capabilities: ir.capabilities ?? [],
    unsupportedFeatures: sortDiagnostics(diagnostics).filter((item) => item.code.startsWith("GGCONV-E")).map((item) => item.code),
    diagnostics: {
      errors: diagnostics.filter((item) => item.severity === "error").length,
      warnings: diagnostics.filter((item) => item.severity === "warning").length,
      infos: diagnostics.filter((item) => item.severity === "info").length,
    },
    sourceToOutput: Object.fromEntries([
      ...Object.keys(ir.events ?? {}).map((name) => [name, `${ir.targetClassName}~${name}`]),
      ...(ir.routines ?? []).map((routine: Routine) => [routine.name, `${ir.targetClassName}~${routine.methodName}`]),
    ].sort(([left], [right]) => left.localeCompare(right))),
  }) as Metadata;
}
