// abaplint's bundled typings cover its public API. The converter also runs
// the statement parser on its own, without a registry, and the syntax check of
// one object; these declare the parts of them it uses.

declare module "@abaplint/core/build/src/abap/abap_parser.js" {
  import type { ABAPFile, Config, IFile, IRegistry, Issue } from "@abaplint/core";

  export class ABAPParser {
    constructor(options: {
      release?: ReturnType<Config["getRelease"]>;
      languageVersion?: ReturnType<Config["getLanguageVersion"]>;
      globalMacros?: readonly string[];
      reg?: IRegistry;
    });
    parse(files: IFile[]): { issues: Issue[]; output: ABAPFile[] };
  }
}

declare module "@abaplint/core/build/src/abap/5_syntax/syntax.js" {
  import type { ABAPObject, IRegistry, ISpaghettiScope, Issue } from "@abaplint/core";

  export class SyntaxLogic {
    constructor(reg: IRegistry, object: ABAPObject);
    run(): { readonly issues: Issue[]; readonly spaghetti: ISpaghettiScope };
  }
}
