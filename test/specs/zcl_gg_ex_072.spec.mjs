import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_072 - round-trips include and exclude range operators", async ({page, host}) => {
  await openExample(page, host, 72);
  await dispatch(page, {
    action: "SUBMIT",
    values: [
      {
        name: "S_CARRIER",
        ranges: [
          {sign: "I", option: "EQ", low: "AA"},
          {sign: "E", option: "BT", low: "LH", high: "SQ"},
          {sign: "I", option: "CP", low: "A*"},
        ],
      },
      {name: "P_REQUIRED", value: "ok"},
    ],
  });
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText([
    "I EQ AA",
    "E BT LH - SQ",
    "I CP A*",
  ]);
});
