import fs from "node:fs/promises";
import path from "node:path";

const SCREEN_FILE = /^(?<stem>.+)\.prog\.screen_(?<number>\d{1,4})\.abap$/i;

function localName(name) {
  return String(name ?? "").split(":").at(-1).toUpperCase();
}

function decodeXml(value) {
  return String(value ?? "").replace(/&(#x[0-9a-f]+|#\d+|amp|apos|quot|lt|gt);/gi, (match, entity) => {
    const normalized = entity.toLowerCase();
    if (normalized === "amp") return "&";
    if (normalized === "apos") return "'";
    if (normalized === "quot") return '"';
    if (normalized === "lt") return "<";
    if (normalized === "gt") return ">";
    if (normalized.startsWith("#x")) return String.fromCodePoint(Number.parseInt(normalized.slice(2), 16));
    if (normalized.startsWith("#")) return String.fromCodePoint(Number.parseInt(normalized.slice(1), 10));
    return match;
  });
}

function parseAttributes(source) {
  const attributes = {};
  const pattern = /(?<name>[A-Za-z_][A-Za-z0-9_.:-]*)\s*=\s*(?<quote>["'])(?<value>[\s\S]*?)\k<quote>/g;
  for (const match of source.matchAll(pattern)) attributes[match.groups.name] = decodeXml(match.groups.value);
  return attributes;
}

function parseXml(source) {
  const root = { name: "#document", children: [], text: "" };
  const stack = [root];
  const tokens = /<!--[\s\S]*?-->|<!\[CDATA\[[\s\S]*?\]\]>|<\?[\s\S]*?\?>|<!DOCTYPE[\s\S]*?>|<[^>]+>|[^<]+/gi;
  for (const match of String(source ?? "").matchAll(tokens)) {
    const token = match[0];
    if (token.startsWith("<!--") || token.startsWith("<?") || /^<!DOCTYPE/i.test(token)) continue;
    if (token.startsWith("<![CDATA[")) {
      stack.at(-1).text += token.slice(9, -3);
      continue;
    }
    if (!token.startsWith("<")) {
      stack.at(-1).text += decodeXml(token);
      continue;
    }
    if (/^<\//.test(token)) {
      const name = token.slice(2, -1).trim();
      if (stack.length === 1 || localName(stack.at(-1).name) !== localName(name)) {
        throw new Error(`malformed XML: unexpected closing tag ${name}`);
      }
      stack.pop();
      continue;
    }
    const selfClosing = /\/\s*>$/.test(token);
    const body = token.slice(1, selfClosing ? -2 : -1).trim();
    const nameMatch = /^(?<name>[A-Za-z_][A-Za-z0-9_.:-]*)/.exec(body);
    if (!nameMatch) throw new Error(`malformed XML: invalid tag ${token}`);
    const node = {
      name: nameMatch.groups.name,
      attributes: parseAttributes(body.slice(nameMatch[0].length)),
      children: [],
      text: "",
    };
    stack.at(-1).children.push(node);
    if (!selfClosing) stack.push(node);
  }
  if (stack.length !== 1) throw new Error(`malformed XML: unclosed tag ${stack.at(-1).name}`);
  return root;
}

function children(node, name) {
  return (node?.children ?? []).filter((item) => name === undefined || localName(item.name) === name.toUpperCase());
}

function child(node, name) {
  return children(node, name)[0];
}

function firstDescendant(node, name) {
  if (localName(node?.name) === String(name).toUpperCase()) return node;
  for (const item of node?.children ?? []) {
    const found = firstDescendant(item, name);
    if (found) return found;
  }
  return undefined;
}

function text(node) {
  return String(node?.text ?? "").trim();
}

function leafRecord(node) {
  const record = {};
  for (const item of children(node)) {
    const nested = children(item);
    if (nested.length === 0) {
      const value = text(item);
      if (value !== "") record[localName(item.name)] = value;
    }
  }
  return record;
}

function recordValue(record, key) {
  const value = record[String(key).toUpperCase()];
  return value === undefined || value === "" ? undefined : value;
}

function integer(value) {
  if (value === undefined || value === null || value === "") return undefined;
  const parsed = Number.parseInt(String(value), 10);
  return Number.isFinite(parsed) ? parsed : undefined;
}

function flag(value) {
  return ["X", "1", "Y", "TRUE"].includes(String(value ?? "").trim().toUpperCase());
}

function paddedScreen(value) {
  if (value === undefined || value === null || value === "") return undefined;
  return String(value).trim().padStart(4, "0");
}

function camelCase(name) {
  return String(name).toLowerCase().replace(/_([a-z0-9])/g, (_, letter) => letter.toUpperCase());
}

function publicRecord(record) {
  return Object.fromEntries(Object.entries(record).map(([key, value]) => [camelCase(key), value]));
}

function positionAndGeometry(record) {
  const line = integer(record.LINE);
  const column = integer(record.COLUMN);
  const width = integer(record.LENGTH);
  const height = integer(record.HEIGHT);
  const visibleWidth = integer(record.VISLENGTH);
  return {
    ...(line === undefined ? {} : { line }),
    ...(column === undefined ? {} : { column }),
    ...(width === undefined ? {} : { width }),
    ...(height === undefined ? {} : { height }),
    ...(visibleWidth === undefined ? {} : { visibleWidth }),
  };
}

function elementKind(record) {
  const type = String(record.TYPE ?? "").toUpperCase();
  if (type === "TEXT") return "text";
  if (type === "FRAME") return "frame";
  if (type === "PUSH") return "pushbutton";
  if (type === "CHECK") return "checkbox";
  if (type === "RADIO" || type === "RADIOBUTTON" || type === "RADIOGROUP") return "radio";
  if (type === "LISTBOX" || type === "DROPDOWN" || type === "COMBO") return "dropdown";
  if (type === "SUBSCREEN") return "subscreen";
  if (type === "OKCODE") return "okcode";
  if (flag(record.INPUT_FLD) && flag(record.OUTPUT_FLD)) return "input-output";
  if (flag(record.INPUT_FLD)) return "input";
  if (flag(record.OUTPUT_FLD)) return "output";
  return type ? type.toLowerCase() : "element";
}

function parseElement(node) {
  const attributes = leafRecord(node);
  const position = positionAndGeometry(attributes);
  const kind = elementKind(attributes);
  return {
    kind,
    type: recordValue(attributes, "TYPE"),
    name: recordValue(attributes, "NAME"),
    text: recordValue(attributes, "TEXT"),
    line: position.line,
    column: position.column,
    length: position.width,
    height: position.height,
    visibleLength: position.visibleWidth,
    position,
    geometry: position,
    input: flag(attributes.INPUT_FLD),
    output: flag(attributes.OUTPUT_FLD),
    required: String(attributes.REQU_ENTRY ?? "").toUpperCase() === "R",
    invisible: flag(attributes.INVISIBLE),
    bright: flag(attributes.BRIGHT),
    rolling: flag(attributes.ROLLING),
    ucomm: recordValue(attributes, "PUSH_FCODE"),
    iconName: recordValue(attributes, "ICON_NAME"),
    pushType: recordValue(attributes, "PUSH_FTYPE"),
    attributes: publicRecord(attributes),
  };
}

function parseContainer(node) {
  const attributes = leafRecord(node);
  const position = positionAndGeometry(attributes);
  return {
    kind: String(attributes.TYPE ?? "container").toLowerCase(),
    type: recordValue(attributes, "TYPE"),
    name: recordValue(attributes, "NAME"),
    elementOf: recordValue(attributes, "ELEMENT_OF"),
    line: position.line,
    column: position.column,
    length: position.width,
    height: position.height,
    position,
    geometry: position,
    resizable: {
      horizontal: flag(attributes.C_RESIZE_H),
      vertical: flag(attributes.C_RESIZE_V),
    },
    attributes: publicRecord(attributes),
  };
}

function moduleEntry(name, extras = {}) {
  return {
    name: String(name ?? "").trim().toUpperCase(),
    ...extras,
  };
}

function parseFlowLogic(source, filename, number) {
  const flow = {
    screen: number,
    filename,
    source: String(source ?? ""),
    pbo: [],
    pai: [],
    pov: { field: undefined, modules: [] },
    poh: { field: undefined, modules: [] },
    steps: [],
  };
  let phase;
  let chainDepth = 0;
  const lines = flow.source.split(/\r?\n/);
  for (const [index, line] of lines.entries()) {
    const raw = line.trim();
    if (raw === "") continue;
    const process = /^PROCESS\s+(?:BEFORE\s+OUTPUT|AFTER\s+INPUT|ON\s+VALUE-REQUEST|ON\s+HELP-REQUEST)\s*\.?$/i.exec(raw);
    if (process) {
      const processName = process[0].replace(/^PROCESS\s+/i, "").replace(/\.$/, "").replace(/\s+/g, " ").toUpperCase();
      phase = processName === "BEFORE OUTPUT" ? "pbo"
        : processName === "AFTER INPUT" ? "pai"
          : processName === "ON VALUE-REQUEST" ? "pov" : "poh";
      flow.steps.push({ kind: "process", phase, line: index + 1, source: raw });
      continue;
    }
    if (/^CHAIN\s*\.?$/i.test(raw)) {
      chainDepth += 1;
      flow.steps.push({ kind: "chain-begin", phase, depth: chainDepth, line: index + 1, source: raw });
      continue;
    }
    if (/^ENDCHAIN\s*\.?$/i.test(raw)) {
      flow.steps.push({ kind: "chain-end", phase, depth: chainDepth, line: index + 1, source: raw });
      chainDepth = Math.max(0, chainDepth - 1);
      continue;
    }
    const field = /^FIELD\s+([^\s.]+)\s+MODULE\s+([^\s.]+)(.*)$/i.exec(raw);
    if (field && phase) {
      const entry = moduleEntry(field[2], {
        field: field[1].toUpperCase(),
        chainDepth,
        onInput: /\bON\s+INPUT\b/i.test(field[3]),
        onRequest: /\bON\s+(?:CHAIN-)?REQUEST\b/i.test(field[3]),
        line: index + 1,
        source: raw,
      });
      if (phase === "pov" || phase === "poh") {
        flow[phase].field ??= entry.field;
        flow[phase].modules.push(entry);
      } else {
        flow[phase].push(entry);
      }
      flow.steps.push({ kind: "field-module", phase, ...entry });
      continue;
    }
    const module = /^MODULE\s+([^\s.]+)(.*)$/i.exec(raw);
    if (module && phase) {
      const entry = moduleEntry(module[1], {
        atExitCommand: /\bAT\s+EXIT-COMMAND\b/i.test(module[2]),
        onInput: /\bON\s+INPUT\b/i.test(module[2]),
        chainDepth,
        line: index + 1,
        source: raw,
      });
      flow[phase].push(entry);
      flow.steps.push({ kind: "module", phase, ...entry });
      continue;
    }
    flow.steps.push({ kind: "source", phase, chainDepth, line: index + 1, source: raw });
  }
  if (flow.pov.modules.length === 0) delete flow.pov;
  if (flow.poh.modules.length === 0) delete flow.poh;
  return flow;
}

function parseTextPool(values) {
  const entries = children(child(values, "TPOOL"), "item").map((item) => {
    const attributes = leafRecord(item);
    return {
      id: recordValue(attributes, "ID"),
      key: recordValue(attributes, "KEY"),
      entry: recordValue(attributes, "ENTRY"),
      length: integer(attributes.LENGTH),
      attributes: publicRecord(attributes),
    };
  });
  const textPool = {};
  for (const entry of entries) {
    if (entry.key && entry.entry) textPool[entry.key] = entry.entry;
  }
  return {
    entries,
    textPool,
    reportTitle: entries.find((entry) => entry.id?.toUpperCase() === "R" && entry.entry)?.entry,
  };
}

function parseGuiStatus(values) {
  const cua = child(values, "CUA");
  if (!cua) return { guiStatus: undefined, guiStatuses: {}, titlebars: {} };
  const records = (section, item) => children(child(cua, section), item).map(leafRecord);
  const statuses = records("STA", "RSMPE_STAT").map((record) => ({
    name: recordValue(record, "CODE"),
    modal: recordValue(record, "MODAL"),
    activeCode: recordValue(record, "ACTCODE"),
    pfKeyCode: recordValue(record, "PFKCODE"),
    buttonCode: recordValue(record, "BUTCODE"),
    note: recordValue(record, "INT_NOTE"),
    attributes: publicRecord(record),
  }));
  const functions = records("FUN", "RSMPE_FUNT").map((record) => ({
    code: recordValue(record, "CODE"),
    text: recordValue(record, "FUN_TEXT"),
    type: recordValue(record, "TYPE"),
    textType: recordValue(record, "TEXT_TYPE"),
    textName: recordValue(record, "TEXT_NAME"),
    iconId: recordValue(record, "ICON_ID"),
    iconText: recordValue(record, "ICON_TEXT"),
    infoText: recordValue(record, "INFO_TEXT"),
    attributes: publicRecord(record),
  }));
  const menus = records("MEN", "RSMPE_MEN").map((record) => ({
    code: recordValue(record, "CODE"),
    number: integer(record.NO),
    referenceType: recordValue(record, "REF_TYPE"),
    referenceCode: recordValue(record, "REF_CODE"),
    referenceNumber: integer(record.REF_NO),
    attributes: publicRecord(record),
  }));
  const menuTexts = records("MTX", "RSMPE_MNLT").map((record) => ({
    code: recordValue(record, "CODE"),
    text: recordValue(record, "TEXT"),
    path: recordValue(record, "PATH"),
    note: recordValue(record, "INT_NOTE"),
    attributes: publicRecord(record),
  }));
  const buttons = records("BUT", "RSMPE_BUT").map((record) => ({
    functionKeyCode: recordValue(record, "PFK_CODE"),
    code: recordValue(record, "CODE"),
    number: integer(record.NO),
    functionKey: integer(record.PFNO),
    attributes: publicRecord(record),
  }));
  const pfKeys = records("PFK", "RSMPE_PFK").map((record) => ({
    code: recordValue(record, "CODE"),
    functionKey: integer(record.PFNO),
    functionCode: recordValue(record, "FUNCODE"),
    functionNumber: integer(record.FUNNO),
    attributes: publicRecord(record),
  }));
  const assignments = records("SET", "RSMPE_STAF").map((record) => ({
    status: recordValue(record, "STATUS"),
    function: recordValue(record, "FUNCTION"),
    attributes: publicRecord(record),
  }));
  const titlebars = Object.fromEntries(records("TIT", "RSMPE_TITT").map((record) => [recordValue(record, "CODE"), {
    code: recordValue(record, "CODE"),
    text: recordValue(record, "TEXT"),
    attributes: publicRecord(record),
  }]));
  const guiStatuses = Object.fromEntries(statuses.filter((item) => item.name).map((status) => [status.name, {
    ...status,
    functions: functions.filter((item) => assignments.some((assignment) => assignment.status === status.name && assignment.function === item.code)),
    menu: menus.filter((item) => item.code === status.activeCode),
    buttons: buttons.filter((item) => item.functionKeyCode === status.pfKeyCode),
    pfKeys: pfKeys.filter((item) => item.code === status.pfKeyCode),
    activeUcomm: assignments.filter((item) => item.status === status.name).map((item) => item.function),
  }]));
  return {
    guiStatus: { statuses: guiStatuses, functions, menus, menuTexts, buttons, pfKeys, assignments, titlebars },
    guiStatuses,
    titlebars,
  };
}

function parseXmlMetadata(xml, { metadataFilename } = {}) {
  const document = parseXml(xml);
  const values = firstDescendant(document, "values");
  if (!values) throw new Error("dynpro metadata XML does not contain asx:values");
  const programRecord = leafRecord(child(values, "PROGDIR"));
  const dynpros = children(child(values, "DYNPROS"), "item").map((item) => {
    const header = leafRecord(child(item, "HEADER"));
    const number = paddedScreen(header.SCREEN);
    const geometry = {
      width: integer(header.COLUMNS),
      height: integer(header.LINES),
      columns: integer(header.COLUMNS),
      lines: integer(header.LINES),
    };
    return {
      number,
      title: recordValue(header, "DESCRIPT"),
      description: recordValue(header, "DESCRIPT"),
      type: recordValue(header, "TYPE"),
      modal: String(header.TYPE ?? "").toUpperCase() === "M" || flag(header.MODAL),
      nextScreen: paddedScreen(header.NEXTSCREEN),
      cursor: recordValue(header, "CURSOR_POS"),
      width: geometry.width,
      height: geometry.height,
      geometry,
      attributes: publicRecord(header),
      containers: children(child(item, "CONTAINERS"), "RPY_DYCATT").map(parseContainer),
      elements: children(child(item, "FIELDS"), "RPY_DYFATC").map(parseElement),
    };
  });
  const textPool = parseTextPool(values);
  const guiStatus = parseGuiStatus(values);
  const statusNames = Object.keys(guiStatus.guiStatuses);
  const statuses = statusNames.length === 1
    ? Object.fromEntries(dynpros.map((screen) => [screen.number, { status: statusNames[0] }]))
    : {};
  const titlebars = guiStatus.titlebars;
  for (const screen of dynpros) {
    screen.titlebar = titlebars[`TITLE_${screen.number}`];
  }
  return {
    programName: recordValue(programRecord, "NAME"),
    initialScreen: dynpros[0]?.number,
    screens: dynpros,
    flowLogic: [],
    statuses,
    guiStatuses: guiStatus.guiStatuses,
    guiStatus: guiStatus.guiStatus,
    titlebars,
    textPool: textPool.textPool,
    textPoolEntries: textPool.entries,
    reportTitle: textPool.reportTitle,
    metadataFilename,
  };
}

function replaceProgramExtension(filename, extension) {
  if (/\.prog\.abap$/i.test(filename)) return filename.replace(/\.prog\.abap$/i, extension);
  return `${filename}${extension}`;
}

function screenFilesForReport(directory, reportFilename, names) {
  const stem = path.basename(reportFilename).replace(/\.prog\.abap$/i, "");
  const expected = new RegExp(`^${stem.replace(/[.*+?^${}()|[\\]\\]/g, "\\$&")}\\.prog\\.screen_(\\d{1,4})\\.abap$`, "i");
  return names.map((name) => {
    const filename = typeof name === "string" ? name : name?.filename;
    const match = expected.exec(path.basename(filename ?? ""));
    return match ? { filename, number: paddedScreen(match[1]) } : undefined;
  }).filter(Boolean).sort((left, right) => left.number.localeCompare(right.number) || left.filename.localeCompare(right.filename));
}

/**
 * Load the abapGit-owned dynpro representation for one executable program.
 * Missing metadata is treated as an absent optional input unless `required`
 * is true. Screen files are discovered beside the `.prog.xml` and are never
 * loaded from another program's prefix.
 */
export async function loadDynproMetadata({
  filename = "program.prog.abap",
  metadataFilename,
  screenDirectory,
  screenFiles,
  readFile = fs.readFile,
  readDirectory = fs.readdir,
  required = false,
} = {}) {
  const reportFilename = path.normalize(filename);
  const xmlFilename = path.normalize(metadataFilename ?? replaceProgramExtension(reportFilename, ".prog.xml"));
  let xml;
  try {
    xml = await readFile(xmlFilename, "utf8");
  } catch (error) {
    if (!required && (error?.code === "ENOENT" || error?.code === "ENOTDIR")) return undefined;
    throw new Error(`unable to read dynpro metadata ${xmlFilename}: ${error.message}`);
  }
  const directory = path.normalize(screenDirectory ?? path.dirname(xmlFilename));
  const candidates = screenFiles ?? await readDirectory(directory);
  const matching = screenFilesForReport(directory, reportFilename, candidates);
  const metadata = parseXmlMetadata(xml, { metadataFilename: xmlFilename });
  const flowByNumber = new Map();
  const loadedFiles = [];
  for (const item of matching) {
    const source = typeof screenFiles?.find((entry) => (typeof entry === "string" ? entry : entry?.filename) === item.filename)?.source === "string"
      ? screenFiles.find((entry) => (typeof entry === "string" ? entry : entry?.filename) === item.filename).source
      : await readFile(path.isAbsolute(item.filename) ? item.filename : path.join(directory, item.filename), "utf8");
    const flow = parseFlowLogic(source, path.isAbsolute(item.filename) ? item.filename : path.join(directory, item.filename), item.number);
    flowByNumber.set(item.number, flow);
    loadedFiles.push({ filename: flow.filename, number: item.number, source });
  }
  metadata.flowLogic = metadata.screens.map((screen) => {
    const flow = flowByNumber.get(screen.number);
    if (!flow) return { screen: screen.number, pbo: [], pai: [] };
    screen.flowLogic = flow;
    screen.flowFilename = flow.filename;
    return flow;
  });
  for (const flow of flowByNumber.values()) {
    if (!metadata.screens.some((screen) => screen.number === flow.screen)) metadata.flowLogic.push(flow);
  }
  metadata.files = {
    metadata: xmlFilename,
    screens: loadedFiles.map(({ filename, number }) => ({ filename, number })),
  };
  metadata.screenFiles = loadedFiles;
  return metadata;
}

export { parseFlowLogic };
