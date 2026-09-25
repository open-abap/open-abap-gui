REPORT zexample_types.

TABLES: sflight, zmissing_table.

TYPES ty_missing TYPE zmissing_element.
TYPES ty_rows TYPE STANDARD TABLE OF zmissing_structure WITH EMPTY KEY.
TYPES ty_ref TYPE REF TO zcl_missing_class.
TYPES ty_nested TYPE zcl_missing_class=>ty_nested.
TYPES ty_range TYPE RANGE OF zmissing_element.

DATA gt_rows TYPE ty_rows.
DATA gv_value TYPE ty_missing.

START-OF-SELECTION.
  sflight-carrid = 'LH'.
  WRITE: / sflight-carrid.
