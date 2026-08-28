REPORT zgg_ex_60.

TABLES: spfli, sflight.

NODES: spfli, sflight.

GET spfli.
  WRITE / 'spfli'.

GET sflight.
  WRITE / 'sflight'.

GET spfli LATE.
  WRITE / 'spfli late'.
