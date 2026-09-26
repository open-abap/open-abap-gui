REPORT zexample_incsel.
INCLUDE zexample_incsel_top.
INCLUDE zexample_incsel_cls.
INCLUDE zexample_incsel_f01.

AT SELECTION-SCREEN.
  IF p_factor > 10.
    MESSAGE 'Factor too large' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  PERFORM show_factor.
  NEW lcl_counter( )->count( ).
