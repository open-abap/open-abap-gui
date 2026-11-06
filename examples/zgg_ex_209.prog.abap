REPORT zgg_ex_209.

* Field symbols declared in a TOP include and bound in the FORMs of
* another include: an untyped one, one bound by READ TABLE in one FORM
* and used in another, and one bound by ASSIGN ... CASTING.

INCLUDE zgg_ex_209_top.
INCLUDE zgg_ex_209_f01.

START-OF-SELECTION.
  PERFORM fill.
  PERFORM point_to USING 2.
  PERFORM raise_points.
  PERFORM show.
  PERFORM split_code.
