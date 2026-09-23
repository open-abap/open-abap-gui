REPORT zgg_ex_150.

PARAMETERS p_carr TYPE c LENGTH 20 DEFAULT 'Lufthansa'.
PARAMETERS p_date TYPE d DEFAULT '20260830'.

START-OF-SELECTION.
  WRITE 'Analytics cockpit'.
  WRITE 'Carrier:'.
  WRITE p_carr.
  WRITE 'As-of:'.
  WRITE p_date.
  WRITE 'ALV table, tree, chart summary and detail pane'.
