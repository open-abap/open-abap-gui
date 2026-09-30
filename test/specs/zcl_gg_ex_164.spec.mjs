import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_164 — a radio group's USER-COMMAND switches MODIF ID select-options", async ({page, host}) => {
  await openExample(page, host, 164);
  await expectPageKind(page, "SELECTION");
  const inbound = page.getByRole("group", {name: "Inbound queue"});
  const outbound = page.locator('.gg-range[aria-label="Outbound queue"]');
  await expect(inbound).toBeVisible();
  await expect(outbound).toBeHidden();

  // USER-COMMAND is declared on the first button only; the second raises it too.
  await Promise.all([
    page.waitForNavigation({waitUntil: "load"}),
    page.getByLabel("Outbound", {exact: true}).check(),
  ]);
  await expect(page.getByLabel("Outbound", {exact: true})).toBeChecked();
  await expect(page.getByLabel("Inbound", {exact: true})).not.toBeChecked();
  await expect(page.getByRole("group", {name: "Outbound queue"})).toBeVisible();
  await expect(page.locator('.gg-range[aria-label="Inbound queue"]')).toBeHidden();

  await Promise.all([
    page.waitForNavigation({waitUntil: "load"}),
    page.getByLabel("Inbound", {exact: true}).check(),
  ]);
  await expect(page.getByRole("group", {name: "Inbound queue"})).toBeVisible();
  await expect(page.locator('.gg-range[aria-label="Outbound queue"]')).toBeHidden();

  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("Cleaning inbound queues");
});
