import { createHash, randomUUID } from "node:crypto";
import { createWorkbenchService } from "./workbench-service.mjs";

function plain(value) {
  if (value === undefined || value === null) return value;
  if (value.constructor?.name === "Table") return value.array().map(plain);
  if (value.constructor?.name === "Structure") {
    return Object.fromEntries(Object.entries(value.value ?? {}).map(([key, item]) => [key, plain(item)]));
  }
  if (Object.hasOwn(value, "value") && (typeof value.value !== "object" || value.value === null)) return value.value;
  return value;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function formFields(request) {
  const body = Buffer.isBuffer(request.body) ? request.body.toString("utf8") : String(request.body ?? "");
  return new URLSearchParams(body);
}

function sourceHash(source) {
  return createHash("sha256").update(source, "utf8").digest("hex");
}

function runtimeClass(runtime, name) {
  const definition = runtime?.Classes?.[name];
  if (!definition) throw new Error(`ABAP runtime class ${name} is unavailable`);
  return definition;
}

/**
 * Adapt the read-only scaffold repository to the converter workbench service.
 * The adapter exposes source and a deterministic source revision; it has no
 * mutation methods by design.
 */
export function createAbapRepository(runtime = globalThis.abap) {
  async function repositoryObject() {
    const instance = new (runtimeClass(runtime, "ZCL_GG_SYSTEM_REPOSITORY"))();
    await instance.constructor_();
    return instance;
  }

  return {
    async getProgram(program) {
      const instance = await repositoryObject();
      const result = plain(await instance["zif_gg_program_repository_v1$get_program"]({
        iv_program: String(program ?? ""),
        rs_program: 1,
      }));
      const lines = Array.isArray(result?.source_lines) ? result.source_lines : [];
      if (result?.error || lines.length === 0) return {
        filename: `${String(program ?? "program").toLowerCase()}.prog.abap`,
        revision: sourceHash(JSON.stringify(result ?? {})),
        ...result,
      };
      const source = lines.join("\n");
      return {
        filename: `${String(result.program ?? program).toLowerCase()}.prog.abap`,
        source,
        revision: sourceHash(source),
        ...result,
      };
    },

    async getProgramNames() {
      const instance = await repositoryObject();
      const result = plain(await instance["zif_gg_program_repository_v1$get_program_names"]({
        rt_programs: 1,
      }));
      return (Array.isArray(result) ? result : []).map((item) => String(item ?? "").trim()).filter(Boolean);
    },
  };
}

function existingClassNames(runtime) {
  return Object.keys(runtime?.Classes ?? {})
    .filter((name) => /^[A-Z][A-Z0-9_]{0,29}$/.test(name));
}

function diagnosticMarkup(diagnostics) {
  if (!diagnostics?.length) return '<p class="cvp-success" role="status">No conversion diagnostics were reported.</p>';
  return `<ul class="cvp-diagnostics" aria-label="Conversion diagnostics">${diagnostics.map((item) =>
    `<li class="cvp-diagnostic cvp-${escapeHtml(item.severity)}"><code>${escapeHtml(item.code)}</code> ` +
    `<span>${escapeHtml(item.message)}</span>` +
    (item.filename ? ` <small>${escapeHtml(item.filename)}${item.line ? `:${escapeHtml(item.line)}` : ""}</small>` : "") +
    (item.suggestion ? `<br><em>${escapeHtml(item.suggestion)}</em>` : "") +
    "</li>").join("")}</ul>`;
}

function programOptions(programs, selected) {
  return programs.map((program) =>
    `<option value="${escapeHtml(program)}"${program === selected ? " selected" : ""}>${escapeHtml(program)}</option>`).join("");
}

function renderPage({programs, request = {}, result, token, sourceShown = false, saveAvailable = false, csrfToken = ""}) {
  const diagnostics = result ? diagnosticMarkup(result.diagnostics) :
    '<p class="cvp-muted">Choose a repository program and inspect diagnostics before requesting generated source.</p>';
  const source = sourceShown && result?.sourceAvailable && result.classSource
    ? `<section aria-labelledby="generated-source-heading"><h2 id="generated-source-heading">Generated class source</h2><pre data-generated-source>${escapeHtml(result.classSource)}</pre><a class="cvp-download" href="/converter/preview/download?token=${escapeHtml(token)}" download>Download generated class</a></section>`
    : "";
  const sourceAction = result?.sourceAvailable && !sourceShown
    ? `<form method="post" action="/converter/preview"><input type="hidden" name="action" value="source"><input type="hidden" name="token" value="${escapeHtml(token)}"><button type="submit">Show generated source</button></form>`
    : "";
  const target = request.className ?? "";
  const tcode = request.transactionCode ?? "";
  const selected = request.program ?? "";
  const checked = request.collisionConfirmed ? " checked" : "";
  const capabilities = result?.capabilities?.length
    ? `<p class="cvp-capabilities"><strong>Capabilities:</strong> ${result.capabilities.map((item) =>
      escapeHtml(`${item.kind ?? "construct"}: ${item.status ?? "reported"}${item.loweringRule ? ` (${item.loweringRule})` : ""}`)).join(", ")}</p>`
    : "";
  const mutation = saveAvailable
    ? `<form method="post" action="/converter/preview/save"><input type="hidden" name="action" value="save"><input type="hidden" name="token" value="${escapeHtml(token)}"><input type="hidden" name="csrfToken" value="${escapeHtml(csrfToken)}"><input type="hidden" name="pageToken" value="${escapeHtml(token)}"><button type="submit">Save generated class</button></form><p class="cvp-readonly" data-save-boundary>Saving is explicit and revalidates authorization, CSRF, and the source revision before writing.</p>`
    : '<p class="cvp-readonly" data-save-disabled>Save and activation are unavailable in this read-only deployment. A separately authorized repository writer is required.</p>';
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Converter Preview · open-abap</title><style>
html,body{margin:0;min-height:100%;font-family:Segoe UI,Tahoma,Arial,sans-serif;color:#1d2d3e;background:#e9f0f8}.cvp-shell{max-width:1100px;margin:0 auto;padding:28px}.cvp-header{display:flex;align-items:baseline;gap:18px;border-bottom:1px solid #aebfd2;padding-bottom:12px}.cvp-header h1{margin:0;color:#174a80}.cvp-header a{color:#064b99}.cvp-panel{margin-top:22px;padding:22px;background:#fff;border:1px solid #aebfd2;border-radius:5px;box-shadow:0 2px 8px rgba(34,67,102,.12)}label{display:block;margin:12px 0 5px;font-weight:600}select,input{box-sizing:border-box;width:100%;max-width:520px;height:34px;padding:5px 8px;border:1px solid #829fbe;border-radius:3px;font:inherit;background:#fff}input[type=checkbox]{width:auto;height:auto;margin-right:7px}button,.cvp-download{display:inline-block;margin-top:18px;padding:8px 14px;border:1px solid #5e8fbd;border-radius:3px;background:linear-gradient(#fff,#e8f0f8);color:#15589a;font:inherit;font-weight:600;text-decoration:none;cursor:pointer}button:focus,input:focus,select:focus,a:focus{outline:2px solid #2668a3;outline-offset:2px}.cvp-note,.cvp-muted{color:#60758b}.cvp-diagnostics{padding:0;list-style:none}.cvp-diagnostic{margin:9px 0;padding:10px 12px;border-left:4px solid #a32121;background:#fdf1f1}.cvp-warning{border-color:#a36b12;background:#fdf7ea}.cvp-info{border-color:#9c1f6a;background:#fdf0f7}.cvp-success{color:#14663a}.cvp-readonly{margin-top:18px;padding:12px;border-left:4px solid #60758b;background:#f1f5f9;color:#465d72}.cvp-capabilities{color:#315a7f}pre{max-height:600px;overflow:auto;padding:16px;background:#172536;color:#f4f8fc;border-radius:3px;white-space:pre-wrap;tab-size:2}.cvp-diagnostic code{font-weight:700}.cvp-diagnostic small{color:#60758b}.cvp-diagnostic em{color:#465d72}.cvp-section-heading{margin-top:0;color:#174a80}@media(max-width:700px){.cvp-shell{padding:14px}}
</style></head><body><div class="cvp-shell"><header class="cvp-header"><h1>Converter Preview</h1><a href="/">Return to workbench</a></header><main><section class="cvp-panel"><p class="cvp-note">Read-only migration preview. The source program is never replaced. Diagnostics are inspected before generated class source is offered.</p><form method="post" action="/converter/preview"><input type="hidden" name="action" value="inspect"><label for="cvp-program">Repository program</label><select id="cvp-program" name="program" required><option value="">Choose a program</option>${programOptions(programs, selected)}</select><label for="cvp-class">Target class name (required)</label><input id="cvp-class" name="className" required value="${escapeHtml(target)}" placeholder="ZCL_MIGRATED_REPORT"><label for="cvp-tcode">Transaction code (optional)</label><input id="cvp-tcode" name="transactionCode" value="${escapeHtml(tcode)}" placeholder="Z_MIGRATED_REPORT"><label><input type="checkbox" name="collisionConfirmed"${checked}> I explicitly confirm replacing an existing target name if a collision is reported</label><button type="submit">Inspect diagnostics</button></form></section>${result ? `<section class="cvp-panel" aria-labelledby="diagnostics-heading"><h2 id="diagnostics-heading" class="cvp-section-heading">Diagnostics</h2>${capabilities}${diagnostics}${sourceAction}${source}${mutation}</section>` : ""}</main></div></body></html>`;
}

/**
 * Create the HTTP handlers for the read-only converter workbench action.
 * Preview state is process-local and only stores the explicit request/result
 * needed for the subsequent source inspection or download.
 */
export function createWorkbenchPreviewHandlers({
  runtime = globalThis.abap,
  repository = createAbapRepository(runtime),
  authorize,
  validateCsrf,
  csrfToken = "",
} = {}) {
  const service = createWorkbenchService({repository});
  const previews = new Map();
  const saveAvailable = typeof repository.saveProgram === "function"
    && typeof authorize === "function"
    && typeof validateCsrf === "function";

  function remember(request, result, token = randomUUID()) {
    previews.set(token, {request, result});
    while (previews.size > 32) previews.delete(previews.keys().next().value);
    return token;
  }

  async function programs() {
    return repository.getProgramNames();
  }

  function workbenchRequest(fields, sourceRequest) {
    return {
      program: fields.get("program") ?? sourceRequest?.program,
      className: fields.get("className") ?? sourceRequest?.className,
      transactionCode: fields.get("transactionCode") ?? sourceRequest?.transactionCode,
      collisionConfirmed: fields.get("collisionConfirmed") === "on" || sourceRequest?.collisionConfirmed === true,
      existingClassNames: existingClassNames(runtime),
      filename: sourceRequest?.filename,
    };
  }

  return {
    async get(_request, response) {
      response.type("html").send(renderPage({programs: await programs()}));
    },

    async post(request, response) {
      const fields = formFields(request);
      const token = fields.get("token");
      const saved = token ? previews.get(token) : undefined;
      const sourceAction = fields.get("action") === "source";
      const previewRequest = workbenchRequest(fields, saved?.request);
      const result = await service.preview({
        ...previewRequest,
        includeSource: sourceAction,
      });
      const currentToken = remember(previewRequest, result, token || randomUUID());
      response.type("html").send(renderPage({
        programs: await programs(),
        request: previewRequest,
        result,
        token: currentToken,
        sourceShown: sourceAction,
        saveAvailable,
        csrfToken,
      }));
    },

    async save(request, response) {
      const fields = formFields(request);
      const token = fields.get("token");
      const saved = token ? previews.get(token) : undefined;
      const previewRequest = saved?.request ?? workbenchRequest(fields);
      const result = await service.save({
        ...previewRequest,
        expectedRevision: saved?.result?.repositoryRevision,
        csrfToken: fields.get("csrfToken"),
        pageToken: fields.get("pageToken"),
        authorize,
        validateCsrf,
        includeSource: true,
      });
      const currentToken = remember(previewRequest, result, token || randomUUID());
      response.type("html").send(renderPage({
        programs: await programs(),
        request: previewRequest,
        result,
        token: currentToken,
        sourceShown: Boolean(result.sourceAvailable),
        saveAvailable,
        csrfToken,
      }));
    },

    async download(request, response) {
      const token = String(request.query?.token ?? "");
      const record = previews.get(token);
      if (!record?.result?.sourceAvailable || !record.result.classSource) {
        response.status(404).type("text").send("Generated source is not available; inspect diagnostics first.");
        return;
      }
      response.type("text/plain");
      response.set("Content-Disposition", `attachment; filename="${String(record.result.targetClassName).toLowerCase()}.clas.abap"`);
      response.send(record.result.classSource);
    },
  };
}
