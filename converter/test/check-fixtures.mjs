import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "../src/api.mjs";
import { repositoryRoot } from "./repository.mjs";

const examples = path.join(repositoryRoot, "scaffold", "examples");
const rows = [];
for (let number = 1; number <= 58; number++) {
  const id = String(number).padStart(3, "0");
  const filename = `zgg_ex_${id}.prog.abap`;
  const source = await fs.readFile(path.join(examples, filename), "utf8");
  const metadata = ["020", "032"].includes(id)
    ? { ddicTypes: { ZSFLIGHT: { type: "zsflight", fields: { CARRID: { type: "c", length: 3 } } } } }
    : id === "058"
      ? {
        dynproMetadata: {
          initialScreen: "0100",
          screens: [{ number: "0100", title: "ZCL_GG_EX_058" }, { number: "0200", title: "ZCL_GG_EX_058" }],
          flowLogic: [{ screen: "0100", pbo: [{ name: "STATUS_0100" }], pai: [{ name: "USER_COMMAND_0100" }] }],
          statuses: { "0100": { status: "SCREEN FLOW", activeUcomm: ["NEXT"] } },
        },
      }
      : {};
  const result = await convertProgram({ source, filename, mode: "strict", ...metadata });
  rows.push({
    example: id,
    supported: result.supported,
    programKind: result.reportIR?.programKind,
    diagnostics: result.diagnostics.map((item) => ({ code: item.code, severity: item.severity, construct: item.construct })),
  });
}
console.log(JSON.stringify({ count: rows.length, supported: rows.filter((row) => row.supported).length, deferred: rows.filter((row) => !row.supported).length, rows }, null, 2));
