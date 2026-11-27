# Converter

The converter turns each executable report (and, optionally, each module pool)
into a global class. It is a pipeline of passes over abaplint's syntax tree.

```text
source + includes ─► parse ─► collect ─► analyze ─► lower ─► emit
                     abaplint  passes/   passes/    passes/   emit/
```

| step | what happens | code |
| --- | --- | --- |
| resolve | find the program, its includes, texts and dynpro metadata | `source-resolver.ts`, `dynpro-metadata.ts` |
| parse | split into statements, build syntax trees | `parser.ts`, `abap/` |
| collect | declarations, events, selection screens, FORMs, modules, local classes | `passes/collect-*.ts` |
| analyze | types, references, field symbols, header lines, control flow | `passes/analyze-*.ts`, `passes/resolve-*.ts`, `passes/control-flow.ts` |
| lower | report state to attributes, statements to session calls, suspensions to continuations | `passes/lower-*.ts` |
| emit | class source, helper classes, XML, manifest | `emit/` |

Along the way it builds three intermediate representations in `ir/`: the
report IR (what the program contains), the dynpro IR (its screens) and the
scaffold IR (what the generated class will implement).

The output is a class implementing `zif_gg_report_v1` (or `zif_gg_dynpro_v1`
for a module pool), plus `zif_gg_transaction_v1` or `zif_gg_program_v1` so the
workbench can find it, and `zif_gg_resumable_v1` when the program calls screens
or other programs.

Entry points: `convertProgram` in [api.ts](../../converter/src/api.ts) and the
CLI in [converter/bin/](../../converter/bin/). Details are in
[converter/README.md](../../converter/README.md).
