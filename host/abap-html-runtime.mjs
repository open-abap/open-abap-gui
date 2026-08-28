import "../output/init.mjs";
import {database} from "../setup.mjs";

const reportFactories = {
  ZCL_GG_INTEGRATION_HTML_REPORT: {
    className: "ZCL_GG_INTEGRATION_HTML_REPORT",
    interfaceName: "ZIF_GG_REPORT_V1",
    field: "io_report",
  },
  ZCL_GG_INTEGRATION_FAILURE: {
    className: "ZCL_GG_INTEGRATION_FAILURE",
    interfaceName: "ZIF_GG_REPORT_V1",
    field: "io_report",
    constructorInput: {iv_mode: "VALID"},
  },
  ZCL_GG_INTEGRATION_FLIGHTS: {
    className: "ZCL_GG_INTEGRATION_FLIGHTS",
    interfaceName: "ZIF_GG_REPORT_V1",
    field: "io_report",
    constructorInput: {iv_mode: "ALL"},
  },
  ZCL_GG_INTEGRATION_INTERACTIVE: {
    className: "ZCL_GG_INTEGRATION_INTERACTIVE",
    interfaceName: "ZIF_GG_REPORT_V1",
    field: "io_report",
  },
  ZCL_GG_INTEGRATION_NAVIGATION: {
    className: "ZCL_GG_INTEGRATION_NAVIGATION",
    interfaceName: "ZIF_GG_REPORT_V1",
    field: "io_report",
    constructorInput: {iv_mode: "CALL"},
  },
  ZCL_GG_INTEGRATION_SELECTION: {
    className: "ZCL_GG_INTEGRATION_SELECTION",
    interfaceName: "ZIF_GG_REPORT_V1",
    field: "io_report",
    constructorInput: {iv_mode: "DEFAULT"},
  },
  ZCL_GG_INTEGRATION_VARIANTS: {
    className: "ZCL_GG_INTEGRATION_VARIANTS",
    interfaceName: "ZIF_GG_REPORT_V1",
    field: "io_report",
    constructorInput: {iv_mode: "PLAIN"},
  },
};
const dynproFactories = {
  ZCL_GG_INTEGRATION_DYNPRO: {
    className: "ZCL_GG_INTEGRATION_DYNPRO",
    interfaceName: "ZIF_GG_DYNPRO_V1",
    field: "io_dynpro_program",
  },
};

for (let index = 1; index <= 57; index++) {
  const suffix = String(index).padStart(2, "0");
  reportFactories[`zgg_ex_${suffix}`] = {
    className: `ZCL_GG_EX_${suffix}`,
    interfaceName: "ZIF_GG_REPORT_V1",
    field: "io_report",
  };
}

dynproFactories.zgg_ex_58 = {
  className: "ZCL_GG_EX_58",
  interfaceName: "ZIF_GG_DYNPRO_V1",
  field: "io_dynpro_program",
};

let fixturePromise;
let destroyPromise;

function asString(value) {
  return value === undefined || value === null ? "" : String(value);
}

function asNumber(value) {
  return value === undefined || value === null || value === "" ? 0 : Number(value);
}

function asBoolean(value) {
  return value === "X" || value === true;
}

function valueFromField(structure, field) {
  return structure[field].get();
}

function tableRows(table) {
  return table.array().map((row) => row.get());
}

function unwrapResponse(response) {
  const result = response.get();
  return {
    valid: asBoolean(valueFromField(result, "valid")),
    error: asString(valueFromField(result, "error")),
    session_id: asString(valueFromField(result, "session_id")),
    page_id: asString(valueFromField(result, "page_id")),
    page_kind: asString(valueFromField(result, "page_kind")),
    html: asString(valueFromField(result, "html")),
    messages: tableRows(result.messages).map((message) => ({
      type: asString(message.type),
      id: asString(message.id),
      number: asString(message.number),
      text: asString(message.text),
      field: asString(message.field),
      row: asNumber(message.row),
    })),
  };
}

function typedRanges(ranges) {
  const types = abap.Classes.ZIF_GG_SELECTION_SCREEN_TYPES;
  const result = types.ty_ranges.clone();
  for (const range of ranges ?? []) {
    result.appendThis(types.ty_range.clone()
      .setField("sign", asString(range.sign))
      .setField("option", asString(range.option))
      .setField("low", asString(range.low))
      .setField("high", asString(range.high)));
  }
  return result;
}

function typedValues(values) {
  const types = abap.Classes.ZIF_GG_SELECTION_SCREEN_TYPES;
  const result = types.ty_values.clone();
  for (const value of values ?? []) {
    result.appendThis(types.ty_value.clone()
      .setField("name", asString(value.name))
      .setField("value", asString(value.value))
      .setField("ranges", typedRanges(value.ranges)));
  }
  return result;
}

function typedDynproValues(values) {
  const types = abap.Classes.ZIF_GG_DYNPRO_TYPES_V1;
  const result = types.ty_values.clone();
  for (const value of values ?? []) {
    result.appendThis(types.ty_value.clone()
      .setField("container", asString(value.container))
      .setField("name", asString(value.name))
      .setField("row", asNumber(value.row))
      .setField("value", asString(value.value)));
  }
  return result;
}

function typedRequest(request = {}) {
  const types = abap.Classes.ZIF_GG_HOST_HTML_V1;
  return types.ty_request.clone()
    .setField("session_id", asString(request.session_id))
    .setField("page_id", asString(request.page_id))
    .setField("action", asString(request.action))
    .setField("ucomm", asString(request.ucomm))
    .setField("target", asString(request.target))
    .setField("value", asString(request.value))
    .setField("row", asNumber(request.row))
    .setField("pf_key", asNumber(request.pf_key))
    .setField("token", asString(request.token))
    .setField("cursor_field", asString(request.cursor_field))
    .setField("cursor_value", asString(request.cursor_value))
    .setField("values", typedValues(request.values))
    .setField("dynpro_values", typedDynproValues(request.dynpro_values));
}

function fixtureFor(entryPoint) {
  const factory = reportFactories[entryPoint] ?? dynproFactories[entryPoint];
  if (!factory) {
    throw new RangeError(`Unknown ABAP HTML entry point: ${entryPoint}`);
  }
  const definition = abap.Classes[factory.className];
  if (!definition || !definition.IMPLEMENTED_INTERFACES.includes(factory.interfaceName)) {
    throw new TypeError(`${factory.className} does not implement ${factory.interfaceName}`);
  }
  return {factory, definition};
}

async function createFixture(entryPoint) {
  const {factory, definition} = fixtureFor(entryPoint);
  const instance = new definition();
  await instance.constructor_(factory.constructorInput);
  return {factory, instance};
}

async function ensureFixtureData() {
  fixturePromise ??= (async () => {
    await abap.Classes.ZCL_GG_DB_HELPER.create();
    await abap.Classes.ZCL_GG_DB_HELPER.reset();
  })();
  return fixturePromise;
}

function failedResponse(error, operation) {
  const message = error instanceof Error ? error.message : String(error);
  return {
    valid: false,
    error: `${operation}: ${message}`,
    session_id: "",
    page_id: "",
    page_kind: "ERROR",
    html: "",
    messages: [],
  };
}

export function createAbapHtmlRuntime({entryPoint = "report"} = {}) {
  fixtureFor(entryPoint);
  let fixture;

  return {
    async start() {
      try {
        await ensureFixtureData();
        fixture = await createFixture(entryPoint);
        const input = { [fixture.factory.field]: fixture.instance };
        return unwrapResponse(await abap.Classes.ZCL_GG_HOST_RUNTIME.start(input));
      } catch (error) {
        return failedResponse(error, "ABAP start failed");
      }
    },

    async dispatch(request) {
      try {
        return unwrapResponse(await abap.Classes.ZCL_GG_HOST_RUNTIME.dispatch({
          is_request: typedRequest(request),
        }));
      } catch (error) {
        return failedResponse(error, "ABAP dispatch failed");
      }
    },

    async close(sessionId) {
      await abap.Classes.ZCL_GG_HOST_RUNTIME.close({iv_session_id: asString(sessionId)});
    },

    async clear() {
      await abap.Classes.ZCL_GG_HOST_RUNTIME.clear();
      await ensureFixtureData();
      await abap.Classes.ZCL_GG_DB_HELPER.reset();
      fixture = undefined;
    },

    async destroy() {
      destroyPromise ??= (async () => {
        await abap.Classes.ZCL_GG_HOST_RUNTIME.clear();
      await abap.Classes.ZCL_GG_DB_HELPER.destroy();
        await database?.disconnect();
        fixturePromise = undefined;
      })();
      await destroyPromise;
    },
  };
}

export {typedRequest, unwrapResponse};
