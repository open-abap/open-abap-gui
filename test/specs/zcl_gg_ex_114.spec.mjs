import {test, expect, openExample} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

const cases = [
  {button: "Status message", text: "Flight saved", kind: ".gg-success", state: "PAI went on after S"},
  {button: "Information", text: "Seats are limited", kind: ".gg-info", state: "PAI went on after I"},
  {button: "Warning", text: "The flight is almost full", kind: ".gg-warning", state: ""},
  {button: "Error", text: "The flight is fully booked", kind: ".gg-error", state: ""},
  {button: "Status like error", text: "Saved, but check the seats", kind: ".gg-error", state: "PAI went on after S like E"},
];

for (const item of cases) {
  test(`ZCL_GG_EX_114 — ${item.button}: ${item.state || "PAI stops"}`, async ({page, host}) => {
    await openExample(page, host, 114);
    await page.getByRole("button", {name: item.button, exact: true}).click();
    await page.waitForLoadState("load");
    await expect(page.locator(`.gg-message${item.kind}`)).toContainText(item.text);
    await expect(out(page, "GV_STATE")).toHaveText(item.state);
  });
}
