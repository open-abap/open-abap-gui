REPORT zgg_ex_210.

* Names ABAP keeps apart: two structured constants with the same
* component names, and a FORM named like a global data object.

CONSTANTS: BEGIN OF gc_mode,
             add    TYPE c LENGTH 1 VALUE 'A',
             change TYPE c LENGTH 1 VALUE 'C',
           END OF gc_mode.
CONSTANTS: BEGIN OF gc_label,
             add    TYPE string VALUE `Add`,
             change TYPE string VALUE `Change`,
           END OF gc_label.

DATA total TYPE i.

START-OF-SELECTION.
  PERFORM total.
  WRITE: / gc_mode-add, gc_label-add.
  WRITE: / gc_mode-change, gc_label-change.
  WRITE: / 'Total:', total.

FORM total.
  total = 42.
ENDFORM.
