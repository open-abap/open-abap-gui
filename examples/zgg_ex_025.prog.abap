REPORT zgg_ex_025.

DATA: BEGIN OF sscrfields,
        functxt_01 TYPE c LENGTH 20,
      END OF sscrfields.

SELECTION-SCREEN FUNCTION KEY 1.

INITIALIZATION.
  sscrfields-functxt_01 = 'Extras'.
