// The gg-gui repository deliberately exercises classic SAP Dictionary names
// that are not part of the open-abap runtime. This catalog records only
// identities that were observed in the pinned source revision. It does not
// fabricate component layouts; consumers that need fields must supply them
// separately through the normal ddicTypes option.

const identity = (name, kind = "ddic-type") => ({
  type: name.toLowerCase(),
  kind,
  source: "gg-gui explicit type inventory",
  metadataComplete: false,
});

const names = [
  "DISVARIANT",
  "ICON_D",
  "LVC_FNAME",
  "LVC_NKEY",
  "LVC_S_CELL",
  "LVC_S_COLO",
  "LVC_S_COL",
  "LVC_S_FCAT",
  "LVC_S_L004",
  "LVC_S_LACI",
  "LVC_S_LAYN",
  "LVC_S_LAYO",
  "LVC_S_PRNT",
  "LVC_S_ROID",
  "LVC_S_ROW",
  "LVC_S_SCOL",
  "LVC_S_STBL",
  "LVC_S_STYL",
  "LVC_T_CELL",
  "LVC_T_CHIT",
  "LVC_T_COL",
  "LVC_T_DROP",
  "LVC_T_F4",
  "LVC_T_FCAT",
  "LVC_T_FIDX",
  "LVC_T_FILT",
  "LVC_T_GRPL",
  "LVC_T_LACI",
  "LVC_T_LAYI",
  "LVC_T_NKEY",
  "LVC_T_ROID",
  "LVC_T_ROW",
  "LVC_T_SCOL",
  "LVC_T_SGRP",
  "LVC_T_SORT",
  "LVC_T_STYL",
  "SALV_DE_NODE_KEY",
  "SALV_S_LAYOUT_KEY",
  "SALV_T_HIERSEQ_BINDING",
  "SALV_T_ROW",
  "SLIS_FIELDCAT_ALV",
  "SLIS_T_FIELDCAT_ALV",
  "STB_BUTTON",
  "TREEV_HHDR",
  "TREEV_NKS",
  "TREEV_NTAB",
  "TV_IMAGE",
  "TV_ITMNAME",
  "TV_NODEKEY",
];

export const GG_GUI_DDIC_TYPES = Object.freeze(Object.fromEntries(names.map((name) => [name, identity(name)]).concat([
  ["ZCL_GG_GUI_DEMO_DATA=>TY_PRODUCTS", identity("zcl_gg_gui_demo_data=>ty_products", "class-type")],
])));

