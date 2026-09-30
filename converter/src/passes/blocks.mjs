// Statement kinds that open, branch and close an ABAP control block. Every
// pass that walks a statement list by nesting depth uses these, so a LOOP AT
// SCREEN or SELECT loop is counted the same way as an IF.
export const BLOCK_CLOSERS = new Map([
  ["If", "EndIf"],
  ["Case", "EndCase"],
  ["CaseType", "EndCase"],
  ["Do", "EndDo"],
  ["While", "EndWhile"],
  ["Loop", "EndLoop"],
  ["LoopAtScreen", "EndLoop"],
  ["LoopExtract", "EndLoop"],
  ["SelectLoop", "EndSelect"],
  ["Try", "EndTry"],
  ["At", "EndAt"],
  ["AtFirst", "EndAt"],
  ["AtLast", "EndAt"],
  ["Provide", "EndProvide"],
  ["OnChange", "EndOn"],
]);

export const BLOCK_OPENERS = new Set(BLOCK_CLOSERS.keys());
export const BLOCK_ENDS = new Set(BLOCK_CLOSERS.values());
export const BLOCK_BRANCHES = new Set(["Else", "ElseIf", "When", "WhenOthers", "WhenType", "Catch", "Cleanup"]);
export const LOOP_BLOCKS = new Set(["Do", "While", "Loop", "LoopAtScreen", "LoopExtract", "SelectLoop"]);

export function closesBlock(opener, kind) {
  return BLOCK_CLOSERS.get(opener) === kind;
}
