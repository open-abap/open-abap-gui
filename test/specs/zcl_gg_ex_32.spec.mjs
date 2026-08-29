import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_32 — executes select-option validation`, async ({page, host}) => {
  await openExample(page, host, 32);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
  await dispatch(page, {
    action: "SUBMIT",
    values: [{
      name: "S_CARR",
      ranges: [
        {sign: "I", option: "EQ", low: "AA"},
        {sign: "I", option: "EQ", low: "BA"},
        {sign: "I", option: "EQ", low: "DL"},
        {sign: "I", option: "EQ", low: "JL"},
        {sign: "I", option: "EQ", low: "LH"},
        {sign: "I", option: "EQ", low: "SQ"},
      ],
    }],
  });
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toHaveText("at most five entries");
});
