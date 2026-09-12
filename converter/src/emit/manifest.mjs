import { CONVERTER_VERSION, MANIFEST_SCHEMA_VERSION } from "../options.mjs";
import { sortDiagnostics } from "../diagnostics.mjs";
import { compatibilityAdapter, functionModuleName } from "../function-modules.mjs";

function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === "object") return Object.fromEntries(Object.keys(value).sort().map((key) => [key, stable(value[key])]));
  return value;
}

export function createManifest(ir, diagnostics, options) {
  const features = [...new Set(ir.features)].sort();
  const compatibilityAdapters = [...new Set((ir.statements ?? [])
    .map((statement) => functionModuleName(statement.text))
    .filter((name) => name && compatibilityAdapter(name)))]
    .sort();
  return stable({
    converterVersion: options.converterVersion ?? CONVERTER_VERSION,
    manifestSchema: MANIFEST_SCHEMA_VERSION,
    ...(options.partialStrategy === "skeleton" ? {partialStrategy: "skeleton"} : {}),
    sourceObject: ir.programName,
    sourceFilename: ir.source.filename,
    sourceHash: ir.source.sourceHash,
    targetClass: ir.targetClassName,
    helperClasses: (ir.localClasses ?? []).map((localClass) => ({ sourceName: localClass.name, targetClass: localClass.generatedName })).filter((item) => item.targetClass),
    transactionCode: ir.transactionCode,
    programKind: ir.programKind,
    interfaces: [...ir.interfaces].sort(),
    includes: ir.units.map((unit) => unit.filename).sort(),
    metadataInputs: {
      dynpro: Boolean(ir.dynproMetadata),
      screenProvider: Boolean(ir.screenMetadata),
      ddicTypes: Boolean(options.ddicTypes ?? options.dictionaryTypes ?? options.dictionary),
      compatibilityAdapters,
      messages: ir.messageMetadata ?? { supplied: false },
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
    supportedFeatures: features,
    capabilities: ir.capabilities ?? [],
    unsupportedFeatures: sortDiagnostics(diagnostics).filter((item) => item.code.startsWith("GGCONV-E")).map((item) => item.code),
    diagnostics: {
      errors: diagnostics.filter((item) => item.severity === "error").length,
      warnings: diagnostics.filter((item) => item.severity === "warning").length,
      infos: diagnostics.filter((item) => item.severity === "info").length,
    },
    sourceToOutput: Object.fromEntries([
      ...Object.keys(ir.events ?? {}).map((name) => [name, `${ir.targetClassName}~${name}`]),
      ...(ir.routines ?? []).map((routine) => [routine.name, `${ir.targetClassName}~${routine.methodName}`]),
    ].sort(([left], [right]) => left.localeCompare(right))),
  });
}

export function manifestJSON(manifest) {
  return `${JSON.stringify(stable(manifest), null, 2)}\n`;
}
