import assert from "node:assert/strict";

import {
  clearDatabase,
  resetDatabase,
} from "./integration-setup.mjs";

export async function resetScenario(options = {}) {
  if (options.empty === true) {
    await clearDatabase();
  } else {
    await resetDatabase();
  }
}

export function assertScreen(result, expectedScreen, message = "screen") {
  assert.equal(result.screen, expectedScreen, message);
}

export function assertList(result, expectedLines, message = "list lines") {
  assert.deepEqual(result.lines, expectedLines, message);
}

export function assertListMetadata(result, expectedFormats, message = "list formats") {
  assert.deepEqual(result.line_formats, expectedFormats, message);
}

export function assertTransaction(result, expectedTerminal, message = "transaction flow") {
  assert.equal(result.terminal, expectedTerminal, message);
}
