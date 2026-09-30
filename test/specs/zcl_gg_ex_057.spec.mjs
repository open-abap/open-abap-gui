import {test, openExample, submit, expectPageKind, expectWorkbench} from "../fixtures.mjs";

test(`ZCL_GG_EX_057 — LEAVE PROGRAM returns to the workbench`, async ({page, host}) => {
  await openExample(page, host, 57);
  await expectPageKind(page, "SELECTION");
  await submit(page);
  await expectWorkbench(page);
});
