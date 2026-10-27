// The shapes the conversion passes hand to each other. The report IR is
// returned to callers and serialized into snapshots, so everything in it is
// plain data: the abaplint nodes behind a statement are reached through
// src/abap/ast.ts, never stored in the IR.

export interface Position {
  line: number;
  column: number;
}

export interface Span {
  start: Position;
  end: Position;
  startOffset?: number;
  endOffset?: number;
}

export type Severity = "error" | "warning" | "info";

export interface Diagnostic {
  code: string;
  severity: Severity;
  filename: string;
  start: Position;
  end: Position;
  construct: string;
  message: string;
  suggestion: string;
  phase: string;
  category?: string;
  feature?: string;
  internalLocation?: { filename: string; start: Position; end: Position };
  generatedLocation?: { filename: string; start: Position; end: Position };
}

export interface DiagnosticInput {
  code: string;
  severity?: Severity;
  filename?: string;
  start?: Position;
  end?: Position;
  construct?: string;
  message?: string;
  suggestion?: string;
  phase?: string;
  feature?: string;
  category?: string;
}

/** A source file of the conversion: the program or one of its includes. */
export interface SourceUnit {
  filename: string;
  source: string;
  newline: string;
  ancestry: string[];
  hashKey?: string;
}

/**
 * One ABAP statement as abaplint split it. A chained statement arrives as one
 * statement per chain element, keyword repeated, ending in its comma; `text`
 * is the element on one line, as abaplint's concatTokens writes it.
 */
export interface Statement {
  kind: string;
  text: string;
  span: Span;
  filename: string;
  ancestry?: string[];
  /** Declared in a FORM or method rather than the program. */
  scope?: "local";
  localClassName?: string;
  localClassPart?: string;
  resolvedType?: boolean;
}

export interface DeclarationEntry {
  name: string;
  definition: string;
}

export interface Declaration {
  kind: string;
  raw: string;
  statement: Statement;
  names?: string[];
  name?: string;
  entries?: DeclarationEntry[];
  componentNames?: string[];
  component?: boolean;
  complex?: boolean;
  inline?: boolean;
  additions?: string;
  table?: string;
  target?: string;
  typeExpression?: string;
  type?: string;
  fields?: Record<string, unknown>;
  resolved?: boolean;
}

export interface DataType {
  typ: string;
  length?: number;
  decimals?: number;
  rollname?: string;
}

/** A PARAMETERS, SELECT-OPTIONS or SELECTION-SCREEN layout element. */
export interface SelectionElement {
  kind: string;
  name?: string;
  layout?: string;
  text?: string;
  title?: string;
  span?: Span;
  statement?: Statement;
  raw?: string;
  additions?: string;
  dataType?: DataType;
  default?: string;
  screen?: string;
  suppressTextPool?: boolean;
  position?: number;
  length?: number;
  lines?: number;
  number?: number;
  ucomm?: string;
  subscreen?: string;
  withFrame?: boolean;
  ranges?: boolean;
  [key: string]: unknown;
}

export interface SelectionScreen {
  number: string;
  additions?: string;
  /** The field BEGIN OF SCREEN ... TITLE names, if a field and no text symbol. */
  titleField?: string;
  asWindow?: boolean;
  asSubscreen?: boolean;
  elements: SelectionElement[];
  span?: Span;
}

export interface RoutineParameter {
  name: string;
  section: "USING" | "CHANGING" | "TABLES";
  direction: "IMPORTING" | "CHANGING";
  byValue: boolean;
  type: string;
  typing: string;
  /** The line type TABLES p STRUCTURE s names. */
  structure?: string;
  lineType?: string;
  written?: boolean;
}

export interface Routine {
  name: string;
  statement: Statement;
  statements: Statement[];
  methodName?: string;
  parameters?: RoutineParameter[];
}

export interface EventBlock {
  event: string;
  qualifier: string | undefined;
  statements: Statement[];
}

export interface LocalClassMethod {
  name: string;
  statement: Statement | undefined;
  definition: Statement | undefined;
  statements: Statement[];
}

export interface LocalClass {
  name: string;
  definition: Statement[];
  methods: LocalClassMethod[];
  definitionStatement: Statement | undefined;
  implementationStatement: Statement | undefined;
  definitionHeader?: string;
  implementationHeader?: string;
  generatedName?: string;
}

export interface DynproModule {
  name: string;
  direction: "INPUT" | "OUTPUT";
  statement: Statement;
  statements: Statement[];
}

export interface ControlFrame {
  kind: string;
  branch: string;
}

export interface Continuation {
  id: string;
  sourceId: string;
  filename: string;
  span: Span;
  source: string;
  contextDepth: number;
  controlStack: ControlFrame[];
  liveVariables: string[];
  capturedVariables?: string[];
}

export interface SelectionState {
  member: string;
  ranges: boolean;
  dataType?: DataType;
  additions?: string;
}

export interface StatePlan {
  globals: string[];
  selections: string[];
  renames: Record<string, string>;
  selectionState: Record<string, SelectionState>;
  hydration: { name: string; from: string; target: string }[];
  flush: { name: string; source: string; to: string }[];
  systemFields: { ucomm: string; subrc: string; listIndex: string };
}

export interface FieldSymbolReference {
  member: string;
  routines: string[];
  methods: boolean;
}

export interface HeaderLines {
  global: Record<string, string>;
  routines: Record<string, Record<string, string>>;
  parameters: Record<string, string[]>;
}

export interface DynamicAlvField {
  name: string;
  intType: string;
  length: number;
  decimals: number;
  outputLength: number;
  checkbox: boolean;
  editable: boolean;
  total: boolean;
  title: string;
  currencyField: string;
}

export interface DynamicAlv {
  rowType: string;
  tableType: string;
  tableMember: string;
  tableSymbol: string;
  referenceMember: string;
  styleMember: string;
  styleComponent: string;
  rowSymbol: string;
  componentSymbol: string;
  styleTableSymbol: string;
  styleRowSymbol: string;
  styleValueSymbol: string;
  fieldSymbols: string[];
  fields: DynamicAlvField[];
  typeFields: { name: string; type: string }[];
}

export interface SourceSymbol {
  name: string;
  kind: string;
  scope?: string;
  localClassName?: string;
  filename: string;
  span: Span;
}

export interface SourceIndex {
  symbols: SourceSymbol[];
  byName: Record<string, SourceSymbol[]>;
  collisions: Record<string, SourceSymbol[]>;
}

export interface Capability {
  kind: string;
  construct: string;
  filename: string;
  span: Span;
  status: string;
  loweringRule?: string;
  diagnostic?: string;
}

export interface ReportHeader {
  raw: string;
  lineSize?: number;
  lineCount?: number;
  footerLines?: number;
  noStandardPageHeading: boolean;
  messageId?: string;
}

/**
 * Screen and GUI metadata read from the abapGit .prog.xml and
 * .prog.screen_NNNN.abap files, or supplied by the caller. It mirrors the
 * serialized repository objects, so its records stay open-ended.
 */
export type Metadata = Record<string, any>;

export interface ReportIR {
  kind: "report";
  programName: string | undefined;
  programKind: string;
  reportTitle: string | undefined;
  description?: string;
  targetClassName?: string;
  transactionCode?: string;
  header: ReportHeader;
  source: { filename: string; source: string; sourceHash: string; newline: string };
  units: { filename: string; ancestry: string[] }[];
  statements: Statement[];
  declarations: Declaration[];
  selections: SelectionScreen[];
  events: Record<string, Statement[]>;
  eventQualifiers: Record<string, string>;
  eventHeaders: Record<string, Statement[]>;
  duplicateEvents: { event: string; statement: Statement }[];
  eventBlocks: EventBlock[];
  routines: Routine[];
  localClasses: LocalClass[];
  localClassRenames?: Record<string, string>;
  modules: DynproModule[];
  controlFlowGraphs: Metadata[];
  dynproMetadata: Metadata | undefined;
  dynproIR?: Metadata;
  screenMetadata: Metadata | undefined;
  guiStatusMetadata: Metadata;
  references: Metadata;
  interfaces: string[];
  features: string[];
  capabilities: Capability[];
  dynamicAlv?: DynamicAlv;
  safeFieldSymbols?: string[];
  fieldSymbolReferences?: Record<string, FieldSymbolReference>;
  sourceIndex?: SourceIndex;
  statePlan?: StatePlan;
  continuations?: Continuation[];
  hiddenNames?: string[];
  headerLines?: HeaderLines;
  constantNames?: Set<string>;
  readonlyPerformArguments?: { statement: Statement; routine: string; parameter: string; argument: string }[];
  resolvedTypes?: Record<string, Metadata>;
}

/** The input of convertProgram; see the converter README. */
export interface ConvertOptions {
  source?: string;
  filename?: string;
  programName?: string;
  mode?: "strict" | "partial";
  partialStrategy?: "preserve" | "skeleton";
  className?: string;
  transactionCode?: string;
  description?: string;
  language?: string;
  configPath?: string;
  converterVersion?: string;
  maxSourceBytes?: number;
  maxSourceLines?: number;
  maxDurationMs?: number;
  resolveInclude?: (name: string, parentFilename: string) => unknown;
  includePaths?: string[];
  textPool?: unknown;
  ddicTypes?: Metadata;
  dictionaryFiles?: (string | { filename: string; source?: string })[];
  selectionMetadata?: Metadata;
  guiStatusMetadata?: Metadata;
  guiStatuses?: Metadata;
  dynproMetadata?: Metadata;
  screenMetadata?: Metadata;
  resolveDynpro?: (request: { programName?: string; filename: string; source: string }) => Metadata | Promise<Metadata>;
  loadDynproMetadata?: boolean;
  dynproMetadataFilename?: string;
  dynproScreenDirectory?: string;
  dynproScreenFiles?: (string | { filename: string; source?: string })[];
  existingClassNames?: string[];
  existingClasses?: string[];
  existingClassFiles?: Record<string, string>;
}

export interface NormalizedOptions extends ConvertOptions {
  filename: string;
  mode: "strict" | "partial";
  partialStrategy: "preserve" | "skeleton";
  descriptionProvided: boolean;
  configPath: string;
  converterVersion: string;
  maxSourceBytes: number;
  maxSourceLines: number;
  maxDurationMs: number;
}

export interface HelperSource {
  className: string;
  sourceName: string;
  source: string;
}

export interface SourceMapSegment {
  source: string;
  output: string;
  start: Position;
  end: Position;
  segment: string;
  construct?: string;
  filename?: string;
  outputStart?: Position;
  outputEnd?: Position;
}

export interface ConversionResult {
  classSource: string | undefined;
  helperSources?: HelperSource[];
  manifest: Metadata | undefined;
  diagnostics: Diagnostic[];
  sourceMap: SourceMapSegment[];
  reportIR?: ReportIR;
  scaffoldIR?: Metadata;
  supported: boolean;
}
