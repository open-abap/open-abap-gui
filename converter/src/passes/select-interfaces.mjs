export function selectInterfaces(ir) {
  const interfaces = new Set(ir.interfaces);
  if (ir.features.includes("list-processing")) interfaces.add("zif_gg_list_processing_v1");
  if (ir.features.includes("continuation")) interfaces.add("zif_gg_resumable_v1");
  if (ir.screenMetadata && ir.programKind === "report") interfaces.add("zif_gg_screen_provider_v1");
  if (ir.programKind === "module-pool") {
    interfaces.delete("zif_gg_report_v1");
    interfaces.delete("zif_gg_screen_provider_v1");
    interfaces.add("zif_gg_dynpro_v1");
  }
  ir.interfaces = [...interfaces].sort();
  return ir.interfaces;
}
