import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_065 — renders typed breadcrumbs without links", async ({page, host}) => {
  await openExample(page, host, 65);
  const breadcrumbs = page.getByRole("navigation", {name: "Breadcrumb"});
  await expect(breadcrumbs.locator("li")).toHaveCount(3);
  await expect(breadcrumbs).toContainText("Reports");
  await expect(breadcrumbs).toContainText("Shell & <context>");
  await expect(breadcrumbs.locator('[aria-current="page"]')).toHaveText("Current");
  await expect(breadcrumbs.locator('[data-breadcrumb-target="SHELL/65"]')).toHaveText("Shell & <context>");
  await expect(breadcrumbs.locator("a")).toHaveCount(0);
});
