import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_150 — applies selection filters to the analytics cockpit", async ({page, host}) => {
  await openExample(page, host, 150);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_CARR"]')).toHaveValue("Lufthansa");
  await page.locator('[name="P_CARR"]').fill("United");
  await submit(page);

  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-cockpit")).toContainText("Carrier: United");
  await expect(page.locator('[data-control-kind="ALV_GRID"]')).toHaveCount(1);
  await expect(page.locator('[data-control-kind="SIMPLE_TREE"]')).toHaveCount(1);
  await expect(page.locator('[data-control-kind="CHART_ENGINE"]')).toHaveCount(1);
  await expect(page.locator("textarea")).toHaveValue(/Detail dynpro pane/);
});

test("ZCL_GG_EX_150 — saves filters through an authorized application action", async ({page, host}) => {
  await openExample(page, host, 150);
  await submit(page);
  await page.locator(".gg-cockpit").getByRole("button", {name: "Save filters"}).click();
  await page.waitForLoadState("networkidle");

  await expect(page.locator(".gg-list-line").last()).toContainText("filters saved");
  await expect(page.locator(".gg-list-status")).toContainText("FILTERS SAVED");
});

test("ZCL_GG_EX_150 — opens the detail dynpro from the cockpit", async ({page, host}) => {
  await openExample(page, host, 150);
  await submit(page);
  await page.locator(".gg-cockpit").getByRole("button", {name: "Open detail dynpro"}).click();
  await page.waitForLoadState("networkidle");

  await expect(page.locator(".gg-list-line").last()).toContainText("Detail dynpro opened");
});

test("ZCL_GG_EX_150 — escapes hostile filter text at the HTML boundary", async ({page, host}) => {
  await openExample(page, host, 150);
  const hostile = '"><script>alert(1)</script>';
  await page.locator('[name="P_CARR"]').fill(hostile);
  await submit(page);

  await expect(page.locator(".gg-cockpit")).toContainText(hostile);
  await expect(page.locator(".gg-cockpit script")).toHaveCount(0);
});
