REPORT zgg_ex_079.

PARAMETERS p_help TYPE c LENGTH 30.
PARAMETERS p_req TYPE c LENGTH 20 OBLIGATORY.

AT SELECTION-SCREEN ON HELP-REQUEST FOR p_help.
  WRITE 'Enter a business key, for example a carrier and connection such as LH0400.'.

START-OF-SELECTION.
  WRITE p_help.
