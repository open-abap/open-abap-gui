REPORT zgg_ex_184.

* A FORM of another program, named as form(prog).

DATA: gv_time TYPE p,
      gv_out  TYPE string.

START-OF-SELECTION.
  PERFORM p6_to_date_time_tz(rstr0400) IF FOUND USING gv_time CHANGING gv_out.
  WRITE / gv_out.
