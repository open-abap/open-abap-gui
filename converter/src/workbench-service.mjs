import { diagnostic, sortDiagnostics } from "./diagnostics.mjs";
import { previewProgram, previewRepositoryProgram } from "./workbench-preview.mjs";

function serviceDiagnostic(code, construct, message, suggestion, filename) {
  return diagnostic({
    code,
    filename: filename ?? "program.prog.abap",
    construct,
    message,
    suggestion,
    phase: "workbench-service",
  });
}

function boolResult(value) {
  return value === true || value?.allowed === true || value?.valid === true;
}

function revisionOf(record) {
  return record?.revision === undefined || record?.revision === null
    ? undefined
    : String(record.revision);
}

function revisionMatches(record, expectedRevision) {
  const current = revisionOf(record);
  if (current === undefined) return expectedRevision === null || expectedRevision === undefined;
  return String(expectedRevision) === current;
}

function readRepository(repository) {
  return {
    async getProgram(program) {
      return repository.getProgram(program);
    },
  };
}

function resultWithDiagnostics(base, diagnostics) {
  const sorted = sortDiagnostics(diagnostics);
  return {
    ...base,
    repositoryChanged: false,
    diagnostics: sorted,
    supported: false,
  };
}

/**
 * Build the workbench boundary around the converter. Preview is read-only;
 * create/save are deliberately separate operations and can only reach a
 * repository writer after authorization, CSRF, and revision checks succeed.
 * A display-only repository simply omits the writer methods and receives a
 * visible capability diagnostic instead of a false success.
 */
export function createWorkbenchService({ repository, converter } = {}) {
  if (!repository || typeof repository.getProgram !== "function") {
    throw new TypeError("workbench service requires a repository getProgram adapter");
  }

  const readOnly = readRepository(repository);

  async function preview(request = {}) {
    const input = { ...request, converter };
    if (typeof request.source === "string") return previewProgram(input);
    return previewRepositoryProgram({ ...input, repository: readOnly });
  }

  async function mutate(action, request = {}) {
    const filename = request.filename ?? `${request.program ?? "program"}.prog.abap`;
    const diagnostics = [];
    const writer = action === "create" ? repository.createProgram : repository.saveProgram;

    if (typeof request.authorize !== "function" || !boolResult(await request.authorize({
      action,
      program: request.program,
      className: request.className,
    }))) {
      diagnostics.push(serviceDiagnostic(
        "GGCONV-E611",
        "repository mutation",
        `${action} is not authorized for this workbench request`,
        "Obtain an explicit repository authorization decision before attempting the operation.",
        filename,
      ));
      return resultWithDiagnostics({ kind: `conversion-${action}`, targetClassName: request.className }, diagnostics);
    }

    if (typeof request.validateCsrf !== "function" || !boolResult(await request.validateCsrf({
      action,
      token: request.csrfToken,
      page: request.pageToken,
    }))) {
      diagnostics.push(serviceDiagnostic(
        "GGCONV-E612",
        "mutation request",
        "conversion mutation request failed CSRF validation",
        "Submit a fresh CSRF token from the current workbench page.",
        filename,
      ));
      return resultWithDiagnostics({ kind: `conversion-${action}`, targetClassName: request.className }, diagnostics);
    }

    let current;
    try {
      current = await repository.getProgram(request.program);
    } catch (error) {
      diagnostics.push(serviceDiagnostic(
        "GGCONV-E613",
        "repository revision",
        `repository revision could not be read: ${error instanceof Error ? error.message : String(error)}`,
        "Reload the program and retry the operation from the current workbench page.",
        filename,
      ));
      return resultWithDiagnostics({ kind: `conversion-${action}`, targetClassName: request.className }, diagnostics);
    }

    if (!revisionMatches(current, request.expectedRevision)) {
      diagnostics.push(serviceDiagnostic(
        "GGCONV-E614",
        "repository revision",
        "the workbench page is stale; the repository program changed after it was read",
        "Reload the source and obtain a new expectedRevision before retrying.",
        filename,
      ));
      return resultWithDiagnostics({ kind: `conversion-${action}`, targetClassName: request.className }, diagnostics);
    }

    const previewRequest = { ...request, includeSource: true };
    if (typeof request.source !== "string" && typeof current?.source === "string") {
      previewRequest.source = current.source;
      previewRequest.filename = request.filename ?? current.filename ?? filename;
    }
    const previewResult = await preview(previewRequest);
    if (!previewResult.sourceAvailable) {
      return resultWithDiagnostics({
        ...previewResult,
        kind: `conversion-${action}`,
      }, previewResult.diagnostics ?? []);
    }

    if (typeof writer !== "function") {
      diagnostics.push(serviceDiagnostic(
        "GGCONV-E615",
        "repository mutation",
        `repository does not provide a ${action} writer; conversion remains display-only`,
        "Provide a dedicated persistence and activation service before enabling this action.",
        filename,
      ));
      return resultWithDiagnostics({
        ...previewResult,
        kind: `conversion-${action}`,
      }, [...(previewResult.diagnostics ?? []), ...diagnostics]);
    }

    let latest;
    try {
      latest = await repository.getProgram(request.program);
    } catch (error) {
      diagnostics.push(serviceDiagnostic(
        "GGCONV-E613",
        "repository revision",
        `repository revision could not be revalidated: ${error instanceof Error ? error.message : String(error)}`,
        "Reload the source and retry the operation from the current workbench page.",
        filename,
      ));
      return resultWithDiagnostics({
        ...previewResult,
        kind: `conversion-${action}`,
      }, [...(previewResult.diagnostics ?? []), ...diagnostics]);
    }
    if (!revisionMatches(latest, request.expectedRevision)) {
      diagnostics.push(serviceDiagnostic(
        "GGCONV-E614",
        "repository revision",
        "the repository changed while conversion was running; no mutation was attempted",
        "Reload the source and retry with the new expectedRevision.",
        filename,
      ));
      return resultWithDiagnostics({
        ...previewResult,
        kind: `conversion-${action}`,
      }, [...(previewResult.diagnostics ?? []), ...diagnostics]);
    }

    const saved = await writer.call(repository, {
      action,
      program: request.program,
      className: previewResult.targetClassName,
      transactionCode: request.transactionCode,
      source: previewResult.classSource,
      manifest: previewResult.manifest,
      expectedRevision: request.expectedRevision,
    });
    return {
      ...previewResult,
      kind: `conversion-${action}`,
      repositoryChanged: true,
      saved: true,
      mutation: saved,
    };
  }

  return {
    preview,
    create(request) {
      return mutate("create", request);
    },
    save(request) {
      return mutate("save", request);
    },
  };
}
