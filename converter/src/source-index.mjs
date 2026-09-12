export function buildSourceIndex(ir) {
  const symbols = [];
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
  const byName = Object.create(null);
  for (const symbol of symbols) (byName[symbol.name] ??= []).push(symbol);
  const sharedByName = Object.fromEntries(Object.entries(byName).map(([name, values]) => [
    name,
    values.filter((symbol) => symbol.scope !== "local" && !symbol.localClassName),
  ]));
  return {
    symbols,
    byName,
    collisions: Object.fromEntries(Object.entries(sharedByName).filter(([, values]) => values.length > 1)),
  };
}
