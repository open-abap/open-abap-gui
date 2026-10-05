import {test, expect, openExample, statusMessage} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

const cases = [
  {button: "Status message", text: "Flight saved", kind: "wb-status-success", state: "PAI went on after S"},
  {button: "Information", text: "Seats are limited", kind: "wb-status-info", state: "PAI went on after I"},
  {button: "Warning", text: "The flight is almost full", kind: "wb-status-warning", state: ""},
  {button: "Error", text: "The flight is fully booked", kind: "wb-status-error", state: ""},
  {button: "Status like error", text: "Saved, but check the seats", kind: "wb-status-error", state: "PAI went on after S like E"},
];

for (const item of cases) {
  test(`ZCL_GG_EX_114 — ${item.button}: ${item.state || "PAI stops"}`, async ({page, host}) => {
    await openExample(page, host, 114);
    await page.getByRole("button", {name: item.button, exact: true}).click();
    await page.waitForLoadState("load");
    await expect(statusMessage(page)).toHaveText(item.text);
    await expect(statusMessage(page)).toHaveClass(new RegExp(item.kind));
    await expect(page.locator("main")).not.toContainText(item.text);
    await expect(out(page, "GV_STATE")).toHaveText(item.state);
  });
}
