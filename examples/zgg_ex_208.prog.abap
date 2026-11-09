REPORT zgg_ex_208.

* Macros defined in the main program and called from an include. ABAP
* expands a macro wherever it is called after its DEFINE, also in the
* includes that follow.

DATA gt_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA gv_total TYPE i.

DEFINE add_line.
  APPEND &1 TO gt_lines.
END-OF-DEFINITION.

DEFINE add_amount.
  gv_total = gv_total + &1.
  add_line `Amount added`.
END-OF-DEFINITION.

INCLUDE zgg_ex_208_f01.

START-OF-SELECTION.
  PERFORM collect.
  LOOP AT gt_lines INTO DATA(lv_line).
    WRITE / lv_line.
  ENDLOOP.
  WRITE: / 'Total:', gv_total.
