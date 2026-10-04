import {test, expect, openExample, submit} from "../fixtures.mjs";

const result = (page) => page.locator("#gg-dynpro-control-n-GV_RESULT");

test("ZCL_GG_EX_156 — POPUP_TO_CONFIRM returns the chosen answer", async ({page, host}) => {
  await openExample(page, host, 156);
  await submit(page, "Confirm");
  const popup = page.getByRole("dialog", {name: "Cancel booking"});
  await expect(popup).toContainText("Cancel the booking for LH 0400?");
  await expect(popup.getByRole("button")).toHaveText(["Yes", "No"]);
  await submit(page, "No");
  await expect(result(page)).toHaveText("Booking kept");

  await submit(page, "Confirm");
  await submit(page, "Yes");
  await expect(result(page)).toHaveText("Booking cancelled");
});

test("ZCL_GG_EX_156 — POPUP_TO_INFORM shows its text lines", async ({page, host}) => {
  await openExample(page, host, 156);
  await submit(page, "Inform");
  const popup = page.getByRole("dialog", {name: "Flight status"});
  await expect(popup.locator("p")).toHaveText(["Flight LH 0400 is fully booked.", "Choose another connection."]);
  await submit(page, "Close");
  await expect(result(page)).toHaveText("Information acknowledged");
});

test("ZCL_GG_EX_156 — POPUP_GET_VALUES returns the entered value or A", async ({page, host}) => {
  await openExample(page, host, 156);
  await submit(page, "Get values");
  const popup = page.getByRole("dialog", {name: "Choose airline"});
  await expect(popup.getByLabel("Airline", {exact: true})).toHaveValue("LH");
  await popup.getByLabel("Airline", {exact: true}).fill("UA");
  await submit(page, "Apply");
  await expect(result(page)).toHaveText("Airline UA");

  await submit(page, "Get values");
  await submit(page, "Cancel");
  await expect(result(page)).toHaveText("Input cancelled");
});

test("ZCL_GG_EX_156 — POPUP_WITH_TABLE_DISPLAY returns the chosen line", async ({page, host}) => {
  await openExample(page, host, 156);
  await submit(page, "Choose from table");
  const popup = page.getByRole("dialog", {name: "Choose connection"});
  await expect(popup.locator("tbody tr")).toHaveCount(3);
  await submit(page, "UA 0941 Frankfurt - San Francisco");
  await expect(result(page)).toHaveText("UA 0941 Frankfurt - San Francisco");

  await submit(page, "Choose from table");
  await submit(page, "Cancel");
  await expect(result(page)).toHaveText("Selection cancelled");
});
