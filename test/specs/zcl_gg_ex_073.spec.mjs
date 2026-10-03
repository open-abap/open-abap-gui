import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_073 - starts with the default row and writes every range row", async ({page, host}) => {
  await openExample(page, host, 73);
  await expect(page.locator('[name="S_MUL-LOW"]')).toHaveValue("AA");
  await dispatch(page, {
    action: "SUBMIT",
    values: [
      {
        name: "S_MUL",
        ranges: [
          {sign: "I", option: "EQ", low: "AA"},
          {sign: "I", option: "EQ", low: "LH"},
        ],
      },
      {name: "P_REQ", value: "ok"},
    ],
  });
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText([/^I\s+EQ\s+AA\s*$/, /^I\s+EQ\s+LH\s*$/]);
});
