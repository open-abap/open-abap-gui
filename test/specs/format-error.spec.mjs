import {test, expect} from "playwright/test";
import {errorResponse, formatError} from "../../web/format-error.mjs";

// The explanation of a request that failed in JavaScript. ABAP exceptions are
// explained by ZCL_GG_EXCEPTION_TEXT, see its unit tests. No host is needed.

test("format error — a native JavaScript error is explained by its name and message", () => {
  expect(formatError(new TypeError("x is not a function"))).toBe("TypeError: x is not a function");
  expect(formatError(new Error(""))).toBe("Error");
  expect(errorResponse(new RangeError("too deep"))).toEqual({valid: false, error: "RangeError: too deep"});
});

test("format error — chained causes follow the outer error", () => {
  const wrapped = new Error("Request failed", {cause: new RangeError("too deep")});
  expect(formatError(wrapped)).toBe("Error: Request failed\nCaused by: RangeError: too deep");
});

test("format error — an ABAP exception outside the handler is named by its class", () => {
  class TranspiledException extends Error {
    static INTERNAL_NAME = "CX_SY_DYN_CALL_ILLEGAL_FUNC";
  }
  expect(formatError(new TranspiledException())).toBe("CX_SY_DYN_CALL_ILLEGAL_FUNC");
});

test("format error — values without text get a fallback, never an empty string or [object Object]", () => {
  for (const value of [undefined, null, "", {}]) {
    expect(formatError(value)).toBe("Unknown error (no message available)");
  }
  expect(formatError({code: "E1"})).toBe(`{"code":"E1"}`);
  expect(formatError("CX_SY_DYN_CALL_ILLEGAL_FUNC not found")).toBe("CX_SY_DYN_CALL_ILLEGAL_FUNC not found");
});

test("format error — the stack is added only when asked for", () => {
  const error = new TypeError("x is not a function");
  expect(formatError(error)).toBe("TypeError: x is not a function");
  expect(formatError(error, {stack: true})).toBe(`TypeError: x is not a function\n\n${error.stack}`);
});
