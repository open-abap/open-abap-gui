import type { ReportIR, SourceIndex, SourceSymbol } from "./types.js";

export function buildSourceIndex(ir: ReportIR): SourceIndex {
  const symbols: SourceSymbol[] = [];
  for (const declaration of ir.declarations) {
    const names = declaration.names ?? (declaration.name ? [declaration.name] : []);
    for (const name of names) {
      symbols.push({
        name,
        kind: declaration.kind,
        scope: declaration.statement?.scope,
        localClassName: declaration.statement?.localClassName,
        filename: declaration.statement.filename,
        span: declaration.statement.span,
      });
    }
  }
  for (const routine of ir.routines) {
    symbols.push({ name: routine.name, kind: "form", filename: routine.statement.filename, span: routine.statement.span });
  }
  symbols.sort((a, b) => a.name.localeCompare(b.name) || a.kind.localeCompare(b.kind) || a.filename.localeCompare(b.filename));
  const byName: Record<string, SourceSymbol[]> = Object.create(null);
  for (const symbol of symbols) (byName[symbol.name] ??= []).push(symbol);
  // A FORM becomes a method form_<name>, a program global a class attribute of
  // its own name: a FORM named like a data object, legal in ABAP, does not
  // collide with it.
  const sharedByName = Object.fromEntries(Object.entries(byName).map(([name, values]) => [
    name,
    values.filter((symbol) => symbol.scope !== "local" && !symbol.localClassName),
  ]));
  const collides = (values: SourceSymbol[]) => values.filter((symbol) => symbol.kind === "form").length > 1
    || values.filter((symbol) => symbol.kind !== "form").length > 1;
  return {
    symbols,
    byName,
    collisions: Object.fromEntries(Object.entries(sharedByName).filter(([, values]) => collides(values))),
  };
}
