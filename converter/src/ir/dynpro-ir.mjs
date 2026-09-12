export function dynproProgramIR(reportIR) {
  return {
    kind: "dynpro-program",
    programName: reportIR.programName,
    source: reportIR.source,
    units: reportIR.units,
    declarations: reportIR.declarations,
    statements: reportIR.statements,
    modules: reportIR.modules,
    metadata: reportIR.dynproMetadata,
    statePlan: reportIR.statePlan,
  };
}
