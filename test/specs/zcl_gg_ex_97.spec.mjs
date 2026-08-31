import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_97 — nested list memory resumes into the caller list", async ({page, host}) => {
  await openExample(page, host, 97);
  await expectPageKind(page, "NAVIGATION");
  await submit(page, "Continue");
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list")).toContainText("nested submit memory: hello world");
});

