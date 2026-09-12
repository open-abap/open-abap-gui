# Converter regression fixtures

Each entry below names the failure mode that prompted the fixture and the
automated check that keeps it covered. New converter defects should add a
fixture here before their plan checkbox is marked complete.

| ID | Failure mode | Fixture | Automated check |
| --- | --- | --- | --- |
| `GGCONV-REG-001` | nested includes were flattened after the owning event, hiding declarations and FORM routines | `composite_nested_includes.abap.txt` | composite unit and behavioral tests |
| `GGCONV-REG-002` | Open SQL `SELECT ... INTO TABLE` was indented as a control-flow block | `composite_sql_form.abap.txt` | composite unit and seeded SQLite behavior |
| `GGCONV-REG-003` | implicit-header-table loops were copied into methods without a legality diagnostic | `regression_implicit_loop.abap.txt` | method-legality unit test |
| `GGCONV-REG-004` | nested conditional continuation resumed sibling branches | `regression_nested_continuation.abap.txt` | continuation unit test |
| `GGCONV-REG-005` | dynpro global state was lost across PBO/PAI requests and helper indentation broke generated ABAP | `regression_dynpro_state.prog.abap.txt` | generated dynpro host behavior test |
| `GGCONV-REG-006` | local-class content could be omitted without a visible migration marker | `composite_local_class.abap.txt` | partial-conversion diagnostic unit test |
| `GGCONV-REG-007` | structured, internal-table, reference, and elementary type declarations were not represented in class state | `regression_declaration_shapes.abap.txt` | declaration-shape unit and transpile tests |
| `GGCONV-REG-008` | method-safe exception blocks were rejected even though their control flow is valid inside a method | `regression_exception_block.abap.txt` | exception-block unit and transpile tests |
| `GGCONV-REG-009` | valid dynamic WRITE substring operands were misclassified as calls instead of being lowered | `regression_dynamic_write.abap.txt` | dynamic-WRITE unit and transpile tests |
| `GGCONV-REG-010` | supported dynamic WRITE variable names were rejected instead of evaluating the name once and dispatching only to known targets | inline unit fixture | dynamic-WRITE lowering and generated-source validation |
| `GGCONV-REG-011` | balanced dynamic WRITE name expressions were truncated at their first nested parenthesis | inline unit fixture | dynamic-WRITE expression unit, transpile, and host behavior validation |
| `GGCONV-REG-012` | call-like dynamic WRITE operands were accepted without a safe target-dispatch rule | `regression_dynamic_write_call.abap.txt` | dynamic-WRITE diagnostic unit and transpile tests |
| `GGCONV-REG-013` | unsupported parser-representable dynamic WRITE operands lost expression evaluation entirely | `regression_dynamic_write_fallback.abap.txt` | dynamic-WRITE fallback unit and transpile tests |
