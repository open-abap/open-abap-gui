REPORT zgg_ex_031.

PARAMETERS p_carr TYPE c LENGTH 3.

AT SELECTION-SCREEN ON p_carr.
  p_carr = to_upper( p_carr ).
