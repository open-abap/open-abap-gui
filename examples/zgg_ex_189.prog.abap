REPORT zgg_ex_189.

* SELECT-OPTIONS chained over an indented DATA declaration.

DATA gv_flat TYPE c LENGTH 4.
   DATA gv_indented TYPE c LENGTH 4.

SELECT-OPTIONS: s_flat FOR gv_flat,
                s_ind  FOR gv_indented.

START-OF-SELECTION.
  WRITE / 'hello'.
