import {test, openExample, dispatch, expectPageKind, expectWorkbench} from "../fixtures.mjs";

test(`ZCL_GG_EX_037 — executes selection exit handling`, async ({page, host}) => {
  await openExample(page, host, 37);
  await expectPageKind(page, "SELECTION");
  // The exit handler runs LEAVE PROGRAM, which ends the transaction the
  // workbench started.
  await dispatch(page, {action: "EXIT", ucomm: "ECAN"});
  await expectWorkbench(page);
});
