import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_072 - round-trips include and exclude range operators", async ({page, host}) => {
  await openExample(page, host, 72);
  await dispatch(page, {
    action: "SUBMIT",
    values: [
      {
        name: "S_CAR",
        ranges: [
          {sign: "I", option: "EQ", low: "AA"},
          {sign: "E", option: "BT", low: "LH", high: "SQ"},
          {sign: "I", option: "CP", low: "A*"},
        ],
      },
      {name: "P_REQ", value: "ok"},
    ],
  });
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText([
    /^I\s+EQ\s+AA\s*$/,
    /^E\s+BT\s+LH\s+SQ\s*$/,
    /^I\s+CP\s+A\*\s*$/,
  ]);
});
