import assert from "node:assert/strict";
import test from "node:test";
import { previewProgram, previewRepositoryProgram } from "../../src/workbench-preview.mjs";
import { createWorkbenchService } from "../../src/workbench-service.mjs";
import { createWorkbenchPreviewHandlers } from "../../src/workbench-http.mjs";

const source = "REPORT zpreview.\nSTART-OF-SELECTION.\nWRITE 'preview'.\n";

test("workbench preview requires an explicit target and never returns source before inspection", async () => {
  const result = await previewProgram({ source, filename: "zpreview.prog.abap" });
  assert.equal(result.repositoryChanged, false);
  assert.equal(result.classSource, undefined);
  assert.equal(result.sourceAvailable, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E601"));
});

test("workbench preview reports collisions before offering generated source", async () => {
  const blocked = await previewProgram({
    source,
    filename: "zpreview.prog.abap",
    className: "ZCL_PREVIEW",
    existingClassNames: ["zcl_preview"],
    includeSource: true,
  });
  assert.equal(blocked.sourceAvailable, false);
  assert.equal(blocked.classSource, undefined);
  assert.ok(blocked.diagnostics.some((item) => item.code === "GGCONV-E602"));

  const confirmed = await previewProgram({
    source,
    filename: "zpreview.prog.abap",
    className: "ZCL_PREVIEW",
    existingClassNames: ["zcl_preview"],
    collisionConfirmed: true,
    includeSource: true,
  });
  assert.equal(confirmed.repositoryChanged, false);
  assert.equal(confirmed.sourceAvailable, true);
  assert.match(confirmed.classSource, /CLASS zcl_preview DEFINITION/);
});

test("repository preview is read-only and uses the adapter's source", async () => {
  let reads = 0;
  const result = await previewRepositoryProgram({
    program: "ZPREVIEW",
    className: "ZCL_PREVIEW",
    includeSource: true,
    repository: {
      async getProgram(program) {
        reads++;
        assert.equal(program, "ZPREVIEW");
        return { filename: "ZPREVIEW.prog.abap", source };
      },
    },
  });
  assert.equal(reads, 1);
  assert.equal(result.repositoryChanged, false);
  assert.equal(result.repositoryRevision, undefined);
  assert.equal(result.sourceAvailable, true);
  assert.match(result.classSource, /preview/);
});

test("repository preview carries its revision for a separately authorized save", async () => {
  const result = await previewRepositoryProgram({
    program: "ZPREVIEW",
    className: "ZCL_PREVIEW",
    repository: {
      async getProgram() {
        return { filename: "ZPREVIEW.prog.abap", revision: "7", source };
      },
    },
  });
  assert.equal(result.repositoryRevision, "7");
});

test("workbench mutation is behind authorization, CSRF, and revision checks", async () => {
  const calls = [];
  const service = createWorkbenchService({
    repository: {
      async getProgram() {
        return { filename: "ZPREVIEW.prog.abap", revision: "7", source };
      },
      async saveProgram(payload) {
        calls.push(payload);
        return { revision: "8" };
      },
    },
  });

  const unauthorized = await service.save({
    program: "ZPREVIEW",
    className: "ZCL_PREVIEW",
    expectedRevision: "7",
    authorize: async () => false,
    validateCsrf: async () => true,
  });
  assert.equal(unauthorized.repositoryChanged, false);
  assert.ok(unauthorized.diagnostics.some((item) => item.code === "GGCONV-E611"));
  assert.equal(calls.length, 0);

  const csrfRejected = await service.save({
    program: "ZPREVIEW",
    className: "ZCL_PREVIEW",
    expectedRevision: "7",
    authorize: async () => true,
    validateCsrf: async () => false,
  });
  assert.equal(csrfRejected.repositoryChanged, false);
  assert.ok(csrfRejected.diagnostics.some((item) => item.code === "GGCONV-E612"));
  assert.equal(calls.length, 0);

  const stale = await service.save({
    program: "ZPREVIEW",
    className: "ZCL_PREVIEW",
    expectedRevision: "6",
    authorize: async () => true,
    validateCsrf: async () => true,
  });
  assert.equal(stale.repositoryChanged, false);
  assert.ok(stale.diagnostics.some((item) => item.code === "GGCONV-E614"));
  assert.equal(calls.length, 0);

  const saved = await service.save({
    program: "ZPREVIEW",
    className: "ZCL_PREVIEW",
    expectedRevision: "7",
    authorize: async () => true,
    validateCsrf: async () => true,
  });
  assert.equal(saved.repositoryChanged, true);
  assert.equal(saved.saved, true);
  assert.equal(calls.length, 1);
  assert.match(calls[0].source, /CLASS zcl_preview DEFINITION/);
});

test("display-only workbench repositories reject mutation after preview", async () => {
  const service = createWorkbenchService({
    repository: {
      async getProgram() {
        return { filename: "ZPREVIEW.prog.abap", revision: "7", source };
      },
    },
  });
  const result = await service.save({
    program: "ZPREVIEW",
    className: "ZCL_PREVIEW",
    expectedRevision: "7",
    authorize: async () => true,
    validateCsrf: async () => true,
  });
  assert.equal(result.repositoryChanged, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E615"));
});

test("workbench mutation rechecks the repository revision before writing", async () => {
  let reads = 0;
  let writes = 0;
  const service = createWorkbenchService({
    repository: {
      async getProgram() {
        reads++;
        return { filename: "ZPREVIEW.prog.abap", revision: reads === 1 ? "7" : "8", source };
      },
      async saveProgram() {
        writes++;
      },
    },
  });
  const result = await service.save({
    program: "ZPREVIEW",
    className: "ZCL_PREVIEW",
    expectedRevision: "7",
    authorize: async () => true,
    validateCsrf: async () => true,
  });
  assert.equal(result.repositoryChanged, false);
  assert.ok(result.diagnostics.some((item) => item.code === "GGCONV-E614"));
  assert.equal(writes, 0);
});

test("HTTP workbench save is exposed only with an authorized writer and current revision", async () => {
  const writes = [];
  const repository = {
    async getProgram() {
      return { filename: "ZPREVIEW.prog.abap", revision: "7", source };
    },
    async getProgramNames() {
      return ["ZPREVIEW"];
    },
    async saveProgram(payload) {
      writes.push(payload);
      return { revision: "8" };
    },
  };
  const handlers = createWorkbenchPreviewHandlers({
    runtime: {Classes: {}},
    repository,
    csrfToken: "csrf-7",
    authorize: async ({action}) => action === "save",
    validateCsrf: async ({token, page}) => token === "csrf-7" && Boolean(page),
  });
  const makeResponse = () => ({
    body: "",
    statusCode: 200,
    type() { return this; },
    set() { return this; },
    status(code) { this.statusCode = code; return this; },
    send(body) { this.body = body; return this; },
  });

  const inspected = makeResponse();
  await handlers.post({body: Buffer.from("action=inspect&program=ZPREVIEW&className=ZCL_PREVIEW&transactionCode=ZPREVIEW")}, inspected);
  assert.match(inspected.body, /Save generated class/);
  const token = /name="token" value="([^"]+)"/.exec(inspected.body)?.[1];
  assert.ok(token);

  const saved = makeResponse();
  await handlers.save({body: Buffer.from(`action=save&token=${token}&csrfToken=csrf-7&pageToken=${token}`)}, saved);
  assert.equal(saved.statusCode, 200);
  assert.match(saved.body, /data-save-boundary/);
  assert.match(saved.body, /CLASS zcl_preview DEFINITION/);
  assert.equal(writes.length, 1);
  assert.equal(writes[0].expectedRevision, "7");
});
