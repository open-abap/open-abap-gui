import {test, expect, openExample, submit, expectPageKind, statusMessage} from "../fixtures.mjs";

test(`ZCL_GG_EX_040 — renders a message-class response`, async ({page, host}) => {
  await openExample(page, host, 40);
  await expectPageKind(page, "MESSAGE");
  await expect(statusMessage(page)).toHaveText("alpha beta");
  await expect(page.locator("main")).not.toContainText("alpha beta");
});

test(`ZCL_GG_EX_040 — double-clicking the status bar message shows its technical information`, async ({page, host}) => {
  await openExample(page, host, 40);
  const details = page.getByRole("dialog", {name: "Technical information"});
  await expect(details).toBeHidden();

  await statusMessage(page).dblclick();
  await expect(details).toBeVisible();
  const rows = await details.locator("dt").evaluateAll((terms) =>
    terms.map((term) => [term.textContent, term.nextElementSibling.textContent]));
  expect(rows).toEqual([
    ["Message type", "I"],
    ["Message class", "ZGG_EX"],
    ["Message number", "001"],
    ["Variable 1", "alpha"],
    ["Variable 2", "beta"],
    ["Variable 3", ""],
    ["Variable 4", ""],
  ]);
  await expect(details.getByRole("button", {name: "Close technical information"})).toBeFocused();

  // Escape closes the dialog and goes no further: the page stays.
  await page.keyboard.press("Escape");
  await expect(details).toBeHidden();
  await expectPageKind(page, "MESSAGE");

  await statusMessage(page).dblclick();
  await details.getByRole("button", {name: "Close technical information"}).click();
  await expect(details).toBeHidden();
});
